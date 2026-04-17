# MC Tree-sitter Grammars

Community-driven tree-sitter grammar installer and distribution for
[GNU Midnight Commander](https://github.com/MidnightCommander/mc).

## Overview

MC ships with built-in tree-sitter integration but no grammars by
default (similar to Neovim, Helix, and Emacs). This project provides:

- A **grammar registry** (`grammars.yaml`) tracking upstream grammar
  repositories.
- Pre-built **grammar libraries** (`.so`/`.dylib`/`.dll`) published as
  release bundles.
- MC-curated **query files** (`.scm`) tailored to MC's terminal
  rendering.
- Self-contained **per-grammar config** in INI format.
- An **installer tool** (`mc-ts-grammar`) to download/build and install
  grammars.

## Quick start

Download the installer from the
[latest release](https://github.com/jtyr/mc-ts-grammars/releases/latest):

```bash
curl -LO https://github.com/jtyr/mc-ts-grammars/releases/latest/download/mc-ts-grammar
chmod +x mc-ts-grammar
```

Install all grammars:

```bash
./mc-ts-grammar install --all
```

Or install specific grammars:

```bash
./mc-ts-grammar install python bash yaml markdown
```

Optionally move the installer to a directory in your `PATH`:

```bash
mv mc-ts-grammar ~/.local/bin/
```

## Installer

The `mc-ts-grammar` tool manages grammar installation and removal.

```text
Usage: mc-ts-grammar <command> [options]

Commands:
  build      Build grammars from source (run from cloned repo)
  install    Install grammars from pre-built release bundles
  update     Update installed grammars to latest release
  list       List installed grammars
  available  List grammars available in a release bundle
  uninstall  Remove installed grammars

Global options:
  --dir PATH      Install prefix (default: ~/.local)
  --libdir PATH   Library install path (default: <prefix>/lib)
  --help, -h      Show this help message

Run 'mc-ts-grammar <command> --help' for command-specific options.
```

### install

Install grammars from a pre-built release bundle. The platform is
auto-detected and the bundle is cached in `~/.cache/mc-ts-grammar/`.

```bash
# Install all available grammars
mc-ts-grammar install --all

# Install specific grammars
mc-ts-grammar install python bash yaml

# Install a specific version
mc-ts-grammar install python --version 2026.04.14

# Install to a custom prefix
mc-ts-grammar install python --dir /usr/local

# Install with separate lib path (e.g. Fedora)
mc-ts-grammar install --all --dir /usr --libdir /usr/lib64
```

### update

Update installed grammars to the latest release.

```bash
# Update all installed grammars
mc-ts-grammar update --all

# Update specific grammars
mc-ts-grammar update python bash
```

### build

Build grammars locally from a cloned copy of this repository. Requires
a C compiler and the
[tree-sitter CLI](https://tree-sitter.github.io/tree-sitter/).

```bash
# Build all MC-supported grammars
mc-ts-grammar build

# Build, validate, and install
mc-ts-grammar build --install --validate
```

### list

List installed grammars with version and scope information.

```bash
mc-ts-grammar list
```

```text
Grammar         Version        Scope
python          2026.04.17     local
bash            2026.04.17     system
```

Use `--verbose` to show installation paths.

### available

List grammars available in a release bundle and show which are
already installed.

```bash
# Show latest release
mc-ts-grammar available

# Show a specific release
mc-ts-grammar available --version 2026.04.17
```

### uninstall

Remove installed grammars.

```bash
# Remove specific grammars
mc-ts-grammar uninstall python bash

# Remove all user-local grammars
mc-ts-grammar uninstall --all

# Remove from system path
sudo mc-ts-grammar uninstall python --dir /usr
```

### Install paths

```text
<prefix>/share/mc/syntax-ts/<lang>/config.ini
<prefix>/share/mc/syntax-ts/<lang>/highlights.scm
<prefix>/share/mc/syntax-ts/<lang>/injections.scm  (if present)
<libdir>/mc/ts-grammars/<lang>.so
```

## Per-grammar config format

Each grammar has a `config.ini` file with metadata and colors:

```ini
[grammar]
extensions=.py .pyw .pyi
filenames=SConstruct SConscript
shebangs=python python3
display-name=Python

[colors]
comment=brown;
keyword=yellow;
string=green;
function.special=brightred;
variable.builtin=brightred;
```

The `[grammar]` section holds file matching rules, display name, and
optional fields like `symbol` (override for the
`tree_sitter_<name>()` function) and `wrapper` (for template
languages like `gotmpl`).

The `[colors]` section maps tree-sitter capture names to MC terminal
colors (16 ANSI colors plus MC extras `brown` and `lightgray`).

## Testing highlighting quality

Each grammar with MC support includes a `report.md` comparing
tree-sitter highlighting against MC's legacy regex-based engine, and
a `examples/` directory with test files:

```text
grammars/python/
  report.md          # TS vs Legacy comparison
  examples/
    example.py       # example file for testing
```

To regenerate a report, use the `mc-syntax-dump` tool from the
[MC fork](https://github.com/jtyr/mc) (branch `jtyr-ts`). Build it
from `tests/syntax/`:

```bash
cd <path_to_mc>/tests/syntax
make
```

Then compare TS and Legacy output for a grammar:

```bash
# TS highlighting using queries from this repo
<path_to_mc>/tests/syntax/mc-syntax-dump --ts \
    --grammar-dir grammars/python \
    --lib-dir build \
    grammars/python/examples/example.py

# Legacy highlighting
<path_to_mc>/tests/syntax/mc-syntax-dump --legacy \
    grammars/python/examples/example.py
```

The `--grammar-dir` option points to a per-grammar directory
containing `highlights.scm` and `config.ini`. The `--lib-dir` option
points to the directory with built `.so` files. This allows testing
queries directly from a development checkout without installing them.

## Contributing grammars

To add MC support for a new grammar:

1. Ensure the grammar is listed in `grammars.yaml` (with upstream URL
   and ref).
2. Create `grammars/<lang>/highlights.scm` with MC-curated capture
   names.
3. Create `grammars/<lang>/config.ini` with file matching rules and
   colors.
4. Optionally create `grammars/<lang>/injections.scm` for language
   injection support.
5. Set `release: true` in the grammar's `grammars.yaml` entry.
6. Submit a pull request.

## Release bundles

CI builds grammar libraries for 5 platforms:

- `x86_64-linux`
- `aarch64-linux`
- `x86_64-macos`
- `aarch64-macos`
- `x86_64-windows`

Each release tarball contains all grammars with `release: true` in
`grammars.yaml`. A `mc-ts-grammars.sha256` checksum file is published
alongside.

## Distro packaging

Each grammar is independent and can be packaged separately:

```text
Package: mc-ts-grammar-python
Files:
  /usr/lib/mc/ts-grammars/python.so
  /usr/share/mc/syntax-ts/python/config.ini
  /usr/share/mc/syntax-ts/python/highlights.scm
```

## Running tests

The installer has a test suite using
[bats](https://github.com/bats-core/bats-core):

```bash
bats tests/installer.bats
```

## License

Grammar libraries are built from upstream sources, each with their own
license. The LICENSE file for each grammar is included in the release
bundle. MC-curated query files and config files in this repository are
provided under the same license as
[GNU Midnight Commander](https://github.com/MidnightCommander/mc).
