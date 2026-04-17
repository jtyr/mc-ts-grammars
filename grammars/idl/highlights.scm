;; Tree-sitter highlight queries for IDL (Interface Definition Language)
;; Colors aligned with MC's idl.syntax
;; MC: keywords=yellow, operators=yellow, comments=brown, strings=green

;; Keywords -> yellow (@keyword)
[
  "module"
  "interface"
  "struct"
  "union"
  "enum"
  "typedef"
  "const"
  "exception"
  "valuetype"
  "eventtype"
  "component"
  "home"
  "factory"
  "finder"
  "native"
  "local"
  "abstract"
  "custom"
  "truncatable"
  "supports"
  "public"
  "private"
  "switch"
  "case"
  "default"
  "void"
  "in"
  "out"
  "inout"
  "raises"
  "readonly"
  "attribute"
  "oneway"
  "context"
  "import"
  "provides"
  "uses"
  "emits"
  "publishes"
  "consumes"
  "manages"
  "primarykey"
  "porttype"
  "port"
  "mirrorport"
  "connector"
  "multiple"
  "typeid"
  "typeprefix"
] @keyword

;; Type keywords -> yellow (@keyword)
[
  "short"
  "long"
  "long long"
  "unsigned short"
  "unsigned long"
  "unsigned long long"
  "long double"
  "float"
  "double"
  "string"
  "wstring"
  "any"
  "sequence"
  "map"
  "fixed"
  "Object"
] @keyword

;; Named type nodes -> yellow (@keyword)
(boolean_type) @keyword
(octet_type) @keyword
(char_type) @keyword
(wide_char_type) @keyword
(any_type) @keyword
(value_base_type) @keyword

;; Integer type nodes -> yellow (@keyword)
(signed_short_int) @keyword
(signed_long_int) @keyword
(signed_longlong_int) @keyword
(unsigned_short_int) @keyword
(unsigned_long_int) @keyword
(unsigned_longlong_int) @keyword
(signed_tiny_int) @keyword
(unsigned_tiny_int) @keyword

;; Boolean literals -> yellow (@keyword)
[
  "TRUE"
  "FALSE"
] @keyword

;; Operators -> yellow (@operator.word)
[
  "+"
  "-"
  "*"
  "/"
  "%"
  "="
  "::"
  "<<"
  ">>"
  "~"
] @operator.word

;; Preprocessor -> brightmagenta (@keyword.control)
(preproc_define) @keyword.control
(preproc_call) @keyword.control
(preproc_include) @keyword.control

;; Comments -> brown
(comment) @comment

;; Strings -> green
(string_literal) @string
(system_lib_string) @string
(wide_string_literal) @string

;; Char literals -> brightgreen (@string.special)
(char_literal) @string.special
(wide_character_literal) @string.special

;; Escape sequences -> brightgreen
(escape_sequence) @string.special

;; Integer literals
(integer_literal) @string.special

;; Brackets -> brightcyan (@delimiter)
[
  "{"
  "}"
  "("
  ")"
  "["
  "]"
] @delimiter

;; Punctuation -> brightcyan (@delimiter)
[
  ","
  ":"
  "<"
  ">"
] @delimiter

;; Semicolons -> brightmagenta (@delimiter.special)
";" @delimiter.special
