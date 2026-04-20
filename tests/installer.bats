#!/usr/bin/env bats

load test_helper/common

# ============================================================
# Help
# ============================================================

@test "no arguments shows usage and exits 1" {
    run "$INSTALLER"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "--help shows usage with all commands" {
    run "$INSTALLER" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"build"* ]]
    [[ "$output" == *"install"* ]]
    [[ "$output" == *"update"* ]]
    [[ "$output" == *"list"* ]]
    [[ "$output" == *"available"* ]]
    [[ "$output" == *"uninstall"* ]]
    [[ "$output" == *"Global options:"* ]]
}

@test "unknown command fails" {
    run "$INSTALLER" foobar
    [ "$status" -eq 1 ]
    [[ "$output" == *"unknown command"* ]]
}

@test "each command supports --help" {
    for cmd in build install update list available uninstall; do
        run "$INSTALLER" $cmd --help
        [ "$status" -eq 0 ]
        [[ "$output" == *"Usage:"* ]]
    done
}

# ============================================================
# List
# ============================================================

@test "list shows nothing when no grammars installed" {
    run "$INSTALLER" list
    [ "$status" -eq 0 ]
    [[ "$output" == *"No grammars installed"* ]]
}

@test "list shows installed grammars with version and scope" {
    create_installed_grammar alpha "$HOME/.local"
    create_installed_grammar beta "$HOME/.local" "2026.04.20"

    run "$INSTALLER" list
    [ "$status" -eq 0 ]
    [[ "$output" == *"alpha"* ]]
    [[ "$output" == *"2026.04.14"* ]]
    [[ "$output" == *"beta"* ]]
    [[ "$output" == *"2026.04.20"* ]]
    [[ "$output" == *"local"* ]]
}

@test "list hides paths by default" {
    create_installed_grammar alpha "$HOME/.local"

    run "$INSTALLER" list
    [ "$status" -eq 0 ]
    [[ "$output" != *"Paths"* ]]
}

@test "list --verbose shows paths" {
    create_installed_grammar alpha "$HOME/.local"

    run "$INSTALLER" list --verbose
    [ "$status" -eq 0 ]
    [[ "$output" == *"Paths"* ]]
    [[ "$output" == *"syntax-ts"* ]]
}

@test "list -v is shorthand for --verbose" {
    create_installed_grammar alpha "$HOME/.local"

    run "$INSTALLER" list -v
    [ "$status" -eq 0 ]
    [[ "$output" == *"Paths"* ]]
}

# ============================================================
# Install
# ============================================================

@test "install requires grammar names or --all" {
    run "$INSTALLER" install
    [ "$status" -eq 1 ]
    [[ "$output" == *"specify grammar names or --all"* ]]
}

@test "install --all installs all grammars from bundle" {
    create_fake_bundle "2026.04.14" alpha beta gamma

    run "$INSTALLER" install --all --version 2026.04.14 --dir "$TEST_PREFIX"
    [ "$status" -eq 0 ]
    [[ "$output" == *"alpha"* ]]
    [[ "$output" == *"beta"* ]]
    [[ "$output" == *"gamma"* ]]
    [[ "$output" == *"Installed 3"* ]]

    # Verify files exist
    [ -f "$TEST_PREFIX/share/mc/syntax-ts/alpha/config.ini" ]
    [ -f "$TEST_PREFIX/share/mc/syntax-ts/alpha/highlights.scm" ]
    [ -f "$TEST_PREFIX/share/mc/syntax-ts/alpha/.version" ]
    [ -f "$TEST_PREFIX/lib/mc/ts-grammars/alpha.so" ]
}

@test "install specific grammars from bundle" {
    create_fake_bundle "2026.04.14" alpha beta gamma

    run "$INSTALLER" install alpha gamma --version 2026.04.14 --dir "$TEST_PREFIX"
    [ "$status" -eq 0 ]
    [[ "$output" == *"alpha"* ]]
    [[ "$output" == *"gamma"* ]]
    [[ "$output" == *"Installed 2"* ]]

    # beta should not be installed
    [ ! -d "$TEST_PREFIX/share/mc/syntax-ts/beta" ]
}

