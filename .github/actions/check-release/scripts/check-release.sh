#!/bin/bash
#
# Check whether a new release should be created.
#
# Usage: check-release.sh [<tag>]
#
# Without arguments, compares HEAD against the latest git tag.
# With a tag argument (from a tag push event), always releases with that tag.

set -uo pipefail

if [ $# -gt 0 ] && [ -n "$1" ]; then
    # Tag was pushed explicitly - always release
    echo "Tag push: $1"
    echo 'true'
    echo "$1"
    exit 0
fi

latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo '')

if [ -z "$latest_tag" ]; then
    echo 'No previous release found, will create first release'
    should_release=true
else
    commits=$(git rev-list "$latest_tag"..HEAD --count)
    if [ "$commits" -gt 0 ]; then
        echo "$commits new commits since $latest_tag"
        should_release=true
    else
        echo "No new commits since $latest_tag"
        should_release=false
    fi
fi

tag=$(date +%Y.%m.%d)

echo "$should_release"
echo "$tag"
