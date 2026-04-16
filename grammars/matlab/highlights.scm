;; Tree-sitter highlight queries for MATLAB/Octave
;; Colors aligned with MC's octave.syntax

;; Control flow keywords -> white (@keyword.other)
[
  "if"
  "else"
  "elseif"
  "for"
  "while"
  "switch"
  "case"
  "otherwise"
  "try"
  "catch"
  "return"
  "continue"
  "break"
  "classdef"
  "methods"
  "events"
  "enumeration"
  "properties"
] @keyword.other

(end) @keyword.other
(function_keyword) @keyword.other

;; Comments -> brown
(comment) @comment

;; Strings -> green
(string) @string

;; Numbers
(number) @string.special

;; Boolean literals
(bool) @string.special

;; Operators -> brightcyan (@operator)
[
  "="
  "+"
  "*"
  "/"
  "\\"
  "^"
  ".*"
  "./"
  ".^"
  "<"
  ">"
  "<="
  ">="
  "=="
  "~="
  "&"
  "&&"
  "||"
  "~"
] @operator

;; Delimiters -> brightcyan (@delimiter)
[
  ","
  ";"
  "("
  ")"
  "["
  "]"
  "{"
  "}"
] @delimiter