@test "install skips grammars not in bundle" {
    create_fake_bundle "2026.04.14" alpha

    run "$INSTALLER" install alpha nonexistent --version 2026.04.14 --dir "$TEST_PREFIX"
    [ "$status" -eq 0 ]
    [[ "$output" == *"alpha"* ]]
    [[ "$output" == *"SKIP"*"nonexistent"* ]]
}

@test "install variation auto-pulls its provider from bundle" {
    create_fake_bundle "2026.04.14" alpha "zeta@alpha"

    run "$INSTALLER" install zeta --version 2026.04.14 --dir "$TEST_PREFIX"
    [ "$status" -eq 0 ]
    [[ "$output" == *"DEPS"*"zeta"*"alpha"* ]]

    # Variation installed as its own dir with config + queries, no .so
    [ -f "$TEST_PREFIX/share/mc/syntax-ts/zeta/config.ini" ]
    [ -f "$TEST_PREFIX/share/mc/syntax-ts/zeta/highlights.scm" ]
    [ ! -f "$TEST_PREFIX/lib/mc/ts-grammars/zeta.so" ]

    # Parent pulled in automatically
    [ -f "$TEST_PREFIX/share/mc/syntax-ts/alpha/config.ini" ]
    [ -f "$TEST_PREFIX/lib/mc/ts-grammars/alpha.so" ]
}

@test "install variation when provider already installed" {
    create_fake_bundle "2026.04.14" alpha
    run "$INSTALLER" install alpha --version 2026.04.14 --dir "$TEST_PREFIX"
    [ "$status" -eq 0 ]

    # Second bundle contains only the variation
    create_fake_bundle "2026.04.15" "zeta@alpha"
    run "$INSTALLER" install zeta --version 2026.04.15 --dir "$TEST_PREFIX"
    [ "$status" -eq 0 ]
    [[ "$output" == *"DEPS"*"zeta"*"alpha"*"already installed"* ]]
    [ -f "$TEST_PREFIX/share/mc/syntax-ts/zeta/config.ini" ]
}

@test "install variation fails when provider is unavailable" {
    create_fake_bundle "2026.04.14" "zeta@alpha"

    run "$INSTALLER" install zeta --version 2026.04.14 --dir "$TEST_PREFIX"
    [ "$status" -ne 0 ]
    [[ "$output" == *"ERROR"*"zeta"*"alpha"* ]]
    [ ! -d "$TEST_PREFIX/share/mc/syntax-ts/zeta" ]
}

@test "install --all pulls variations from bundle" {
    create_fake_bundle "2026.04.14" alpha "zeta@alpha"

    run "$INSTALLER" install --all --version 2026.04.14 --dir "$TEST_PREFIX"
    [ "$status" -eq 0 ]
    [ -f "$TEST_PREFIX/share/mc/syntax-ts/alpha/config.ini" ]
    [ -f "$TEST_PREFIX/share/mc/syntax-ts/zeta/config.ini" ]
    [ -f "$TEST_PREFIX/lib/mc/ts-grammars/alpha.so" ]
    [ ! -f "$TEST_PREFIX/lib/mc/ts-grammars/zeta.so" ]
}

@test "install writes correct version file" {
    create_fake_bundle "2026.04.14" alpha

    run "$INSTALLER" install alpha --version 2026.04.14 --dir "$TEST_PREFIX"
    [ "$status" -eq 0 ]

    version=$(cat "$TEST_PREFIX/share/mc/syntax-ts/alpha/.version")
    [ "$version" = "2026.04.14" ]
}

@test "install uses cached bundle" {
    create_fake_bundle "2026.04.14" alpha

    run "$INSTALLER" install alpha --version 2026.04.14 --dir "$TEST_PREFIX"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Using cached bundle"* ]]
}

# ============================================================
# Update
# ============================================================

@test "update requires grammar names or --all" {
    run "$INSTALLER" update
    [ "$status" -eq 1 ]
    [[ "$output" == *"specify grammar names or --all"* ]]
}

