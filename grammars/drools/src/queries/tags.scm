; ============================================================
; TAGS QUERY
; Used by editors (Helix :syntax-symbol-picker,
; tree-sitter `tags`) for code navigation and symbol outline.
; Captures: @name + @definition.<kind> for definitions,
;          @name + @reference for references.
; ============================================================

; ============================================================
; RULES
; ============================================================

(rule_decl
  name: (string_literal) @name
  (#strip! @name)) @definition.function

(rule_decl
  name: (identifier) @name) @definition.function

; ============================================================
; QUERIES
; ============================================================

(query_decl
  name: (string_literal) @name
  (#strip! @name)) @definition.function

(query_decl
  name: (identifier) @name) @definition.function

; ============================================================
; FUNCTIONS
; ============================================================

(function_decl
  (identifier) @name) @definition.function

; ============================================================
; DECLARE BLOCKS
; ============================================================

(type_declaration
  name: (qualified_name) @name) @definition.type

(enum_declaration
  (qualified_name) @name) @definition.enum

(field_decl
  name: (identifier) @name) @definition.field

(entry_point_declaration
  (string_literal) @name
  (#strip! @name)) @definition.section

(window_declaration
  (identifier) @name) @definition.section

; ============================================================
; GLOBALS
; ============================================================

(global_decl
  (identifier) @name) @definition.field

; ============================================================
; NAMED CONSEQUENCES
; ============================================================

(named_consequence
  (identifier) @name) @definition.section

; ============================================================
; REFERENCES
; ============================================================

; Method / function calls
(method_call
  method: (identifier) @name) @reference

; Pattern types referenced in LHS patterns
(lhs_pattern
  type: (qualified_name) @name) @reference