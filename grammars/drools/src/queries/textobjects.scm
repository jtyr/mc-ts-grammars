; ============================================================
; TEXTOBJECTS QUERY
; Used by Helix for text objects (mi/ma) and navigation
; (goto_next_function / goto_prev_function, etc.).
; ============================================================

; ============================================================
; FUNCTIONS (includes rules, queries and functions)
; ============================================================

(function_decl) @function.around
(function_decl
  (block) @function.inside)

(rule_decl) @function.around
(rule_decl) @function.inside

(query_decl) @function.around
(query_decl) @function.inside

; ============================================================
; CLASSES / TYPES (declare blocks and enums)
; ============================================================

(type_declaration) @class.around
(type_declaration) @class.inside

(enum_declaration) @class.around
(enum_declaration) @class.inside

; ============================================================
; PARAMETERS
; ============================================================

(formal_parameters) @parameter.inside
(formal_parameters) @parameter.around
(parameters) @parameter.inside
(parameters) @parameter.around

; ============================================================
; COMMENTS
; ============================================================

(comment) @comment.inside
(comment) @comment.around