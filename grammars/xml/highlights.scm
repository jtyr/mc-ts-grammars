;; Tree-sitter highlight queries for XML
;; Colors aligned with MC's default xml.syntax

;; Tag names -> white (tag.special)
(tag_name) @tag.special
(erroneous_end_tag_name) @tag.special

;; Attribute names -> brightcyan (delimiter)
(attribute_name) @delimiter

;; Attribute values -> lightgray (variable)
(attribute_value) @variable
(quoted_attribute_value) @variable

;; Comments -> brightgreen (comment.special)
(comment) @comment.special

;; <?xml ...?> prolog -> keyword (yellow)
(prolog) @keyword

;; <!DOCTYPE> -> keyword (yellow)
(doctype) @keyword
"doctype" @keyword

;; CDATA sections -> lightgray (constant)
(cdata_start) @constant
(cdata_end) @constant
(cdata_text) @variable

;; Entity references -> white (tag.special)
(entity) @tag.special

;; Text content -> lightgray (variable)
(text) @variable

;; = -> keyword (yellow)
"=" @keyword

;; Angle brackets / delimiters -> white (tag.special)
[
  "<"
  ">"
  "</"
  "/>"
  "<?"
  "<!"
] @tag.special
