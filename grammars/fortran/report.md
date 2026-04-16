Fortran syntax highlighting: TS vs Legacy comparison report
=============================================================

Sample file: `fortran.f90`
Legacy reference: `misc/syntax/fortran.syntax`
TS query: `grammars/fortran/highlights.scm` (mc-ts-grammars)
TS colors: `misc/syntax-ts/colors.ini` `[fortran]`

Aligned with legacy
-------------------

- Type declarations (`integer`, `real`, `character`, `logical`, `complex`,
  `double`): `brightcyan` - MATCH
- Declaration keywords (`dimension`, `allocatable`, `intent`, `in`, `out`,
  `inout`, `parameter`, `type`, `contains`, `public`, `private`,
  `pointer`, `target`, `save`): `brightcyan` - MATCH
- Control flow (`do`, `if`, `then`, `else`, `elseif`, `endif`, `enddo`,
  `call`, `return`, `stop`, `continue`, `cycle`, `exit`, `goto`, `while`,
  `select`, `case`, `default`, `allocate`, `deallocate`): `brightgreen` -
  MATCH
- I/O keywords (`read`, `write`, `print`, `open`, `close`, `inquire`):
  `brightmagenta` - MATCH
- Program structure keywords (`program`, `subroutine`, `function`,
  `module`, `end`, `use`, `implicit`, `result`, `recursive`): `yellow` -
  MATCH
- Comments (`!` to end of line): `brown` - MATCH
- Strings (single-quoted `'...'` and double-quoted `"..."`): `green` -
  MATCH
- Boolean literals (`.true.`, `.false.`): `brightred` - MATCH
- Logical/relational operators (`.and.`, `.or.`, `.not.`): `brightred` -
  MATCH Now captured via field-based `logical_expression`,
  `relational_expression`, and `unary_expression` operator wildcard
  patterns as `@function.special`.
- Arithmetic operators (`+`, `-`, `*`, `/`, `**`, `=`): `yellow` - MATCH
- Delimiters (`,`, `::`, `(`, `)`): `brightcyan` - MATCH

Intentional improvements over legacy
-------------------------------------

- The TS query previously listed specific operator literals like `.eq.`,
  `.ne.`, `.gt.`, `.lt.`, `.ge.`, `.le.` as string matches. These have
  been replaced with wildcard `operator: _` patterns on
  `logical_expression`, `relational_expression`, and `unary_expression`
  nodes, which correctly captures all operator forms regardless of
  spelling (e.g., `.eq.` vs `==`).
- Many new keywords have been added to the TS query: `submodule`,
  `elemental`, `pure`, `impure` (program structure); `block`, `common`,
  `external`, `format`, `class`, `interface`, `abstract`, `extends`,
  `procedure`, `intrinsic`, `optional`, `value`, `volatile`, `sequence`,
  `generic`, `contiguous`, `protected`, `bind` (declaration);
  `where`, `elsewhere`, `forall`, `selectcase`, `selecttype`, `selectrank`,
  `associate`, `critical`, `concurrent`, `assign`, `entry`, `pause`,
  `nullify` (control flow); `rewind`, `backspace`, `endfile`, `flush`,
  `wait` (I/O).
- `deallocate` is now included in the `@number.builtin` control flow
  list, matching legacy behavior.
- `precision` is now colored `brightcyan` via the `doubleprecision` and
  `double` type keywords.

Known shortcomings
------------------

- Comparison operators (`==`, `/=`, `<`, `>`, `<=`, `>=`): TS colors
  these as `yellow` via `@operator.word`. Legacy colors them as
  `brightred` via the operator patterns. This is a deliberate difference
  - TS groups symbolic comparison operators with arithmetic operators
  rather than with dot-form operators like `.eq.`.
- `name` identifier: legacy colors `name` as `brightmagenta` because it
  matches the I/O keyword `name` in the legacy list. TS correctly treats
  `name` as a regular identifier when used as a variable name. This is
  actually a legacy false positive.
- `implicit none`: TS colors `implicit` and `none` both as `yellow`
  (`@keyword`). Legacy colors both as `brightcyan`. Minor difference in
  keyword categorization.
- I/O specifier keywords within parenthesized I/O statements (e.g.,
  `unit=`, `file=`, `status=`, `exist=`): legacy colors these as
  `brightmagenta` via the I/O keyword list. TS does not color these
  specifiers when they appear as assignment targets in I/O calls.
- Statement label `100` at column 1: legacy colors the label with
  `brightred`. TS colors it as `brightred` via `@label`
  (`statement_label`), achieving the same result through a different
  mechanism.
- Mathematical functions (`sqrt`, `mod`, `real`): legacy colors these as
  `yellow` via a hardcoded list. TS does not capture intrinsic function
  calls specially - they appear uncolored or as default text.
- `result` keyword: TS colors `result` as `yellow` (`@keyword`). However,
  the grammar does not always emit a matchable `result` node, so in some
  contexts it may appear uncolored.
- `recursive` keyword: TS includes `recursive` in the `@keyword` list,
  but the grammar may not always emit it as a matchable node.
- `only` keyword after `use`: TS colors `only` as `yellow`. Legacy
  colors it as `brightcyan` via the declaration keyword list.
- `target` keyword: TS colors `target` as `brightcyan` (`@property`).
  Legacy colors it as `brightgreen` (`@number.builtin`). Minor
  difference in categorization.
