#!/bin/bash
#
# Generate parser.c from grammar.js for tree-sitter grammars.
#
# Usage: generate.sh [--all] [--cache-dir=DIR] <language> [<language> ...]
#
# For each grammar:
# 1. Check cache (if --cache-dir given) for a previously generated parser.c.
# 2. Try local generation (npm install + tree-sitter generate in grammars/<lang>/src/).
# 3. If that fails, clone the upstream repo and generate there, then copy results.
# 4. Store result in cache (if --cache-dir given).
#
# Requires: node, npm, tree-sitter CLI, git, yq

set -uo pipefail

SCRIPT_DIR=$(dirname "$0")
REPO_ROOT=$(realpath "$SCRIPT_DIR/../../../..")
REGISTRY="$REPO_ROOT/grammars.yaml"
CACHE_DIR=""

if [ $# -eq 0 ]; then
    echo 'Usage: generate.sh [--all] [--cache-dir=DIR] <language> [<language> ...]'
    exit 1
fi

# Parse options
while [ $# -gt 0 ]; do
    case "$1" in
        --cache-dir=*)
            CACHE_DIR="${1#--cache-dir=}"
            shift
            ;;
        --all)
            shift
            # shellcheck disable=SC2046 # word splitting is intentional
            set -- $(
                for d in "$REPO_ROOT"/grammars/*/src/grammar.js; do
                    [ -f "$d" ] || continue
                    basename "$(dirname "$(dirname "$d")")"
                done | sort
            )
            ;;
        *)
            break
            ;;
    esac
done

if ! command -v tree-sitter >/dev/null 2>&1; then
    echo 'ERROR: tree-sitter CLI not found'
    exit 1
fi

echo "tree-sitter version: $(tree-sitter --version)"

# Compute a cache key for a grammar based on its source files.
grammar_cache_key() {
    local lang=$1
    local src_dir="$REPO_ROOT/grammars/$lang/src"
    local files=""

    for f in "$src_dir/grammar.js" \
             "$src_dir/package.json" \
             "$src_dir/src/scanner.c" \
             "$src_dir/src/scanner.cc"; do
        [ -f "$f" ] && files="$files $f"
    done

    # shellcheck disable=SC2086 # word splitting is intentional
    sha256sum $files 2>/dev/null | sha256sum | cut -d' ' -f1
}

# Check if a cached parser.c exists for this grammar.
check_cache() {
    local lang=$1
    local src_dir="$REPO_ROOT/grammars/$lang/src"

    [ -z "$CACHE_DIR" ] && return 1

    local key
    key=$(grammar_cache_key "$lang")
    local cache_entry="$CACHE_DIR/$lang/$key"

    if [ -f "$cache_entry/parser.c" ]; then
        echo "  CACHED   $lang"
        mkdir -p "$src_dir/src"
        cp "$cache_entry/parser.c" "$src_dir/src/"
        if [ -d "$cache_entry/tree_sitter" ]; then
            cp -r "$cache_entry/tree_sitter" "$src_dir/src/"
        fi
        return 0
    fi

    return 1
}

# Store generated parser.c in cache.
store_cache() {
    local lang=$1
    local src_dir="$REPO_ROOT/grammars/$lang/src"

    [ -z "$CACHE_DIR" ] && return
    [ -f "$src_dir/src/parser.c" ] || return

    local key
    key=$(grammar_cache_key "$lang")
    local cache_entry="$CACHE_DIR/$lang/$key"

    mkdir -p "$cache_entry"
    cp "$src_dir/src/parser.c" "$cache_entry/"
    if [ -d "$src_dir/src/tree_sitter" ]; then
        cp -r "$src_dir/src/tree_sitter" "$cache_entry/"
    fi
}

# Try to generate parser.c locally in grammars/<lang>/src/.
try_local_generate() {
    local lang=$1
    local src_dir="$REPO_ROOT/grammars/$lang/src"

    # Install npm dependencies if package.json has them
    if [ -f "$src_dir/package.json" ] && \
       grep -q '"dependencies"' "$src_dir/package.json" 2>/dev/null; then
        (cd "$src_dir" && npm install --ignore-scripts --loglevel=error 2>&1) || true
    fi

    # For monorepos: install parent-level npm dependencies
    if [ -f "$src_dir/_parent/package.json" ] && \
       grep -q '"dependencies"' "$src_dir/_parent/package.json" 2>/dev/null; then
        (cd "$src_dir/_parent" && npm install --ignore-scripts --loglevel=error 2>&1) || true
    fi

    (cd "$src_dir" && tree-sitter generate 2>&1)
}

# Clone upstream repo and generate there, then copy results back.
upstream_generate() {
    local lang=$1
    local src_dir="$REPO_ROOT/grammars/$lang/src"
    local tmpdir
    tmpdir=$(mktemp -d)

    local url ref path
    url=$(yq -r ".[] | select(.language == \"$lang\" and .enabled != false) | .url" "$REGISTRY" | head -1)
    ref=$(yq -r ".[] | select(.language == \"$lang\" and .enabled != false) | .ref" "$REGISTRY" | head -1)
    path=$(yq -r ".[] | select(.language == \"$lang\" and .enabled != false) | .path // \"\"" "$REGISTRY" | head -1)

    if [ -z "$url" ] || [ -z "$ref" ]; then
        echo "    no registry entry for $lang"
        rm -rf "$tmpdir"
        return 1
    fi

    echo "    cloning upstream..."
    if ! git clone --quiet --depth 1 --branch "$ref" "$url" "$tmpdir/repo" 2>/dev/null; then
        git clone --quiet "$url" "$tmpdir/repo" 2>/dev/null || { rm -rf "$tmpdir"; return 1; }
        git -C "$tmpdir/repo" checkout --quiet "$ref" 2>/dev/null || { rm -rf "$tmpdir"; return 1; }
    fi

    local src_root="$tmpdir/repo"
    [ -n "$path" ] && src_root="$tmpdir/repo/$path"

    # Install npm deps - check both grammar dir and repo root for monorepos
    local npm_dir="$src_root"
    if [ -n "$path" ] && [ -f "$tmpdir/repo/package.json" ] && \
       grep -q '"dependencies"' "$tmpdir/repo/package.json" 2>/dev/null; then
        npm_dir="$tmpdir/repo"
    fi
    if [ -f "$npm_dir/package.json" ] && \
       grep -q '"dependencies"' "$npm_dir/package.json" 2>/dev/null; then
        (cd "$npm_dir" && npm install --ignore-scripts --loglevel=error 2>&1) || true
    fi

    echo "    generating..."
    if ! (cd "$src_root" && tree-sitter generate 2>&1); then
        rm -rf "$tmpdir"
        return 1
    fi

    # Copy generated files back
    mkdir -p "$src_dir/src"
    cp "$src_root/src/parser.c" "$src_dir/src/"
    if [ -d "$src_root/src/tree_sitter" ]; then
        cp -r "$src_root/src/tree_sitter" "$src_dir/src/"
    fi

    rm -rf "$tmpdir"
}

generate_one() {
    local lang=$1
    local src_dir="$REPO_ROOT/grammars/$lang/src"

    if [ ! -f "$src_dir/grammar.js" ]; then
        echo "  SKIP     $lang (no grammar.js)"
        return 0
    fi

    # Check cache first
    if check_cache "$lang"; then
        return 0
    fi

    echo "  GENERATE $lang"

    # Try local first, fall back to upstream clone
    local local_output
    local_output=$(try_local_generate "$lang" 2>&1)
    if [ -f "$src_dir/src/parser.c" ]; then
        store_cache "$lang"
        return 0
    fi

    echo "    local generation failed:"
    echo "$local_output" | sed 's/^/      /' | head -20
    echo "    trying upstream clone..."
    if upstream_generate "$lang"; then
        store_cache "$lang"
        return 0
    fi

    echo "  ERROR    $lang: generation failed"
    return 1
}

failed=0
total=$#
generated=0
skipped=0

for lang in "$@"; do
    if generate_one "$lang"; then
        if [ -f "$REPO_ROOT/grammars/$lang/src/src/parser.c" ]; then
            generated=$((generated + 1))
        else
            skipped=$((skipped + 1))
        fi
    else
        failed=$((failed + 1))
    fi
done

echo "Generated $generated/$total ($skipped skipped, $failed failed)"

if [ $failed -gt 0 ]; then
    exit 1
fi
