#!/bin/bash
#
# Check upstream repositories for grammar updates.
#
# Usage: check-updates.sh
#
# For each enabled grammar in grammars.yaml, checks whether the upstream
# repository has a newer commit (or tag). When updates are found, updates
# the ref in grammars.yaml and prints the list of updated languages.
#
# For tag-based grammars, clones the repo and uses
# git for-each-ref --sort=creatordate to find the historically latest tag.

set -uo pipefail

SCRIPT_DIR=$(dirname "$0")
REPO_ROOT=$(realpath "$SCRIPT_DIR/../../../..")
REGISTRY="$REPO_ROOT/grammars.yaml"

# Get the most recently created tag by cloning the repo
get_latest_tag() {
    local url=$1
    local tmpdir
    tmpdir=$(mktemp -d)

    if ! git clone --quiet --bare "$url" "$tmpdir/repo" 2>/dev/null; then
        rm -rf "$tmpdir"
        return 1
    fi

    git -C "$tmpdir/repo" for-each-ref \
        --sort=-creatordate --format='%(refname:short)' refs/tags/ --count=1
    rm -rf "$tmpdir"
}

updated=""
failed=""

while IFS='|' read -r lang url ref branch use_tags; do
    if [ "$use_tags" = "true" ]; then
        latest=$(get_latest_tag "$url")
        if [ -z "$latest" ]; then
            echo "WARNING: $lang: could not fetch tags from $url"
            failed="$failed $lang"
            continue
        fi
        if [ "$latest" = "$ref" ]; then
            continue
        fi
        new_ref="$latest"
    else
        # For commit-based grammars, check HEAD of branch
        latest=$(git ls-remote "$url" "refs/heads/$branch" 2>/dev/null | cut -f1)
        if [ -z "$latest" ]; then
            echo "WARNING: $lang: could not reach $url"
            failed="$failed $lang"
            continue
        fi
        if [ "$latest" = "$ref" ]; then
            continue
        fi
        new_ref="$latest"
    fi

    echo "UPDATE: $lang ($url) $ref -> $new_ref"
    updated="$updated $lang"

    # Update ref in grammars.yaml using sed to preserve formatting
    sed -i "/url: ${url//\//\\/}/,/ref:/{s|ref: $ref|ref: $new_ref|}" "$REGISTRY"
done < <(yq -r '.[] | select(.enabled != false) |
    select(.url | test("nvim-treesitter") | not) |
    .language + "|" + .url + "|" + .ref + "|" + (.branch // "main") + "|" +
    ((.metadata.gitTags // false) | tostring)
' "$REGISTRY" | sort -t'|' -k2,3 -u)

updated=$(echo "$updated" | xargs)

if [ -n "$updated" ]; then
    echo "Updated: $updated"
else
    echo 'All grammars are up to date'
fi

if [ -n "$failed" ]; then
    echo "Unreachable:$failed"
fi

echo "$updated"
