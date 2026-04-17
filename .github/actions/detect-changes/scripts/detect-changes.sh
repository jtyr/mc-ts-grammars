#!/bin/bash
#
# Detect which grammars changed between two git refs.
#
# Usage: detect-changes.sh <base-sha>
#
# Checks both grammars/ directory changes and grammars.yaml ref changes.
# Outputs space-separated list of changed language names.

set -uo pipefail

SCRIPT_DIR=$(dirname "$0")
REPO_ROOT=$(realpath "$SCRIPT_DIR/../../../..")

if [ $# -lt 1 ]; then
    echo 'Usage: detect-changes.sh <base-sha>'
    exit 1
fi

base_sha=$1

# Find languages with changed files in grammars/
changed=$(git diff --name-only "$base_sha"..HEAD -- grammars/ | \
    sed -n 's|^grammars/\([^/]*\)/.*|\1|p' | sort -u | tr '\n' ' ')

# If grammars.yaml changed, detect which language refs were modified
if git diff --name-only "$base_sha"..HEAD | grep -q '^grammars.yaml$'; then
    # Get old refs: language|ref pairs
    old_refs=$(git show "$base_sha:grammars.yaml" 2>/dev/null | \
        yq -r '.[] | select(.enabled != false) | .language + "|" + .ref' 2>/dev/null)
    # Get current refs
    new_refs=$(yq -r '.[] | select(.enabled != false) | .language + "|" + .ref' "$REPO_ROOT/grammars.yaml")

    # Find languages where ref changed or language is new
    yaml_changed=$(diff <(echo "$old_refs" | sort) <(echo "$new_refs" | sort) | \
        grep '^>' | sed 's|^> ||; s||.*||' | sort -u)
    changed="$changed $yaml_changed"
fi

# Filter to only enabled grammars and deduplicate
enabled=$(yq -r '.[] | select(.enabled != false) | .language' "$REPO_ROOT/grammars.yaml")
languages=$(echo "$changed" | tr ' ' '\n' | sort -u | grep -xFf <(echo "$enabled") | tr '\n' ' ' | sed 's/ *$//')

if [ -n "$languages" ]; then
    echo "Changed grammars: $languages"
else
    echo 'No grammar changes detected'
fi

echo "$languages"
