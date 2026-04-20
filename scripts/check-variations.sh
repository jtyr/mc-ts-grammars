#!/bin/bash
#
# Validate grammar variation entries in grammars.yaml against the filesystem.
#
# Usage: check-variations.sh
#
# Emits two kinds of findings:
#
#   WARN  (exit 0) - A variation directory exists under grammars/<lang>/variations/
#                    but is not listed in the parent's variations field. May be
#                    intentional (work in progress, disabled for now).
#
#   ERROR (exit 1) - A variation name collides with a real grammar language.
#                    Variations are flattened to the top level of the release
#                    tarball, so a collision would silently overwrite another
#                    grammar's config.ini and query files.

set -uo pipefail

SCRIPT_DIR=$(dirname "$0")
REPO_ROOT=$(realpath "$SCRIPT_DIR/..")
REGISTRY="$REPO_ROOT/grammars.yaml"

python3 - "$REGISTRY" "$REPO_ROOT" <<'PYEOF'
import os
import sys
from collections import defaultdict

import yaml

registry, repo_root = sys.argv[1:]

with open(registry) as f:
    data = yaml.safe_load(f)

# Set of all language names (including disabled entries) so we can detect
# collisions between a variation name and any real grammar language.
all_languages = {g["language"] for g in data}

# Collect declared variations per parent language. Multiple enabled entries
# for the same language are merged (the variations list is effectively
# per-language, not per-entry).
declared = defaultdict(set)
for g in data:
    if g.get("enabled", True) is False:
        continue
    for v in g.get("variations", []) or []:
        declared[g["language"]].add(v)

warnings = 0
errors = 0

# Variation name must not collide with any real grammar. Flattened packaging
# would overwrite the sibling grammar's config and queries in the tarball.
for lang, names in declared.items():
    for variation in sorted(names):
        if variation in all_languages:
            print(
                f"ERROR: {lang}.variations lists '{variation}' but a grammar "
                f"with that name already exists in grammars.yaml. Variation "
                f"names must be unique across all grammars - release packaging "
                f"flattens variations to the top level of the tarball and would "
                f"overwrite {variation}/config.ini and query files."
            )
            errors += 1

grammars_dir = os.path.join(repo_root, "grammars")
if os.path.isdir(grammars_dir):
    for lang in sorted(os.listdir(grammars_dir)):
        variations_dir = os.path.join(grammars_dir, lang, "variations")
        if not os.path.isdir(variations_dir):
            continue
        for variation in sorted(os.listdir(variations_dir)):
            if not os.path.isdir(os.path.join(variations_dir, variation)):
                continue
            if variation not in declared.get(lang, set()):
                print(
                    f"WARN: grammars/{lang}/variations/{variation}/ exists "
                    f"but is not listed under {lang}.variations in grammars.yaml "
                    f"(it will not be released)"
                )
                warnings += 1

# Warn about variations listed in grammars.yaml without a matching directory.
for lang, names in declared.items():
    for variation in sorted(names):
        variations_dir = os.path.join(grammars_dir, lang, "variations", variation)
        if not os.path.isdir(variations_dir):
            print(
                f"WARN: {lang}.variations lists '{variation}' in grammars.yaml "
                f"but grammars/{lang}/variations/{variation}/ does not exist"
            )
            warnings += 1

if errors == 0 and warnings == 0:
    print("All variation directories match grammars.yaml.")

if errors > 0:
    sys.exit(1)
PYEOF
