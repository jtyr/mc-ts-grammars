IDL syntax highlighting: TS vs Legacy comparison report
========================================================

Sample file: `idl.idl`
Legacy reference: `misc/syntax/idl.syntax`
TS query: `grammars/idl/highlights.scm` (mc-ts-grammars)
TS colors: `misc/syntax-ts/colors.ini` `[idl]`

Aligned with legacy
-------------------

- Keywords (`module`, `interface`, `struct`, `union`, `enum`, `typedef`,
  `const`, `exception`, `valuetype`, `switch`, `case`, `default`, `void`,
  `in`, `out`, `inout`, `raises`, `readonly`, `attribute`, `oneway`,
  `context`): `yellow` - MATCH
- Type keywords (`short`, `long`, `float`, `double`, `string`, `wstring`,
  `any`, `sequence`, `fixed`, `Object`): `yellow` - MATCH
- Boolean type (`boolean`): `yellow` - MATCH Now captured via the
  `boolean_type` named node.
- Unsigned types (`unsigned short`, `unsigned long`): `yellow` - MATCH
  Now captured via `unsigned_short_int`, `unsigned_long_int`, and other
  integer type named nodes.
- `char` type: `yellow` - MATCH Now captured via `char_type` named node.
- `octet` type: `yellow` - MATCH Now captured via `octet_type` named
  node.
- `wchar` type: `yellow` - MATCH Now captured via `wide_char_type` named
  node.
- Boolean literals (`TRUE`, `FALSE`): `yellow` - MATCH
- Comments (line `//` and block `/* */`): `brown` - MATCH
- Strings (double-quoted `"..."`): `green` - MATCH
- Char literals (`'X'`): `brightgreen` - MATCH
- Operators (`+`, `-`, `*`, `/`, `%`, `=`, `::`, `<<`, `>>`, `~`):
  `yellow` - MATCH
- Brackets (`{`, `}`, `(`, `)`, `[`, `]`): `brightcyan` - MATCH
- Punctuation (`,`, `:`, `<`, `>`): `brightcyan` - MATCH
- Semicolons (`;`): `brightmagenta` - MATCH

Intentional improvements over legacy
-------------------------------------

- The TS query previously used string literals like `"unsigned"`,
  `"char"`, `"octet"`, `"wchar"` which did not match the grammar's
  actual node structure. These have been replaced with named nodes
  (`boolean_type`, `octet_type`, `char_type`, `wide_char_type`,
  `any_type`, `value_base_type`, `signed_short_int`,
  `unsigned_short_int`, etc.) which correctly match the grammar output.
- Multi-word type keywords like `"unsigned short"`, `"unsigned long"`,
  `"long long"`, `"long double"` are now included as string literals in
  the keyword list, and their constituent named nodes are captured
  separately, ensuring proper coloring.
- Preprocessor directives (`#ifndef`, `#define`, `#include`, `#pragma`,
  `#endif`): TS colors these as `brightmagenta` via `keyword.control`.
  Legacy uses `brightred`. The TS approach captures the entire
  preprocessor statement more precisely.
- The `public` and `private` keywords (in valuetype): TS colors these as
  `yellow` via the keyword list. Legacy does not include `public` and
  `private` in its keyword list, leaving them as default text.
- System include strings (`<orb.idl>`): TS captures these via
  `system_lib_string` as `green`. Legacy colors the angle brackets as
  operators and the path as `red` inside the preprocessor context.
- The `map` type keyword: TS includes `map` in the keyword list. Legacy
  does not have `map` as a keyword.

Known shortcomings
------------------

- Integer literals (`1024`, `0xFF`, `0x0A`, `0x50`, `10`, `2`): TS
  colors these as `brightgreen` via `@string.special`. Legacy leaves
  them uncolored. This is an intentional TS addition but differs from
  legacy.
- Preprocessor string content: legacy colors `"types.idl"` as `red`
  inside the preprocessor context. TS colors it as `green` (via
  `string_literal`), matching the standard string color. This is
  arguably better but differs from legacy.
- The `#endif` line with a trailing comment: TS colors `#endif` as
  `brightmagenta` and the `// _SAMPLE_IDL_` comment continuation as
  `brown`. Legacy colors the entire line as `brightred`.
- The `|` operator in `0x0A | 0x50`: neither TS nor legacy captures the
  `|` operator, leaving it as default text.
- The `fixed` type with angle brackets (`fixed<10,2>`): TS colors
  `fixed` as `yellow` and the angle brackets as `brightcyan` delimiters.
  Legacy colors `fixed<` as a single `yellow` token and `>` similarly.
- `sequence<string>` and `sequence<long, 10>`: TS properly separates the
  keyword from the angle brackets. Legacy treats `sequence<string>` as a
  single keyword token.
