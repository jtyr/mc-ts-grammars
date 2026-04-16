;; Tree-sitter highlight queries for Erlang
;; Colors aligned with MC's erlang.syntax

;; Control flow keywords -> yellow (@keyword)
[
  "fun"
  "end"
  "if"
  "case"
  "of"
  "receive"
  "after"
  "when"
  "begin"
  "try"
  "catch"
  "maybe"
] @keyword

;; Module directives -> brightmagenta (@delimiter.special)
(module_attribute) @delimiter.special
(export_attribute) @delimiter.special
(export_type_attribute) @delimiter.special
(compile_options_attribute) @delimiter.special
(behaviour_attribute) @delimiter.special
(callback) @delimiter.special
(import_attribute) @delimiter.special

;; Word operators -> brown (@comment) -- MC colors these same as comments
[
  "and"
  "andalso"
  "band"
  "bnot"
  "bor"
  "bsl"
  "bsr"
  "bxor"
  "div"
  "not"
  "or"
  "orelse"
  "rem"
  "xor"
] @comment

(comment) @comment

(string) @string
(char) @string.special

;; Atoms -> lightgray (@constant)
(atom) @constant

;; Variables -> white (@keyword.other)
(var) @keyword.other

;; Function definitions
(function_clause
  name: (atom) @function)

;; Function calls
(call (atom) @function)

;; Operators -> yellow (@keyword)
[
  "->"
  "=>"
  ":="
  "="
  "!"
  "|"
  "::"
  "<-"
  "+"
  "-"
  "*"
  "++"
  "--"
  "<<"
  ">>"
] @keyword

;; Comparison operators -> brown (@comment)
[
  "=="
  "/="
  "=:="
  "=/="
  "<"
  ">"
  "=<"
  ">="
] @comment

;; Delimiters -> brightcyan (@delimiter)
[
  ","
  "."
  ";"
  "("
  ")"
  "["
  "]"
] @delimiter

;; Curly braces -> cyan (@label)
[
  "{"
  "}"
] @label

;; Pipe operators -> brightcyan (@delimiter)
"||" @delimiter
