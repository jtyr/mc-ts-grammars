;; Tree-sitter highlight queries for Fortran
;; Colors aligned with MC's fortran.syntax

;; Type declarations -> brightcyan (@property)
[
  "integer"
  "real"
  "character"
  "logical"
  "complex"
  "double"
  "doubleprecision"
  "doublecomplex"
] @property

;; Program structure keywords -> yellow (@keyword)
[
  "program"
  "end"
  "subroutine"
  "function"
  "module"
  "submodule"
  "use"
  "implicit"
  "none"
  "only"
  "result"
  "recursive"
  "elemental"
  "pure"
  "impure"
] @keyword

;; Declaration keywords -> brightcyan (@property)
[
  "dimension"
  "allocatable"
  "intent"
  "in"
  "out"
  "inout"
  "parameter"
  "data"
  "block"
  "common"
  "external"
  "format"
  "type"
  "class"
  "interface"
  "contains"
  "public"
  "private"
  "abstract"
  "extends"
  "procedure"
  "intrinsic"
  "save"
  "target"
  "pointer"
  "optional"
  "value"
  "volatile"
  "sequence"
  "generic"
  "contiguous"
  "protected"
  "bind"
] @property

;; Control flow -> brightgreen (@number.builtin)
[
  "do"
  "if"
  "then"
  "else"
  "elseif"
  "endif"
  "enddo"
  "call"
  "return"
  "stop"
  "continue"
  "cycle"
  "exit"
  "goto"
  "while"
  "where"
  "elsewhere"
  "forall"
  "select"
  "selectcase"
  "selecttype"
  "selectrank"
  "case"
  "default"
  "associate"
  "critical"
  "concurrent"
  "assign"
  "entry"
  "pause"
  "allocate"
  "deallocate"
  "nullify"
] @number.builtin

;; I/O keywords -> brightmagenta (@constant.builtin)
[
  "read"
  "write"
  "print"
  "open"
  "close"
  "inquire"
  "rewind"
  "backspace"
  "endfile"
  "flush"
  "wait"
  "format"
] @constant.builtin

(comment) @comment

(string_literal) @string

;; Number literals
(number_literal) @constant

;; Statement labels
(statement_label) @label

;; Boolean literals -> brightred (@function.special)
(boolean_literal) @function.special

;; Operators -> yellow (@operator.word)
[
  "="
  "+"
  "-"
  "*"
  "/"
  "**"
  "=="
  "/="
  "<"
  ">"
  "<="
  ">="
  "//"
] @operator.word

;; Logical/relational operators -> brightred (@function.special)
(logical_expression
  operator: _ @function.special)
(relational_expression
  operator: _ @function.special)
(unary_expression
  operator: _ @function.special)

;; Delimiters
[
  ","
  "::"
  "("
  ")"
] @delimiter
