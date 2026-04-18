#!/bin/bash
#
# Fetch tree-sitter grammar source files from upstream.
#
# Usage: fetch.sh [--all] <language> [<language> ...]
#
# Reads grammars.yaml to find the upstream URL, ref, and optional path/extraFiles.
# Downloads the entire upstream tree into grammars/<language>/src/, along with
# query files, JS dependencies, and LICENSE.
#
# MC-curated files (config.ini, highlights.scm, injections.scm) live at
# grammars/<language>/ root and are NOT touched by this script.
#
# If grammars/<language>/patches/ exists, its contents are overlaid onto
# grammars/<language>/src/ after fetching (copy with overwrite).
#
# Requires: git, yq

set -uo pipefail

SCRIPT_DIR=$(dirname "$0")
REPO_ROOT=$(realpath "$SCRIPT_DIR/../../../..")
REGISTRY="$REPO_ROOT/grammars.yaml"

if [ ! -f "$REGISTRY" ]; then
    echo "ERROR: $REGISTRY not found"
    exit 1
fi

if [ $# -eq 0 ]; then
    echo 'Usage: fetch.sh [--all] <language> [<language> ...]'
    exit 1
fi

if [ "$1" = "--all" ]; then
    shift
    # shellcheck disable=SC2046
    set -- $(yq -r '.[] | select(.enabled != false) | .language' "$REGISTRY" | sort -u)
fi

# Parse grammar entries from grammars.yaml.
# Returns one line per enabled entry for the given language.
# Pipe-separated fields with '-' for empty values to avoid delimiter collapsing.
parse_grammar() {
    local lang=$1

    yq -r ".[] | select(.language == \"$lang\" and .enabled != false) |
        (.url // \"\") + \"|\" +
        (.ref // \"\") + \"|\" +
        (.path // \"-\") + \"|\" +
        (.name // \"-\") + \"|\" +
        (.branch // \"main\") + \"|\" +
        ((.extraFiles // [] | join(\",\")) | select(length > 0) // \"-\") + \"|\" +
        (((.metadata.hasParser // false) or (.metadata.hasScanner // false)) | not | tostring) + \"|\" +
        ((.ignoreFiles // [] | join(\",\")) | select(length > 0) // \"-\") + \"|\" +
        (.queryPath // \"-\") + \"|\" +
        ((.skipScanner // false) | tostring)
    " "$REGISTRY"
}

fetch_entry() {
    local lang=$1
    local url ref path name _branch extra_files queries_only ignored_files query_path skip_scanner
    IFS='|' read -r url ref path name _branch extra_files queries_only ignored_files query_path skip_scanner

    # Replace placeholder '-' with empty string
    [ "$path" = "-" ] && path=""
    [ "$name" = "-" ] && name=""
    [ "$extra_files" = "-" ] && extra_files=""
    [ "$ignored_files" = "-" ] && ignored_files=""
    [ "$query_path" = "-" ] && query_path=""

    if [ "$queries_only" = "true" ]; then
        echo "Fetching $lang queries from $url (ref: $ref)"
    else
        echo "Fetching $lang from $url (ref: $ref)"
    fi

    local tmpdir
    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' RETURN

    # Clone with minimal depth
    if ! git clone --quiet --depth 1 --branch "$ref" "$url" "$tmpdir/repo" 2>/dev/null; then
        # If --branch fails (SHA refs), do a full clone and checkout
        git clone --quiet "$url" "$tmpdir/repo" || return 1
        git -C "$tmpdir/repo" checkout --quiet "$ref" || return 1
    fi

    local src_root="$tmpdir/repo"
    if [ -n "$path" ]; then
        src_root="$tmpdir/repo/$path"
    fi

    # Set up output directories
    local out_dir="$REPO_ROOT/grammars/$lang"
    local out_src="$out_dir/src"

    # Queries-only entries: only copy .scm files into src/queries/
    if [ "$queries_only" = "true" ]; then
        local queries_dir="$src_root/queries"
        [ -n "$query_path" ] && queries_dir="$tmpdir/repo/$query_path"
        [ -n "$path" ] && [ -z "$query_path" ] && queries_dir="$src_root"

        if [ -d "$queries_dir" ]; then
            mkdir -p "$out_src/queries"
            for scm in "$queries_dir"/*.scm; do
                [ -f "$scm" ] || continue
                local scm_name
                scm_name=$(basename "$scm")
                # Don't overwrite upstream query files
                [ -f "$out_src/queries/$scm_name" ] && continue
                cp "$scm" "$out_src/queries/"
            done
            # Replace neovim-specific predicates with standard tree-sitter equivalents
            sed -i 's/#lua-match?/#match?/g; s/#vim-match?/#match?/g' "$out_src/queries"/*.scm 2>/dev/null
        fi

        # Copy LICENSE for queries-only entries
        if [ -d "$out_src/queries" ]; then
            rm -f "$out_src/queries"/LICENSE*
            for lic in "$tmpdir/repo"/LICENSE*; do
                [ -f "$lic" ] || continue
                cp "$lic" "$out_src/queries/"
                break
            done
        fi

        echo "  -> grammars/$lang/ updated (queries)"
        return 0
    fi

    # Back up local scanner if skipScanner is set (we maintain our own)
    local saved_scanner=""
    if [ "$skip_scanner" = "true" ] && [ -f "$out_src/src/scanner.c" ]; then
        saved_scanner=$(mktemp)
        cp "$out_src/src/scanner.c" "$saved_scanner"
    fi

    # Clear and recreate the src directory (preserves config.ini, highlights.scm, etc.)
    rm -rf "$out_src"
    mkdir -p "$out_src"

    # Copy the entire upstream tree into grammars/<lang>/src/
    # (excluding .git, node_modules, test, examples, bindings, docs)
    (cd "$src_root" && find . \
        -not -path './.git/*' -not -name '.git' \
        -not -name '.gitignore' \
        -not -path '*/node_modules/*' \
        -not -path '*/test/*' \
        -not -path '*/tests/*' \
        -not -path '*/examples/*' \
        -not -path '*/bindings/*' \
        -not -path '*/docs/*' \
        -not -path '*/scripts/*' \
        -not -path '*/.github/*' \
        -type f -print0) | \
        while IFS= read -r -d '' f; do
            dir="$out_src/$(dirname "$f")"
            mkdir -p "$dir"
            cp "$src_root/$f" "$dir/"
        done

    # For parser entries with queryPath set, or monorepo entries with
    # queries/ at repo root, copy those queries into out_src/queries/
    # without overwriting any already present.
    local queries_dir=""
    if [ -n "$query_path" ]; then
        queries_dir="$tmpdir/repo/$query_path"
    elif [ -n "$path" ] && [ -d "$tmpdir/repo/queries" ]; then
        queries_dir="$tmpdir/repo/queries"
    fi
    if [ -n "$queries_dir" ] && [ -d "$queries_dir" ]; then
        mkdir -p "$out_src/queries"
        for scm in "$queries_dir"/*.scm; do
            [ -f "$scm" ] || continue
            q_name=$(basename "$scm")
            [ -f "$out_src/queries/$q_name" ] && continue
            cp "$scm" "$out_src/queries/"
        done
        sed -i 's/#lua-match?/#match?/g; s/#vim-match?/#match?/g' "$out_src/queries"/*.scm 2>/dev/null
    fi

    # Copy extra files listed in grammars.yaml
    if [ -n "$extra_files" ]; then
        IFS=',' read -ra extras <<< "$extra_files"
        for ef in "${extras[@]}"; do
            if [ -f "$src_root/src/$ef" ]; then
                mkdir -p "$out_src/src"
                cp "$src_root/src/$ef" "$out_src/src/$ef"
            else
                echo "WARNING: $lang: extra file '$ef' not found in $src_root/src/"
            fi
        done
    fi

    # Handle skipScanner: restore our maintained scanner
    if [ "$skip_scanner" = "true" ]; then
        if [ -n "$saved_scanner" ]; then
            mkdir -p "$out_src/src"
            cp "$saved_scanner" "$out_src/src/scanner.c"
            rm -f "$saved_scanner"
        else
            # Remove upstream scanner so it doesn't get compiled
            rm -f "$out_src/src/scanner.c" "$out_src/src/scanner.cc"
        fi
    fi

    # For monorepos: resolve relative includes that reach outside src/
    # (e.g. ../../common/scanner.h). Copy referenced files into src/ and
    # rewrite the include paths to avoid collisions between grammars.
    if [ -n "$path" ]; then
        grep -rh '#include "' "$out_src/src" 2>/dev/null | \
            sed -n 's|.*#include "\(\.\./[^"]*\)".*|\1|p' | \
            sort -u | while read -r inc; do
                src_file="$src_root/src/$inc"
                if [ -f "$src_file" ]; then
                    flat_name=$(basename "$inc")
                    cp "$src_file" "$out_src/src/$flat_name"
                    # Rewrite the include to use the flattened name
                    inc_escaped=${inc//\//\\/}
                    inc_escaped=${inc_escaped//./\\.}
                    sed -i "s|\"$inc_escaped\"|\"$flat_name\"|g" "$out_src/src"/*.c "$out_src/src"/*.h 2>/dev/null
                fi
            done

        # For monorepos: also copy root package.json if it has dependencies
        # (e.g. tree-sitter-typescript needs tree-sitter-javascript from npm)
        if [ -f "$tmpdir/repo/package.json" ] && \
           grep -q '"dependencies"' "$tmpdir/repo/package.json" 2>/dev/null; then
            mkdir -p "$out_src/_parent"
            cp "$tmpdir/repo/package.json" "$out_src/_parent/"
        fi

        # For monorepos: copy parent-level JS files referenced via ../
        # Rewrite the require paths to point within the grammar directory
        if [ -f "$out_src/grammar.js" ]; then
            grep -ohE "require\(['\"]\.\.\/[^'\"]*" "$src_root/grammar.js" 2>/dev/null | \
                sed "s/require(['\"]//; s/['\"]$//" | sort -u | \
                while read -r req; do
                    # Find the source file (try with and without .js)
                    local src_file=""
                    for candidate in "$src_root/$req.js" "$src_root/$req" \
                                     "$src_root/$req/index.js"; do
                        if [ -f "$candidate" ]; then
                            src_file="$candidate"
                            break
                        fi
                    done
                    [ -z "$src_file" ] && continue

                    # Flatten: ../common/foo.js -> _parent/common/foo.js
                    local flat_req
                    flat_req=${req//\.\.\//_parent/}
                    local flat_dir
                    flat_dir=$(dirname "$flat_req")
                    mkdir -p "$out_src/$flat_dir"

                    # Copy all JS and JSON files from the source directory
                    local src_req_dir
                    src_req_dir=$(dirname "$src_file")
                    for f in "$src_req_dir"/*.js "$src_req_dir"/*.json; do
                        [ -f "$f" ] || continue
                        cp "$f" "$out_src/$flat_dir/"
                    done
                done

            # Rewrite require('../...') to require('./_parent/...') in grammar.js
            sed -i "s|'\\.\\./|'./_parent/|g; s|\"\\.\\./|\"./_parent/|g" "$out_src/grammar.js" 2>/dev/null
        fi
    fi

    # Rewrite require('tree-sitter-<name>/...') to relative paths
    # pointing to our local grammars/<name>/src/ directory.
    # Skip if _parent/package.json exists (npm install will provide them).
    if [ -f "$out_src/grammar.js" ] && [ ! -f "$out_src/_parent/package.json" ]; then
        local grammars_dir="$REPO_ROOT/grammars"
        find "$out_src" -name '*.js' -print0 | while IFS= read -r -d '' js_file; do
            grep -q "require('tree-sitter-" "$js_file" 2>/dev/null || continue
            local rel
            rel=$(realpath --relative-to="$(dirname "$js_file")" "$grammars_dir")
            sed -i "s|require('tree-sitter-\([^'/]*\)/\([^']*\)')|require('$rel/\1/src/\2')|g" "$js_file"
            sed -i "s|require(\"tree-sitter-\([^\"/]*\)/\([^\"]*\)\")|require(\"$rel/\1/src/\2\")|g" "$js_file"
        done
    fi

    # Copy LICENSE file from repository root into src/
    local repo_root="$tmpdir/repo"
    rm -f "$out_src"/LICENSE*
    for lic in "$repo_root"/LICENSE*; do
        [ -f "$lic" ] || continue
        cp "$lic" "$out_src/"
        break
    done

    # Apply known source fixes
    # Perl: rename bsearch() to tsp_bsearch() to avoid glibc clash
    if [ "$lang" = "perl" ] && [ -f "$out_src/src/bsearch.h" ]; then
        sed -i 's/void \*bsearch(/void *tsp_bsearch(/' "$out_src/src/bsearch.h"
        sed -i 's/return bsearch(/return tsp_bsearch(/' "$out_src/src/tsp_unicode.h"
    fi

    # Apply patches: overlay grammars/<lang>/patches/ onto grammars/<lang>/src/
    local patches_dir="$out_dir/patches"
    if [ -d "$patches_dir" ]; then
        echo "  applying patches from grammars/$lang/patches/"
        cp -r "$patches_dir"/. "$out_src/"
    fi

    echo "  -> grammars/$lang/ updated"
}

fetch_one() {
    local lang=$1
    local entries

    entries=$(parse_grammar "$lang")
    if [ -z "$entries" ]; then
        echo "ERROR: no enabled grammar found for '$lang' in $REGISTRY"
        return 1
    fi

    local result=0
    while IFS= read -r entry; do
        if ! echo "$entry" | fetch_entry "$lang"; then
            result=1
        fi
    done <<< "$entries"

    # Remove ignored files after all entries are processed
    local all_ignored
    all_ignored=$(yq -r ".[] | select(.language == \"$lang\" and .enabled != false and .ignoreFiles) | .ignoreFiles[]" "$REGISTRY")
    if [ -n "$all_ignored" ]; then
        while IFS= read -r ig; do
            local target="$REPO_ROOT/grammars/$lang/$ig"
            if [ -f "$target" ]; then
                rm -f "$target"
                echo "  removed ignored file: $ig"
                local parent
                parent=$(dirname "$target")
                rmdir "$parent" 2>/dev/null || true
            fi
        done <<< "$all_ignored"
    fi

    return $result
}

failed=0
for lang in "$@"; do
    if ! fetch_one "$lang"; then
        echo "FAILED: $lang"
        failed=$((failed + 1))
    fi
done

if [ $failed -gt 0 ]; then
    echo "$failed grammar(s) failed to fetch"
    exit 1
fi

echo 'Done.'
