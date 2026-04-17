#!/bin/bash
# Common test helper functions

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC2034 # used by bats test files
INSTALLER="$REPO_ROOT/scripts/mc-ts-grammar"
TEST_PREFIX="$(mktemp -d)"

setup() {
    export HOME="$TEST_PREFIX/home"
    mkdir -p "$HOME"
    export TEST_SHARE="$TEST_PREFIX/share/mc/syntax-ts"
    export TEST_LIB="$TEST_PREFIX/lib/mc/ts-grammars"
    # Point cache to test dir so tests don't pollute real cache
    export XDG_CACHE_HOME="$TEST_PREFIX/cache"
    mkdir -p "$XDG_CACHE_HOME"
}

teardown() {
    rm -rf "$TEST_PREFIX"
}

# Create a fake installed grammar
create_installed_grammar() {
    local lang=$1
    local prefix=${2:-$TEST_PREFIX}
    local version=${3:-2026.04.14}

    local share_dir="$prefix/share/mc/syntax-ts/$lang"
    local lib_dir="$prefix/lib/mc/ts-grammars"

    mkdir -p "$share_dir" "$lib_dir"

    cat > "$share_dir/config.ini" << EOF
[grammar]
extensions=.${lang}
display-name=Test $lang

[colors]
keyword=yellow;
EOF

    echo '(identifier) @keyword' > "$share_dir/highlights.scm"
    echo "$version" > "$share_dir/.version"
    touch "$lib_dir/$lang.so"
}

# Create a fake release bundle tarball in the test cache.
# Usage: create_fake_bundle <version> <lang1> [<lang2> ...]
create_fake_bundle() {
    local version=$1
    shift
    local langs=("$@")

    local platform
    case "$(uname -s)" in
        Darwin)
            case "$(uname -m)" in
                arm64) platform='aarch64-macos' ;;
                *)     platform='x86_64-macos' ;;
            esac
            ;;
        *) platform='x86_64-linux' ;;
    esac

    local tarball_name="mc-ts-grammars-$version-$platform"
    local staging="$TEST_PREFIX/staging/$tarball_name"
    mkdir -p "$staging"

    for lang in "${langs[@]}"; do
        mkdir -p "$staging/$lang"

        cat > "$staging/$lang/config.ini" << EOF
[grammar]
extensions=.${lang}
display-name=Test $lang

[colors]
keyword=yellow;
EOF

        echo '(identifier) @keyword' > "$staging/$lang/highlights.scm"
        touch "$staging/$lang/$lang.so"
    done

    echo "$version" > "$staging/VERSION"

    local cache_dir="$XDG_CACHE_HOME/mc-ts-grammar"
    mkdir -p "$cache_dir"
    (cd "$TEST_PREFIX/staging" && tar czf "$cache_dir/$tarball_name.tar.gz" "$tarball_name")
    rm -rf "$TEST_PREFIX/staging"
}
