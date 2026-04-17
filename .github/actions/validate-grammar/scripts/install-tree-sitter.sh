#!/bin/bash
#
# Install the tree-sitter library from source.
#
# Skips installation if a compatible version is already available.

set -euo pipefail

SCRIPT_DIR=$(dirname "$0")
REPO_ROOT=$(realpath "$SCRIPT_DIR/../../../..")

# shellcheck disable=SC1091
source "$REPO_ROOT/.github/actions/common.sh"

if pkg-config --exact-version="$TREE_SITTER_VERSION" tree-sitter 2>/dev/null; then
    echo "tree-sitter $TREE_SITTER_VERSION already installed"
    exit 0
fi

echo "Building tree-sitter v$TREE_SITTER_VERSION from source..."
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

git clone --quiet --depth 1 --branch "v$TREE_SITTER_VERSION" \
    https://github.com/tree-sitter/tree-sitter "$tmpdir/ts"
make -C "$tmpdir/ts" -j"$(nproc)" PREFIX=/usr
sudo make -C "$tmpdir/ts" PREFIX=/usr install
sudo ldconfig

echo "tree-sitter $(pkg-config --modversion tree-sitter) installed"
