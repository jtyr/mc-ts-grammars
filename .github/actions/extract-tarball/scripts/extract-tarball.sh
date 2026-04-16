#!/bin/bash
#
# Extract grammar shared libraries from a release tarball.
#
# Usage: extract-tarball.sh <tarball> <output-dir>
#
# Extracts all .so/.dylib/.dll files from a release tarball into a flat
# directory for use with the validate-grammar action.

set -uo pipefail

if [ $# -lt 2 ]; then
    echo 'Usage: extract-tarball.sh <tarball> <output-dir>'
    exit 1
fi

tarball=$1
output_dir=$2
tmpdir=$(mktemp -d)

tar xzf "$tarball" -C "$tmpdir"
mkdir -p "$output_dir"

find "$tmpdir" -type f \( -name '*.so' -o -name '*.dylib' -o -name '*.dll' \) \
    -exec cp {} "$output_dir/" \;

count=$(find "$output_dir" -type f | wc -l)
echo "Extracted $count shared libraries to $output_dir"

rm -rf "$tmpdir"
