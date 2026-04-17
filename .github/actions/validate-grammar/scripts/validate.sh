#!/bin/bash
#
# Validate tree-sitter grammar query files (.scm) against their grammar.
#
# Usage: validate.sh [--build-dir=DIR] <language> [<language> ...]
#        validate.sh [--build-dir=DIR] --all
#
# Compiles each .scm query file with ts_query_new() to catch invalid node
# names, field names, and syntax errors. Requires a built grammar .so file.
#
# Requires: C compiler, tree-sitter headers, built grammar .so

set -uo pipefail

SCRIPT_DIR=$(dirname "$0")
REPO_ROOT=$(realpath "$SCRIPT_DIR/../../../..")
REGISTRY="$REPO_ROOT/grammars.yaml"

BUILD_DIR="$REPO_ROOT/build"
VALIDATE_ALL=false
LANGUAGES=()

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --all) VALIDATE_ALL=true ;;
        --build-dir=*) BUILD_DIR="${1#--build-dir=}" ;;
        --*) echo "Unknown option: $1"; exit 1 ;;
        *) LANGUAGES+=("$1") ;;
    esac
    shift
done

# Get all grammars with release: true
get_validatable_grammars() {
    yq -r '.[] | select(.release == true) | .language' "$REGISTRY"
}

if $VALIDATE_ALL; then
    while IFS= read -r lang; do
        LANGUAGES+=("$lang")
    done < <(get_validatable_grammars)
fi

if [ ${#LANGUAGES[@]} -eq 0 ]; then
    echo 'Usage: validate.sh [--build-dir=DIR] [--all] <language> [...]'
    exit 1
fi

# Detect shared library extension
case "$(uname -s)" in
    Darwin) SO_EXT=dylib ;;
    MINGW*|MSYS*|CYGWIN*) SO_EXT=dll ;;
    *) SO_EXT=so ;;
esac

# Get the symbol name for a grammar
get_symbol_name() {
    local lang=$1
    local config="$REPO_ROOT/grammars/$lang/config.ini"
    local symbol

    # Check config.ini for a symbol= line in the [grammar] section
    if [ -f "$config" ]; then
        symbol=$(sed -n '/^\[grammar\]/,/^\[/{s/^symbol=//p}' "$config" | head -1)
    fi

    if [ -n "${symbol:-}" ]; then
        echo "tree_sitter_$symbol"
    else
        echo "tree_sitter_$lang"
    fi
}

# Build the validator binary once
VALIDATOR_DIR=$(mktemp -d)
trap 'rm -rf "$VALIDATOR_DIR"' EXIT

cat > "$VALIDATOR_DIR/validate.c" << 'VALIDATE_EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>
#include <tree_sitter/api.h>

int main(int argc, char **argv) {
    if (argc < 4) {
        fprintf(stderr, "Usage: validate <so_file> <symbol_name> <scm_file> [...]\n");
        return 1;
    }

    const char *so_file = argv[1];
    const char *symbol_name = argv[2];
    int errors = 0;

    void *handle = dlopen(so_file, RTLD_LAZY);
    if (!handle) {
        fprintf(stderr, "ERROR: cannot load %s: %s\n", so_file, dlerror());
        return 1;
    }

    typedef const TSLanguage *(*LangFunc)(void);
    LangFunc lang_func = (LangFunc)dlsym(handle, symbol_name);
    if (!lang_func) {
        fprintf(stderr, "ERROR: symbol '%s' not found in %s\n", symbol_name, so_file);
        dlclose(handle);
        return 1;
    }

    const TSLanguage *language = lang_func();

    for (int i = 3; i < argc; i++) {
        FILE *f = fopen(argv[i], "r");
        if (!f) {
            fprintf(stderr, "ERROR: cannot open %s\n", argv[i]);
            errors++;
            continue;
        }

        fseek(f, 0, SEEK_END);
        long len = ftell(f);
        fseek(f, 0, SEEK_SET);

        char *source = malloc(len + 1);
        fread(source, 1, len, f);
        source[len] = '\0';
        fclose(f);

        uint32_t error_offset;
        TSQueryError error_type;
        TSQuery *query = ts_query_new(language, source, len, &error_offset, &error_type);

        if (!query) {
            const char *error_names[] = {
                "None", "Syntax", "NodeType", "Field", "Capture", "Structure", "Language"
            };
            const char *ename = (error_type < 7) ? error_names[error_type] : "Unknown";

            /* Check if this file uses '; inherits:' (nvim-treesitter feature) */
            int has_inherits = (strstr(source, "; inherits:") != NULL);

            /* Downgrade to warning for known unsupported features:
               - Structure errors: unsupported query syntax (e.g. field alternation)
               - Files with '; inherits:' directive: reference parent grammar nodes */
            if (error_type == 5 || has_inherits) {
                const char *reason = has_inherits ? "uses '; inherits:'" : "unsupported syntax";
                fprintf(stderr, "  WARN     %s (offset %u: %s - %s)\n",
                        argv[i], error_offset, ename, reason);
            } else {
                fprintf(stderr, "  FAIL     %s (offset %u: %s)\n", argv[i], error_offset, ename);
                errors++;
            }
        } else {
            ts_query_delete(query);
        }

        free(source);
    }

    dlclose(handle);
    return errors > 0 ? 1 : 0;
}
VALIDATE_EOF

cc="${CC:-gcc}"
if ! $cc -o "$VALIDATOR_DIR/validate" "$VALIDATOR_DIR/validate.c" -ltree-sitter -ldl 2>/dev/null; then
    echo 'ERROR: failed to compile validator (is tree-sitter installed?)'
    exit 1
fi
VALIDATOR="$VALIDATOR_DIR/validate"

# Validate one grammar
validate_one() {
    local lang=$1
    local so_file="$BUILD_DIR/$lang.$SO_EXT"
    local grammar_dir="$REPO_ROOT/grammars/$lang"

    if [ ! -f "$so_file" ]; then
        echo "ERROR: $lang: $so_file not found (build it first)"
        return 1
    fi

    # Collect .scm query files from the grammar directory
    local scm_files=()
    for f in "$grammar_dir"/highlights.scm "$grammar_dir"/injections.scm; do
        if [ -f "$f" ]; then
            scm_files+=("$f")
        fi
    done

    if [ ${#scm_files[@]} -eq 0 ]; then
        echo "  SKIP     $lang (no .scm files)"
        return 0
    fi

    local symbol
    symbol=$(get_symbol_name "$lang")
    if [ -z "$symbol" ]; then
        echo "ERROR: $lang: could not determine symbol name"
        return 1
    fi

    if ! "$VALIDATOR" "$so_file" "$symbol" "${scm_files[@]}"; then
        return 1
    else
        echo "  OK       $lang (${#scm_files[@]} query files)"
    fi
}

failed=0
total=${#LANGUAGES[@]}
validated=0

for lang in "${LANGUAGES[@]}"; do
    if validate_one "$lang"; then
        validated=$((validated + 1))
    else
        failed=$((failed + 1))
    fi
done

echo "Validated $validated/$total grammars ($failed failed)"

if [ $failed -gt 0 ]; then
    exit 1
fi
