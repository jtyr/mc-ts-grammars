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

    # Copy config.ini
    if [ -f "$grammar_dir/config.ini" ]; then
        cp "$grammar_dir/config.ini" "$staging/$lang/"
    fi

    # Copy highlights.scm
    if [ -f "$grammar_dir/highlights.scm" ]; then
        cp "$grammar_dir/highlights.scm" "$staging/$lang/"
    fi

    # Copy injections.scm if present
    if [ -f "$grammar_dir/injections.scm" ]; then
        cp "$grammar_dir/injections.scm" "$staging/$lang/"
    fi

    # Copy LICENSE if present
    if [ -f "$grammar_dir/src/LICENSE" ]; then
        cp "$grammar_dir/src/LICENSE" "$staging/$lang/"
    fi

    included=$((included + 1))
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
