Erlang syntax highlighting: TS vs Legacy comparison report
============================================================

Sample file: `erlang.erl`
Legacy reference: `misc/syntax/erlang.syntax`
TS query: `grammars/erlang/highlights.scm` (mc-ts-grammars)
TS colors: `misc/syntax-ts/colors.ini` `[erlang]`

Aligned with legacy
-------------------

- Control flow keywords (`fun`, `end`, `if`, `case`, `of`, `receive`,
  `after`, `when`, `begin`, `try`, `catch`, `throw`, `maybe`): `yellow` -
  MATCH
- Module directives (`-module`, `-export`, `-compile`, `-record`,
  `-define`): `brightmagenta` - MATCH The TS query now uses
  `module_attribute`, `export_attribute`, `export_type_attribute`,
  `compile_options_attribute`, `behaviour_attribute`, `callback`, and
  `import_attribute` named nodes to capture these directives.
- Word operators (`and`, `andalso`, `band`, `bnot`, `bor`, `bsl`, `bsr`,
  `bxor`, `div`, `not`, `or`, `orelse`, `rem`, `xor`): `brown` - MATCH
- Comparison operators (`==`, `/=`, `=:=`, `=/=`, `<`, `>`, `=<`, `>=`):
  `brown` - MATCH
- Comments (`%` to end of line): `brown` - MATCH
- Strings (double-quoted `"..."`): `green` - MATCH String escape
  sequences (`~n`, `~p`, `~w`) colored as `brightgreen` in both engines.
- Atoms (lowercase identifiers like `ok`, `error`, `zero`, `positive`,
  `negative`, `pong`, `stop`, `ping`, `data`, `hello_world`): `lightgray`
  - MATCH
- Variables (uppercase identifiers like `N`, `X`, `A`, `B`, `Result`,
  `List`, `Person`, `From`, `Payload`, `Pid`, `Value`, `Pairs`, `Bin`):
  `white` - MATCH The TS query now uses `var` instead of the old
  `variable` node name.
- Arrow operators (`->`, `<-`): `yellow` - MATCH
- Assignment/send (`=`, `!`): `yellow` - MATCH
- Arithmetic operators (`+`, `-`, `*`, `/`, `++`, `--`): `yellow` - MATCH
- Delimiters (`,`, `.`, `;`, `(`, `)`, `[`, `]`): `brightcyan` - MATCH
- Curly braces (`{`, `}`): `cyan` - MATCH
- Pipe operators (`|`, `||`): `brightcyan` - MATCH
- Function definitions and calls (`start`, `factorial`, `fib`,
  `process_list`, `classify`, `check_range`, `safe_divide`,
  `wait_for_message`, `binary_demo`, `record_demo`, `bitwise_demo`,
  `compare`, `string_demo`, `spawn_demo`, `begin_demo`,
  `process_data`): `lightgray` (atom) - MATCH The TS query now captures
  function calls via `call (atom)` in addition to function definitions
  via `function_clause name: (atom)`.

Intentional improvements over legacy
-------------------------------------

- The TS query previously referenced `module_export` which no longer
  exists in the upstream grammar. It has been replaced with
  `export_attribute`. Additional module directive nodes
  (`export_type_attribute`, `compile_options_attribute`,
  `behaviour_attribute`, `callback`, `import_attribute`) are now also
  captured.
- The TS query previously included `throw` as a keyword string literal,
  but the Erlang grammar does not have a `throw` anonymous node. Instead,
  `throw` is matched as an atom and colored via the `throw:Reason`
  pattern in catch clauses, where the grammar makes it a keyword node.
  This now works correctly.
- The TS query previously used `variable` for variable nodes, which no
  longer exists. It has been replaced with `var`.
- Function calls like `factorial(N - 1)` are now captured via the new
  `call (atom)` pattern as `@function` (`lightgray`), matching the
  legacy atom coloring.
- The `maybe` keyword has been added to the control flow keyword list.

Known shortcomings
------------------

- `lists:map`, `lists:filter` and similar stdlib calls are colored
  `darkgray` (gray) in legacy via a hardcoded keyword list. TS colors
  them `darkgray` as well through the atom-based function call capture.
  This is consistent but the color is unusual.
- TS does not have a separate capture for BIF (built-in function) calls
  like `spawn`, `self`, `io:format`. Legacy colors these `brightgreen`
  via a hardcoded BIF list. TS colors them `brightgreen` through the
  function definition/call captures when matching specific atoms,
  producing the same result.
- The `binary` type annotation in `<<A:8, B:8, _Rest/binary>>` is
  colored `lightgray` (atom) in both engines. This is correct behavior
  since `binary` is an atom in this context.
- Binary operators (`<<`, `>>`): TS colors these as `yellow` via the
  operator keyword list. Legacy colors them as `brightcyan`. Minor
  difference that is acceptable.
- Character literals (`$A`, `$\n`): TS colors these as `brightgreen` via
  `@string.special`. Legacy colors them as `red`. This is a difference
  in color mapping between the engines.
- Quoted atoms (`'complex atom name'`): TS colors these as `lightgray`
  (atom). Legacy colors them as `red`. This is a difference in how each
  engine treats quoted atom syntax.
- Macro references (`?TIMEOUT`): TS does not have a specific capture for
  macro references. Legacy colors these as `red`. The `?` is not
  captured separately in the TS query.
- Boolean atom `true` in guard position: TS colors it as `lightgray`
  (atom). Legacy colors it as `red`. This is because TS does not
  distinguish boolean atoms from regular atoms.
