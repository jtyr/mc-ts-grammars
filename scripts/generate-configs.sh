#!/bin/bash
#
# Generate per-grammar config.ini files from MC's monolithic configuration.
#
# Usage: generate-configs.sh <mc-syntax-ts-dir> <output-dir>
#
# Reads the monolithic MC config files (extensions, filenames, shebangs,
# display-names, symbols, wrappers, colors.ini) and the query files, then
# generates per-grammar directories with config.ini and copies .scm files.
#
# This script is a one-time migration tool.

set -euo pipefail

if [ $# -lt 2 ]; then
    echo 'Usage: generate-configs.sh <mc-syntax-ts-dir> <output-dir>'
    exit 1
fi

MC_DIR=$1
OUTPUT_DIR=$2

# Verify source directory
for f in extensions display-names colors.ini; do
    if [ ! -f "$MC_DIR/$f" ]; then
        echo "ERROR: $MC_DIR/$f not found"
        exit 1
    fi
done

# Parse a simple key-value file (grammar_name value1 value2 ...)
# Returns the values for a given grammar name.
get_values() {
    local file=$1
    local grammar=$2

    [ -f "$file" ] || return
    grep "^$grammar " "$file" | sed "s/^$grammar //" || true
}

# Parse colors.ini section for a grammar
get_colors() {
    local file=$1
    local grammar=$2

    awk -v section="[$grammar]" '
        $0 == section { found=1; next }
        found && /^\[/ { exit }
        found && /^[a-z]/ { print }
    ' "$file"
}

# Get list of grammars from query files
grammars=()
for scm in "$MC_DIR/queries"/*-highlights.scm; do
    [ -f "$scm" ] || continue
    lang=$(basename "$scm" | sed 's/-highlights\.scm$//')
    grammars+=("$lang")
done

echo "Found ${#grammars[@]} grammars with query files"

for lang in "${grammars[@]}"; do
    dir="$OUTPUT_DIR/grammars/$lang"
    mkdir -p "$dir"

    # Build config.ini
    {
        echo '[grammar]'

        # Extensions
        ext=$(get_values "$MC_DIR/extensions" "$lang")
        if [ -n "$ext" ]; then
            echo "extensions=$ext"
        fi

        # Filenames
        fnames=$(get_values "$MC_DIR/filenames" "$lang")
        if [ -n "$fnames" ]; then
            echo "filenames=$fnames"
        fi

        # Shebangs
        shebangs=$(get_values "$MC_DIR/shebangs" "$lang")
        if [ -n "$shebangs" ]; then
            echo "shebangs=$shebangs"
        fi

        # Display name
        dname=$(get_values "$MC_DIR/display-names" "$lang")
        if [ -n "$dname" ]; then
            echo "display-name=$dname"
        fi

        # Symbol override
        sym=$(get_values "$MC_DIR/symbols" "$lang")
        if [ -n "$sym" ]; then
            echo "symbol=$sym"
        fi

        # Wrapper
        wrapper=$(get_values "$MC_DIR/wrappers" "$lang")
        if [ -n "$wrapper" ]; then
            echo "wrapper=$wrapper"
        fi

        # Colors section
        colors=$(get_colors "$MC_DIR/colors.ini" "$lang")
        if [ -n "$colors" ]; then
            echo ''
            echo '[colors]'
            echo "$colors"
        fi
    } > "$dir/config.ini"

    # Copy highlights.scm
    if [ -f "$MC_DIR/queries/${lang}-highlights.scm" ]; then
        cp "$MC_DIR/queries/${lang}-highlights.scm" "$dir/highlights.scm"
    fi

    # Copy injections.scm if present
    if [ -f "$MC_DIR/queries/${lang}-injections.scm" ]; then
        cp "$MC_DIR/queries/${lang}-injections.scm" "$dir/injections.scm"
    fi

    echo "  $lang"
done

echo "Done. Generated ${#grammars[@]} grammar configs in $OUTPUT_DIR/grammars/"
