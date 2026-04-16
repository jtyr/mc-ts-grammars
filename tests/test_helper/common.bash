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
}

teardown() {
    rm -rf "$TEST_PREFIX"
}

# Create a minimal fake grammar directory in the repo for testing
create_fake_grammar() {
    local lang=$1
    local grammar_dir="$REPO_ROOT/grammars/$lang"

    mkdir -p "$grammar_dir"

    cat > "$grammar_dir/config.ini" << EOF
[grammar]
extensions=.${lang}
display-name=Test $lang

[colors]
keyword=yellow;
EOF

    cat > "$grammar_dir/highlights.scm" << EOF
(identifier) @keyword
EOF
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
