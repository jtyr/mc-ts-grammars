MATLAB syntax highlighting: TS vs Legacy comparison report
==========================================================

Sample file: `matlab.m`
Legacy reference: `misc/syntax/octave.syntax`
TS query: `grammars/matlab/highlights.scm` (mc-ts-grammars)
TS colors: `misc/syntax-ts/colors.ini` `[matlab]`

Aligned with legacy
-------------------

- Control flow keywords (`if`, `else`, `elseif`, `for`, `while`,
  `switch`, `case`, `break`): `white` - MATCH
- `function` keyword: `white` - MATCH Now captured via the
  `function_keyword` named node instead of the `"function"` string
  literal.
- `end` keyword: `white` - MATCH Now captured via the `(end)` named node
  instead of the `"end"` string literal.
- Comments (`%` line comments and `%{ %}` block comments): `brown` -
  MATCH
- Double-quoted strings (`"..."`): `green` - MATCH
- Operators (`=`, `+`, `*`, `/`, `^`, `<`, `>`, `<=`, `>=`, `==`, `~=`,
  `&&`, `||`, `~`): `brightcyan` - MATCH
- Element-wise operators (`.*`, `./`, `.^`): `brightcyan` - MATCH
- Delimiters (`(`, `)`, `[`, `]`, `{`, `}`, `,`, `;`): `brightcyan` -
  MATCH
- `global` keyword: `white` - MATCH

Intentional improvements over legacy
-------------------------------------

- The TS query underwent a major rewrite to align with upstream grammar
  node name changes. Key changes:
  - `function_keyword` named node replaces the `"function"` string
    literal, which no longer matches in the grammar.
  - `(end)` named node replaces the `"end"` string literal, which no
    longer matches in the grammar.
  - Operators are now specified as anonymous string literals (e.g., `"="`,
    `"+"`, `"*"`) rather than relying on named nodes that no longer
    exist.
  - Removed references to nodes that no longer exist in the upstream
    grammar.
- `methods` keyword: TS colors this as `yellow` (`@keyword`) via the
  legacy built-in function name. Legacy also colors it as `yellow`. Both
  engines match, though through different mechanisms.

Known shortcomings
------------------

- `classdef`, `properties`, `events`, `enumeration` keywords: TS now
  includes these in the `@keyword.other` list but the grammar does not
  emit matching nodes for all of them, so some may remain uncolored.
  Legacy also leaves these uncolored.
- `otherwise` keyword: TS includes it in the keyword list but the grammar
  may not produce a matching node. Legacy also leaves it uncolored.
- `try` and `catch` keywords: TS includes these in the keyword list but
  the grammar may not emit matching nodes. Legacy also leaves them
  uncolored.
- `continue` keyword: TS includes it in the keyword list but it appears
  uncolored in the TS output. Legacy colors it as `white`.
- `parfor` and `spmd` keywords: not in the TS keyword list. Legacy also
  leaves them uncolored. Both appear as default text.
- Single-quoted strings (`'...'`): TS does not color these as `green`.
  Legacy also does not color them as `green` (they appear as default
  text). Both engines treat single-quoted character arrays the same way.
- Number literals: TS colors these as `brightgreen` via `@string.special`.
  Legacy leaves them uncolored. This is a difference between the engines.
- Built-in function names (`disp`, `fprintf`, `sprintf`, `sqrt`, `mod`):
  legacy colors these as `yellow` via a hardcoded keyword list. TS does
  not have a built-in function capture, so these appear uncolored unless
  the grammar produces a specific node type.
- Format specifiers (`%s`, `%d`, `%f`) inside strings trigger the legacy
  comment coloring since `%` starts a comment in MATLAB. This causes
  `fprintf('%s: %f\n', ...)` and `sprintf('formatted: %d ...')` to break
  in legacy, with everything after `%` colored as a comment. TS avoids
  this problem when strings are properly captured.
- The `-` operator appears uncolored in some TS contexts (e.g.,
  `n - 1`). The `"-"` anonymous literal is not in the TS operator list
  because it conflicts with the unary minus in some grammar contexts.
- Block comments (`%{ ... %}`): TS colors these uniformly as `brown`.
  Legacy also colors them as `brown` but with different boundary
  handling.
- Cell array braces and struct dot access: both engines handle these
  identically with `brightcyan` delimiters.
- `persistent` and `arguments` keywords: not in the TS keyword list.
  Legacy also leaves them uncolored.