@test "update --all updates installed grammars" {
    create_installed_grammar alpha "$TEST_PREFIX" "2026.04.14"
    create_fake_bundle "2026.04.20" alpha beta

    run "$INSTALLER" update --all --version 2026.04.20 --dir "$TEST_PREFIX"
    [ "$status" -eq 0 ]
    [[ "$output" == *"alpha"* ]]
    [[ "$output" == *"Installed 1"* ]]

    # Version should be updated
    version=$(cat "$TEST_PREFIX/share/mc/syntax-ts/alpha/.version")
    [ "$version" = "2026.04.20" ]

    # beta should not be installed (it wasn't installed before)
    [ ! -d "$TEST_PREFIX/share/mc/syntax-ts/beta" ]
}

@test "update specific grammar" {
    create_installed_grammar alpha "$TEST_PREFIX" "2026.04.14"
    create_installed_grammar beta "$TEST_PREFIX" "2026.04.14"
    create_fake_bundle "2026.04.20" alpha beta

    run "$INSTALLER" update alpha --version 2026.04.20 --dir "$TEST_PREFIX"
    [ "$status" -eq 0 ]
    [[ "$output" == *"alpha"* ]]

    # alpha updated, beta unchanged
    [ "$(cat "$TEST_PREFIX/share/mc/syntax-ts/alpha/.version")" = "2026.04.20" ]
    [ "$(cat "$TEST_PREFIX/share/mc/syntax-ts/beta/.version")" = "2026.04.14" ]
}

@test "update --all with no installed grammars does nothing" {
    run "$INSTALLER" update --all --dir "$TEST_PREFIX"
    [ "$status" -eq 0 ]
    [[ "$output" == *"No installed grammars"* ]]
}

# ============================================================
# Uninstall
# ============================================================

@test "uninstall removes grammar files" {
    create_installed_grammar alpha "$TEST_PREFIX"

    run "$INSTALLER" uninstall alpha --dir "$TEST_PREFIX"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Removed alpha"* ]]

    [ ! -d "$TEST_PREFIX/share/mc/syntax-ts/alpha" ]
    [ ! -f "$TEST_PREFIX/lib/mc/ts-grammars/alpha.so" ]
}

@test "uninstall --all removes all grammars" {
    create_installed_grammar alpha "$TEST_PREFIX"
    create_installed_grammar beta "$TEST_PREFIX"

    run "$INSTALLER" uninstall --all --dir "$TEST_PREFIX"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Removed alpha"* ]]
    [[ "$output" == *"Removed beta"* ]]

    [ ! -d "$TEST_PREFIX/share/mc/syntax-ts/alpha" ]
    [ ! -d "$TEST_PREFIX/share/mc/syntax-ts/beta" ]
}

@test "uninstall reports missing grammar" {
    run "$INSTALLER" uninstall nonexistent --dir "$TEST_PREFIX"
    [ "$status" -eq 0 ]
    [[ "$output" == *"not found"* ]]
}

@test "uninstall requires grammar names or --all" {
    run "$INSTALLER" uninstall --dir "$TEST_PREFIX"
    [ "$status" -eq 1 ]
    [[ "$output" == *"specify grammar names or --all"* ]]
}

# ============================================================
# Available
# ============================================================

@test "available lists grammars in bundle" {
    create_fake_bundle "2026.04.14" alpha beta gamma

    run "$INSTALLER" available --version 2026.04.14
    [ "$status" -eq 0 ]
    [[ "$output" == *"Release: 2026.04.14"* ]]
    [[ "$output" == *"alpha"* ]]
    [[ "$output" == *"beta"* ]]
    [[ "$output" == *"gamma"* ]]
}

@test "available shows installed status" {
    create_installed_grammar alpha "$HOME/.local" "2026.04.14"
    create_fake_bundle "2026.04.14" alpha beta

    run "$INSTALLER" available --version 2026.04.14
    [ "$status" -eq 0 ]
    # alpha should show installed version
    [[ "$output" == *"alpha"*"2026.04.14"* ]]
    # beta should show - (not installed)
    [[ "$output" == *"beta"*"-"* ]]
}

# ============================================================
# Build
# ============================================================

@test "build fails on directory without config.ini" {
    run "$INSTALLER" build /tmp
    [ "$status" -eq 1 ]
    [[ "$output" == *"not a grammar directory"* ]]
}

