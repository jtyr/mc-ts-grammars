#!/usr/bin/env bats

load test_helper/common

@test "mc-ts-grammar shows usage with no arguments" {
    run "$INSTALLER"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "mc-ts-grammar help shows usage" {
    run "$INSTALLER" help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
    [[ "$output" == *"build"* ]]
    [[ "$output" == *"install"* ]]
    [[ "$output" == *"update"* ]]
    [[ "$output" == *"list"* ]]
    [[ "$output" == *"uninstall"* ]]
}

@test "mc-ts-grammar unknown command fails" {
    run "$INSTALLER" foobar
    [ "$status" -eq 1 ]
    [[ "$output" == *"unknown command"* ]]
}

@test "list shows no grammars when none installed" {
    run "$INSTALLER" list
    [ "$status" -eq 0 ]
    [[ "$output" == *"No grammars installed"* ]]
}

@test "list shows installed grammar" {
    # Install to $HOME/.local (the default prefix) since list uses HOME
    create_installed_grammar testlang "$HOME/.local"

    run "$INSTALLER" list
    [ "$status" -eq 0 ]
    [[ "$output" == *"testlang"* ]]
}

@test "uninstall removes installed grammar" {
    create_installed_grammar removeme "$TEST_PREFIX"

    run "$INSTALLER" uninstall removeme --dir "$TEST_PREFIX"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Removed removeme"* ]]

    # Verify files are gone
    [ ! -d "$TEST_PREFIX/share/mc/syntax-ts/removeme" ]
    [ ! -f "$TEST_PREFIX/lib/mc/ts-grammars/removeme.so" ]
}

@test "uninstall --all removes all grammars" {
    create_installed_grammar lang1 "$TEST_PREFIX"
    create_installed_grammar lang2 "$TEST_PREFIX"

    run "$INSTALLER" uninstall --all --dir "$TEST_PREFIX"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Removed lang1"* ]]
    [[ "$output" == *"Removed lang2"* ]]
}

@test "uninstall reports missing grammar" {
    run "$INSTALLER" uninstall nonexistent --dir "$TEST_PREFIX"
    [ "$status" -eq 0 ]
    [[ "$output" == *"not found"* ]]
}

@test "install requires grammar names or --all" {
    run "$INSTALLER" install
    [ "$status" -eq 1 ]
    [[ "$output" == *"specify grammar names or --all"* ]]
}

@test "update requires grammar names or --all" {
    run "$INSTALLER" update
    [ "$status" -eq 1 ]
    [[ "$output" == *"specify grammar names or --all"* ]]
}

@test "build fails outside of repo" {
    cd /tmp
    run "$INSTALLER" build
    [ "$status" -eq 1 ]
    [[ "$output" == *"must be run from within"* ]]
}
