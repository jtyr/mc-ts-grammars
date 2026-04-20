#!/bin/bash
#
# Package built grammar libraries into a release tarball.
#
# Usage: package.sh --platform=PLATFORM --build-dir=DIR --output=DIR --tag=TAG
#
# Creates one tarball per platform:
#   mc-ts-grammars-<tag>-<platform>.tar.gz
#
# The tarball contains per-language directories with library and query files:
#   mc-ts-grammars-<tag>-<platform>/
#     python/
#       python.so
#       config.ini
#       highlights.scm
#       injections.scm  (if available)
#       LICENSE          (if available)
#     terraform/        (variation of hcl: shares hcl.so via config.ini symbol=hcl)
#       config.ini
#       highlights.scm
#     VERSION
#
# Platforms: x86_64-linux, aarch64-linux, aarch64-macos, x86_64-macos, x86_64-windows

set -uo pipefail

SCRIPT_DIR=$(dirname "$0")
REPO_ROOT=$(realpath "$SCRIPT_DIR/../../../..")
REGISTRY="$REPO_ROOT/grammars.yaml"

PLATFORM=""
BUILD_DIR=""
OUTPUT_DIR=""
TAG=""

while [ $# -gt 0 ]; do
    case "$1" in
        --platform=*) PLATFORM="${1#--platform=}" ;;
        --build-dir=*) BUILD_DIR="${1#--build-dir=}" ;;
        --output=*) OUTPUT_DIR="${1#--output=}" ;;
        --tag=*) TAG="${1#--tag=}" ;;
        --*) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

if [ -z "$PLATFORM" ] || [ -z "$BUILD_DIR" ] || [ -z "$OUTPUT_DIR" ] || [ -z "$TAG" ]; then
    echo 'Usage: package.sh --platform=PLATFORM --build-dir=DIR --output=DIR --tag=TAG'
    exit 1
fi

# Detect expected extension from platform name
case "$PLATFORM" in
    *-macos) SO_EXT=dylib ;;
    *-windows) SO_EXT=dll ;;
    *) SO_EXT=so ;;
esac

# Get grammars that have release: true and are not disabled (portable, no yq dependency).
# Matches "- language: <name>" blocks where "release: true" appears before the next
# "- language:" block, and "enabled: false" does NOT appear in that same block.
get_release_grammars() {
    awk '
        /^- language:/ {
            if (lang && release && !disabled) print lang
            lang = $3
            release = 0
            disabled = 0
        }
        /^  release: true/ { release = 1 }
        /^  enabled: false/ { disabled = 1 }
        END { if (lang && release && !disabled) print lang }
    ' "$REGISTRY"
}

# Get variation names listed under a given parent grammar's variations field.
# Only variations of entries that are themselves released are returned.
get_variations() {
    local parent=$1
    awk -v target="$parent" '
        /^- language:/ {
            in_target = ($3 == target)
            in_variations = 0
            release = 0
        }
        in_target && /^  release: true/ { release = 1 }
        in_target && /^  variations:/ { in_variations = 1; next }
        in_variations && /^    - / {
            if (release) print $2
            next
        }
        in_variations && /^  [^ ]/ { in_variations = 0 }
        in_variations && /^- language:/ { in_variations = 0 }
    ' "$REGISTRY"
}

# Copy config.ini + query files + LICENSE from a grammar directory into staging.
# Used for both primary grammars and variations.
copy_grammar_files() {
    local src_dir=$1
    local dest_dir=$2

    [ -f "$src_dir/config.ini" ] && cp "$src_dir/config.ini" "$dest_dir/"
    [ -f "$src_dir/highlights.scm" ] && cp "$src_dir/highlights.scm" "$dest_dir/"
    [ -f "$src_dir/injections.scm" ] && cp "$src_dir/injections.scm" "$dest_dir/"
    [ -f "$src_dir/src/LICENSE" ] && cp "$src_dir/src/LICENSE" "$dest_dir/"
}

tarball_name="mc-ts-grammars-$TAG-$PLATFORM"
staging="$OUTPUT_DIR/$tarball_name"

rm -rf "$staging"
mkdir -p "$staging"

included=0
skipped=0
skipped_list=""

for lang in $(get_release_grammars); do
    lib_file="$BUILD_DIR/$lang.$SO_EXT"
    grammar_dir="$REPO_ROOT/grammars/$lang"

    if [ ! -f "$lib_file" ]; then
        skipped=$((skipped + 1))
        skipped_list="$skipped_list $lang"
        continue
    fi

    mkdir -p "$staging/$lang"
    cp "$lib_file" "$staging/$lang/$lang.$SO_EXT"
    copy_grammar_files "$grammar_dir" "$staging/$lang"
    included=$((included + 1))

    # Variations share the parent's .so but have their own config/queries.
    # They are flattened to the top level of the tarball so MC's discovery
    # scan finds them without any variations/ awareness on the MC side.
    for variation in $(get_variations "$lang"); do
        variation_dir="$grammar_dir/variations/$variation"
        if [ ! -d "$variation_dir" ]; then
            echo "WARNING: $lang: variation '$variation' listed in grammars.yaml but grammars/$lang/variations/$variation/ does not exist"
            continue
        fi
        mkdir -p "$staging/$variation"
        copy_grammar_files "$variation_dir" "$staging/$variation"
        included=$((included + 1))
    done
done

if [ $included -eq 0 ]; then
    echo 'WARNING: no grammars to package'
    rm -rf "$staging"
    exit 1
fi

# Write VERSION file
echo "$TAG" > "$staging/VERSION"

# Create tarball
mkdir -p "$OUTPUT_DIR"
(cd "$OUTPUT_DIR" && tar czf "$tarball_name.tar.gz" "$tarball_name")
rm -rf "$staging"

# Append checksum to the shared checksums file
(cd "$OUTPUT_DIR" && sha256sum "$tarball_name.tar.gz") >> "$OUTPUT_DIR/mc-ts-grammars.sha256"

echo "Package: $OUTPUT_DIR/$tarball_name.tar.gz"
echo "  $included grammars included"

if [ $skipped -gt 0 ]; then
    echo "  $skipped grammars skipped (not built):$skipped_list"
fi