@test "build with --build-dir keeps output" {
    local grammar_dir="$TEST_PREFIX/testgrammar"
    mkdir -p "$grammar_dir/src/src"

    cat > "$grammar_dir/config.ini" << 'EOF'
[grammar]
extensions=.test
display-name=Test

[colors]
keyword=yellow;
EOF
    echo '(identifier) @keyword' > "$grammar_dir/highlights.scm"

    # Create a minimal parser.c that compiles
    cat > "$grammar_dir/src/src/parser.c" << 'EOF'
#include <stdlib.h>
typedef struct TSLanguage TSLanguage;
extern const TSLanguage *tree_sitter_testgrammar(void);
const TSLanguage *tree_sitter_testgrammar(void) { return NULL; }
EOF

    local build_out="$TEST_PREFIX/buildout"

    run "$INSTALLER" build --build-dir "$build_out" "$grammar_dir"
    [ "$status" -eq 0 ]
    [[ "$output" == *"BUILD"*"testgrammar"* ]]

    # Build output should exist
    [ -f "$build_out/testgrammar.so" ] || [ -f "$build_out/testgrammar.dylib" ]
}

@test "build without --build-dir cleans up" {
    local grammar_dir="$TEST_PREFIX/testgrammar"
    mkdir -p "$grammar_dir/src/src"

    cat > "$grammar_dir/config.ini" << 'EOF'
[grammar]
extensions=.test
display-name=Test

[colors]
keyword=yellow;
EOF
    echo '(identifier) @keyword' > "$grammar_dir/highlights.scm"

    cat > "$grammar_dir/src/src/parser.c" << 'EOF'
#include <stdlib.h>
typedef struct TSLanguage TSLanguage;
extern const TSLanguage *tree_sitter_testgrammar(void);
const TSLanguage *tree_sitter_testgrammar(void) { return NULL; }
EOF

    run "$INSTALLER" build "$grammar_dir"
    [ "$status" -eq 0 ]
    [[ "$output" == *"BUILD"*"testgrammar"* ]]

    # No build directory should remain in the grammar dir
    [ ! -d "$grammar_dir/build" ]
}

@test "build --install puts files in prefix" {
    local grammar_dir="$TEST_PREFIX/testgrammar"
    mkdir -p "$grammar_dir/src/src"

    cat > "$grammar_dir/config.ini" << 'EOF'
[grammar]
extensions=.test
display-name=Test

[colors]
keyword=yellow;
EOF
    echo '(identifier) @keyword' > "$grammar_dir/highlights.scm"

    cat > "$grammar_dir/src/src/parser.c" << 'EOF'
#include <stdlib.h>
typedef struct TSLanguage TSLanguage;
extern const TSLanguage *tree_sitter_testgrammar(void);
const TSLanguage *tree_sitter_testgrammar(void) { return NULL; }
EOF

    run "$INSTALLER" build --install --dir "$TEST_PREFIX" "$grammar_dir"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Installing"* ]]

    [ -f "$TEST_PREFIX/share/mc/syntax-ts/testgrammar/config.ini" ]
    [ -f "$TEST_PREFIX/share/mc/syntax-ts/testgrammar/highlights.scm" ]
    [ -f "$TEST_PREFIX/share/mc/syntax-ts/testgrammar/.version" ]

    version=$(cat "$TEST_PREFIX/share/mc/syntax-ts/testgrammar/.version")
    [ "$version" = "dev" ]
}

@test "build multiple grammar directories" {
    for lang in aaa bbb; do
        local gdir="$TEST_PREFIX/$lang"
        mkdir -p "$gdir/src/src"

        cat > "$gdir/config.ini" << EOF
[grammar]
extensions=.$lang
display-name=Test $lang

[colors]
keyword=yellow;
EOF
        echo '(identifier) @keyword' > "$gdir/highlights.scm"

        cat > "$gdir/src/src/parser.c" << EOF
#include <stdlib.h>
typedef struct TSLanguage TSLanguage;
extern const TSLanguage *tree_sitter_${lang}(void);
const TSLanguage *tree_sitter_${lang}(void) { return NULL; }
EOF
    done

    local build_out="$TEST_PREFIX/buildout"

    run "$INSTALLER" build --build-dir "$build_out" "$TEST_PREFIX/aaa" "$TEST_PREFIX/bbb"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Building 2"* ]]
    [[ "$output" == *"Built 2/2"* ]]
}
