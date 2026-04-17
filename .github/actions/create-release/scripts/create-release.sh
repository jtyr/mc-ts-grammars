#!/bin/bash
#
# Generate release notes and create a GitHub release.
#
# Usage: create-release.sh [--dry-run] <tag> <release-dir>
#
# Generates release notes from git history and creates a GitHub release
# with the tarballs in <release-dir>. Requires GH_TOKEN to be set.
#
# With --dry-run, only prints the release notes without creating a release.

set -uo pipefail

DRY_RUN=false
if [ "${1:-}" = "--dry-run" ]; then
    DRY_RUN=true
    shift
fi

if [ $# -lt 2 ]; then
    echo 'Usage: create-release.sh [--dry-run] <tag> <release-dir>'
    exit 1
fi

tag=$1
release_dir=$2
REPO_URL="https://github.com/${GITHUB_REPOSITORY:-jtyr/mc-ts-grammars}"

latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo '')

{
    echo '## Grammars'
    echo ''

    if [ -n "$latest_tag" ]; then
        changed=$(git diff --name-only "$latest_tag"..HEAD -- grammars/ | \
            sed -n 's|^grammars/\([^/]*\)/.*|\1|p' | sort -u)
        if [ -n "$changed" ]; then
            echo 'Updated:'
            echo "$changed" | while read -r lang; do
                echo "- $lang"
            done
        fi
    else
        echo 'Initial release with all grammars.'
    fi

    echo ''
    echo '## Installation'
    echo ''
    echo '```bash'
    echo "curl -LO $REPO_URL/releases/download/$tag/mc-ts-grammar"
    echo 'chmod +x mc-ts-grammar'
    echo "./mc-ts-grammar install --all --version $tag"
    echo '```'
    echo ''
    echo '## Platforms'
    echo ''
    for f in "$release_dir"/*.tar.gz; do
        [ -f "$f" ] || continue
        echo "- \`$(basename "$f")\`"
    done
} > "$release_dir/release_notes.md"

echo 'Release notes:'
cat "$release_dir/release_notes.md"

# Copy installer to release dir
SCRIPT_DIR=$(dirname "$0")
REPO_ROOT=$(realpath "$SCRIPT_DIR/../../../..")
cp "$REPO_ROOT/scripts/mc-ts-grammar" "$release_dir/mc-ts-grammar"

if $DRY_RUN; then
    echo ''
    echo '(dry run - no release created)'
    exit 0
fi

echo ''

gh release create "$tag" \
    --title "$tag" \
    --notes-file "$release_dir/release_notes.md" \
    "$release_dir"/*.tar.gz \
    "$release_dir/mc-ts-grammars.sha256" \
    "$release_dir/mc-ts-grammar"

echo "Release $tag created."
