((identifier (NAME) @type) 
 (#match? @type "^[A-Z]"))
(typeDef (NAME) @type)
(traitDef (NAME) @type) 

(param (pattern (NAME) @variable.parameter))

((param (pattern (NAME) @variable.builtin) 
 (#match? @variable.builtin "self")))
((identifier (NAME) @variable.builtin) 
 (#match? @variable.builtin "self"))

(fnDef (NAME) @function)

(fieldDef (NAME) @property)
(fieldPattern (NAME) @property)
(arg (NAME) @property)

(addOp) @operator
(subOp) @operator
(multOp) @operator
(divOp) @operator
(expOp) @operator
(modOp) @operator
(eqOp) @operator
(neOp) @operator
(geOp) @operator
(leOp) @operator
(gtOp) @operator
(ltOp) @operator
(andOp) @operator
(orOp) @operator
(unwrapOp) @operator
(bindOp) @operator

(USE_KEYWORD) @keyword
(TYPE_KEYWORD) @keyword
(TRAIT_KEYWORD) @keyword
(IF_KEYWORD) @keyword
(ELSE_KEYWORD) @keyword
(RETURN_KEYWORD) @keyword
(BREAK_KEYWORD) @keyword
(IMPL_KEYWORD) @keyword
(LET_KEYWORD) @keyword
(FN_KEYWORD) @keyword
(WHILE_KEYWORD) @keyword
(FOR_KEYWORD) @keyword
(IN_KEYWORD) @keyword
(MATCH_KEYWORD) @keyword
(PUB_KEYWORD) @keyword

(O_PAREN) @punctuation.delimiter
(C_PAREN) @punctuation.delimiter
(O_BRACKET) @punctuation.delimiter
(C_BRACKET) @punctuation.delimiter
(O_BRACE) @punctuation.delimiter
(C_BRACE) @punctuation.delimiter
(COLON) @punctuation.delimiter
(PERIOD) @punctuation.delimiter
(COMMA) @punctuation.delimiter

(identifier (COLON) @punctuation.delimiter)

(typeArgs
  (O_ANGLE) @punctuation.bracket
  (C_ANGLE) @punctuation.bracket)

(COMMENT) @comment

(INT) @number
(FLOAT) @number
(STRING) @string
(stringPart ((O_BRACE) @string))
(stringPart ((C_BRACE) @string))
(string ((D_QUOTE) @string))
(CHAR) @string
