#!/bin/bash
#
# Reconcile metadata flags in grammars.yaml to match actual file presence.
#
# Usage:
#   reconcile-metadata.sh [--check] [--all] [<language> ...]
#
# Modes:
#   (default)    - apply fixes in place
#   --check      - report drift, exit non-zero if any (grammars.yaml unchanged)
#
# Flags reconciled (derived from files under grammars/<lang>/src/):
#   hasParser      - src/grammar.js or src/src/parser.c present
#   hasScanner     - src/src/scanner.c or src/src/scanner.cc present
#   hasHighlights  - src/queries/highlights.scm present
#   hasLocals      - src/queries/locals.scm present
#   hasInjections  - src/queries/injections.scm present
#   hasFolds       - src/queries/folds.scm present
#   hasIndents     - src/queries/indents.scm present
#   hasTags        - src/queries/tags.scm present
#
# Non-derivable flags (gitTags, abi) are left untouched.
# Only entries with enabled != false are reconciled.
#
# For a language with a single enabled entry, flags are both added and removed
# to match the files on disk. For a language with multiple enabled entries
# (e.g. a parser entry + a queries-only entry from nvim-treesitter), we can
# only reliably detect lying flags - the reconcile is remove-only in that case,
# because disk state is the union of all entries and we cannot tell from disk
# alone which entry should own a given file.

set -uo pipefail

SCRIPT_DIR=$(dirname "$0")
REPO_ROOT=$(realpath "$SCRIPT_DIR/..")
REGISTRY="$REPO_ROOT/grammars.yaml"

MODE=fix
LANGS=()

while [ $# -gt 0 ]; do
    case "$1" in
        --check) MODE=check; shift ;;
        --all)
            shift
            mapfile -t LANGS < <(
                yq -r '.[] | select(.enabled != false) | .language' "$REGISTRY" | sort -u
            )
            ;;
        -h|--help)
            sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *) LANGS+=("$1"); shift ;;
    esac
done

if [ "${#LANGS[@]}" -eq 0 ]; then
    echo 'Usage: reconcile-metadata.sh [--check] [--all] [<language> ...]' >&2
    exit 1
fi

python3 - "$MODE" "$REGISTRY" "$REPO_ROOT" "${LANGS[@]}" <<'PYEOF'
import os
import re
import sys
from collections import defaultdict

import yaml

mode, registry, repo_root, *langs = sys.argv[1:]
lang_set = set(langs)

QUERIES = {
    "hasHighlights": "highlights.scm",
    "hasLocals": "locals.scm",
    "hasInjections": "injections.scm",
    "hasFolds": "folds.scm",
    "hasIndents": "indents.scm",
    "hasTags": "tags.scm",
}
FLAGS = ["hasParser", "hasScanner", *QUERIES.keys()]


def detect(lang):
    src = os.path.join(repo_root, "grammars", lang, "src")
    if not os.path.isdir(src):
        return None
    res = {
        "hasParser": os.path.isfile(os.path.join(src, "grammar.js"))
        or os.path.isfile(os.path.join(src, "src", "parser.c")),
        "hasScanner": os.path.isfile(os.path.join(src, "src", "scanner.c"))
        or os.path.isfile(os.path.join(src, "src", "scanner.cc")),
    }
    for flag, fname in QUERIES.items():
        res[flag] = os.path.isfile(os.path.join(src, "queries", fname))
    return res


with open(registry) as f:
    data = yaml.safe_load(f)
with open(registry) as f:
    lines = f.readlines()

enabled_entries_by_lang = defaultdict(list)
for idx, g in enumerate(data):
    if g.get("enabled", True) is False:
        continue
    enabled_entries_by_lang[g["language"]].append((idx, g))

# drifts: list of (lang, entry_idx, flag, want).
# want=False => remove flag; want=True => add flag (single-entry only).
drifts = []
for lang, entries in enabled_entries_by_lang.items():
    if lang not in lang_set:
        continue
    actual = detect(lang)
    if actual is None:
        continue
    single = len(entries) == 1
    for idx, g in entries:
        meta = g.get("metadata") or {}
        for flag in FLAGS:
            have = bool(meta.get(flag))
            if have and not actual[flag]:
                drifts.append((lang, idx, flag, False))
            elif single and not have and actual[flag]:
                drifts.append((lang, idx, flag, True))

if not drifts:
    print("All metadata flags match reality.")
    sys.exit(0)

if mode == "check":
    print(f"Found {len(drifts)} metadata drift(s):")
    for lang, _, flag, want in drifts:
        action = "add" if want else "remove"
        print(f"  {lang}: {action} {flag}")
    sys.exit(1)


def find_entries(lines):
    """Return [(start_line, end_line)] for each '- language:' entry, in order."""
    entries = []
    cur_start = None
    for i, line in enumerate(lines):
        if re.match(r"^- language: (\S+)", line):
            if cur_start is not None:
                entries.append((cur_start, i))
            cur_start = i
    if cur_start is not None:
        entries.append((cur_start, len(lines)))
    return entries


entries = find_entries(lines)
assert len(entries) == len(data), (
    f"entry count mismatch: {len(entries)} line-level vs {len(data)} parsed"
)

# Group drifts by entry_idx so we edit each entry once.
by_entry = defaultdict(list)
for lang, idx, flag, want in drifts:
    by_entry[idx].append((flag, want))

edits = [(entries[idx][0], entries[idx][1], fs) for idx, fs in by_entry.items()]
edits.sort(key=lambda x: x[0], reverse=True)

for s, e, flag_list in edits:
    meta_line = None
    for i in range(s, e):
        if lines[i].startswith("  metadata:"):
            meta_line = i
            break
    if meta_line is None:
        insert_at = e
        while insert_at > s and lines[insert_at - 1].strip() == "":
            insert_at -= 1
        block = ["  metadata:\n"]
        for flag, want in flag_list:
            if want:
                block.append(f"    {flag}: true\n")
        lines[insert_at:insert_at] = block
        continue

    meta_end = meta_line + 1
    while meta_end < e:
        ln = lines[meta_end]
        if ln.strip() == "" or re.match(r"^ {4}\S", ln):
            meta_end += 1
        else:
            break

    for flag, want in flag_list:
        if not want:
            pat = re.compile(r"^\s*" + re.escape(flag) + r":\s*true\s*$")
            for j in range(meta_line + 1, meta_end):
                if pat.match(lines[j].rstrip()):
                    lines.pop(j)
                    meta_end -= 1
                    break

    for flag, want in flag_list:
        if want:
            insert_at = meta_end
            for j in range(meta_line + 1, meta_end):
                m = re.match(r"^ {4}(\S+):", lines[j])
                if m and not m.group(1).startswith("has"):
                    insert_at = j
                    break
            lines.insert(insert_at, f"    {flag}: true\n")
            meta_end += 1

with open(registry, "w") as f:
    f.writelines(lines)

print(f"Reconciled {len(drifts)} flag(s):")
for lang, _, flag, want in drifts:
    action = "added" if want else "removed"
    print(f"  {lang}: {action} {flag}")
PYEOF
