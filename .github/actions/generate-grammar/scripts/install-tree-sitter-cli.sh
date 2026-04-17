#!/bin/bash
#
# Install the tree-sitter CLI via npm.

set -euo pipefail

SCRIPT_DIR=$(dirname "$0")
REPO_ROOT=$(realpath "$SCRIPT_DIR/../../../..")

# shellcheck disable=SC1091
source "$REPO_ROOT/.github/actions/common.sh"

echo "Installing tree-sitter-cli@$TREE_SITTER_VERSION..."
npm install -g "tree-sitter-cli@$TREE_SITTER_VERSION"
