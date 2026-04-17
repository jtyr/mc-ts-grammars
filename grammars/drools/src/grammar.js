/**
 * @file Drools grammar for tree-sitter
 * @author Pavlos Smith <paulsmith4561@proton.me>
 * @license AGPLv3
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

export default grammar({
  name: "drools",

  extras: $ => [
    /\s/,
    $.comment
  ],

  word: $ => $.identifier,

  conflicts: $ => [
    [$.primary_expression, $.qualified_name],
    [$.primary_expression, $.qualified_type],
    [$.lhs_unary],
    [$.lhs_pattern_bind],
    [$.annotation],
    [$.attributes],
    [$.attribute],
    [$.lhs_expression, $.lhs_unary],
    [$.nested_constraint, $.primary_expression, $.qualified_name],
    [$.lhs_expression, $.lhs_and_def],
    [$.nested_constraint, $.qualified_name],
    [$.lhs_accumulate],
    [$.method_call, $.field_access],
    [$.lhs_group_by],
    [$.from_accumulate],
    [$.primary_expression, $.annotation_element_value_pair, $.qualified_name],
  ],

  rules: {
    // ============================================================
    // TOP LEVEL
    // ============================================================
    
    source_file: $ => seq(
      optional($.package_decl),
      optional($.unit_decl),
      repeat($._statement)
    ),

    _statement: $ => choice(
      $.import_decl,
      $.global_decl,
      $.declare_decl,
      $.rule_decl,
      $.function_decl,
      $.query_decl,
      $.attributes
    ),

    // ============================================================
    // DECLARATIONS
    // ============================================================

    // package com.example.rules;
    package_decl: $ => seq(
      "package",
      $.qualified_name,
      optional(";")
    ),

    // unit com.example.MyUnit;
    unit_decl: $ => seq(
      "unit",
      $.qualified_name,
      optional(";")
    ),

    // import com.example.Foo
    // import static com.example.Utils.*
    // import function com.example.Utils.myFunction
    // import accumulate com.example.MyAccumulator myAcc
    import_decl: $ => seq(
      "import",
      optional(choice("static", "function")),
      $.import_path,
      optional(";")
    ),

    import_path: $ => prec.left(seq(
      $.identifier,
      repeat(seq(".", $.identifier)),
      optional(seq(".", "*"))
    )),

    // global com.example.Type variableName
    global_decl: $ => seq(
      "global",
      $.type,
      $.identifier,
      optional(";")
    ),

    // ============================================================
    // DECLARE
    // ============================================================

    declare_decl: $ => seq(
      "declare",
      choice(
        $.type_declaration,
        $.entry_point_declaration,
        $.window_declaration,
        $.enum_declaration
      )
    ),

    // declare [trait] [type] MyType extends SuperType
    //   field1 : String
    //   field2 : int = 42
    // end
    type_declaration: $ => seq(
      optional("trait"),
      optional("type"),
      field("name", $.qualified_name),
      optional(seq(
        "extends",
        commaSep1($.qualified_name)
      )),
      repeat($.annotation),
      repeat($.field_decl),
      "end"
    ),

    field_decl: $ => seq(
      field("name", $.identifier),
      ":",
      $.type,
      optional(seq("=", field("init", $.expression))),
      repeat($.annotation),
      optional(";")
    ),

    entry_point_declaration: $ => seq(
      "entry-point",
      $.string_literal,
      repeat($.annotation),
      "end"
    ),

    window_declaration: $ => seq(
      "window",
      $.identifier,
      repeat($.annotation),
      $.lhs_pattern_bind,
      "end"
    ),

    enum_declaration: $ => seq(
      "enum",
      $.qualified_name,
      repeat($.annotation),
      commaSep1($.enumerative),
      ";",
      repeat($.field_decl),
      "end"
    ),

    enumerative: $ => seq(
      $.identifier,
      optional(seq(
        "(",
        commaSep($.expression),
        ")"
      ))
    ),

    // ============================================================
    // RULE
    // ============================================================

    // rule "My Rule"
    //   salience 10
    // when
    //   $p : Person(age >= 18)
    // then
    //   System.out.println("Adult");
    // end
    rule_decl: $ => seq(
      repeat($.annotation),
      "rule",
      field("name", choice($.string_literal, $.identifier)),
      optional(seq("extends", $.string_literal)),
      repeat($.annotation),
      optional($.attributes),
      optional($.lhs),
      $.rhs,
      "end"
    ),

    // ============================================================
    // QUERY
    // ============================================================

    // query "Find Adults" ($minAge : int)
    //   Person(age >= $minAge)
    // end
    query_decl: $ => seq(
      "query",
      field("name", choice($.string_literal, $.identifier)),
      optional($.parameters),
      repeat($.annotation),
      repeat($.lhs_expression),
      "end"
    ),

    parameters: $ => seq(
      "(",
      commaSep($.parameter),
      ")"
    ),

    parameter: $ => seq(
      optional($.type),
      $.identifier
    ),

    // ============================================================
    // FUNCTION
    // ============================================================

    // function void myFunction(String arg) {
    //   System.out.println(arg);
    // }
    function_decl: $ => seq(
      "function",
      optional($.type),
      $.identifier,
      $.formal_parameters,
      $.block
    ),

    formal_parameters: $ => seq(
      "(",
      commaSep(seq(
        optional($.type),
        $.identifier
      )),
      ")"
    ),

    // ============================================================
    // LHS (Left Hand Side - WHEN clause)
    // ============================================================

    lhs: $ => seq(
      "when",
      repeat($.lhs_expression)
    ),

    lhs_expression: $ => choice(
      seq("(", $.lhs_expression, ")"),
      $.lhs_or,
      $.lhs_and,
      $.lhs_unary
    ),

    lhs_or: $ => prec.left(1, seq(
      choice(
        seq("or", repeat1($.lhs_expression)),
        seq($.lhs_expression, repeat1(seq("or", $.lhs_expression)))
      )
    )),

    lhs_and: $ => prec.left(2, seq(
        $.lhs_expression, repeat1(seq("and", $.lhs_expression))
    )),

    lhs_unary: $ => seq(
      choice(
        seq($.lhs_exists, optional($.named_consequence_invocation)),
        seq($.lhs_not, optional($.named_consequence_invocation)),
        seq($.lhs_eval, repeat($.consequence_invocation)),
        $.lhs_forall,
        $.lhs_accumulate,
        $.lhs_group_by,
        seq("(", $.lhs_expression, ")", optional($.named_consequence_invocation)),
        $.conditional_branch,
        seq($.lhs_pattern_bind, repeat($.consequence_invocation))
      ),
      optional(";")
    ),

    // exists Pattern
    lhs_exists: $ => seq(
      "exists",
      choice(
        seq("(", $.lhs_expression, ")"),
        $.lhs_pattern_bind
      )
    ),

    // not Pattern
    lhs_not: $ => seq(
      "not",
      choice(
        seq("(", $.lhs_expression, ")"),
        $.lhs_pattern_bind
      )
    ),

    // eval(expression)
    lhs_eval: $ => seq(
      "eval",
      "(",
      $.expression,
      ")"
    ),

    // forall(pattern1, pattern2, ...)
    lhs_forall: $ => seq(
      "forall",
      "(",
      repeat1($.lhs_pattern_bind),
      ")"
    ),

    // accumulate(pattern; $result: sum($value))
    lhs_accumulate: $ => seq(
      choice("accumulate", "acc"),
      "(",
      $.lhs_and_def,
      choice(",", ";"),
      commaSep1($.accumulate_function),
      optional(seq(";", $.constraints)),
      ")",
      optional(";")
    ),

    // groupby(pattern; $key: field; $result: sum($value))
    lhs_group_by: $ => seq(
      "groupby",
      "(",
      $.lhs_and_def,
      choice(",", ";"),
      $.group_by_key_binding,
      ";",
      commaSep1($.accumulate_function),
      optional(seq(";", $.constraints)),
      ")",
      optional(";")
    ),

    group_by_key_binding: $ => seq(
      optional($.label),
      $.expression
    ),

    lhs_and_def: $ => choice(
      seq("(", $.lhs_and_def, ")"),
      seq($.lhs_unary, repeat(seq("and", $.lhs_unary))),
      seq("(", "and", repeat1($.lhs_unary), ")")
    ),

    accumulate_function: $ => seq(
      optional(choice($.label, $.unif)),
      $.identifier,
      "(",
      commaSep($.expression),
      ")"
    ),

    // ============================================================
    // PATTERNS
    // ============================================================

    // $p : Person(age >= 18, name == "John")
    lhs_pattern_bind: $ => seq(
      optional(choice($.label, $.unif)),
      choice(
        seq("(", $.lhs_pattern, repeat(seq("or", $.lhs_pattern)), ")"),
        $.lhs_pattern
      )
    ),

    // Person(age >= 18) from entry-point "my-stream"
    lhs_pattern: $ => seq(
      optional("?"),
      field("type", $.qualified_name),
      "(",
      optional($.positional_constraints),
      optional($.constraints),
      ")",
      repeat($.annotation),
      optional(seq("over", $.pattern_filter)),
      optional(seq("from", $.pattern_source))
    ),

    positional_constraints: $ => seq(
      commaSep1($.constraint),
      ";"
    ),

    constraints: $ => commaSep1($.constraint),

    constraint: $ => choice(
      $.constraint_binding,
      $.constraint_unification,
      $.nested_constraint,
      $.expression
    ),

    constraint_binding: $ => seq($.label, $.identifier),

    constraint_unification: $ => seq($.unif, $.identifier),
    
    // address.city == "Boston"
    nested_constraint: $ => seq(
      repeat(seq($.identifier, choice(".", "?.", "#"))),
      $.identifier,
      choice(".", "?."),
      "(",
      $.constraints,
      ")"
    ),

    // ============================================================
    // PATTERN SOURCE
    // ============================================================

    pattern_source: $ => choice(
      $.from_accumulate,
      $.from_collect,
      $.from_entry_point,
      $.from_window,
      $.expression
    ),

    // from accumulate(pattern; init(...) action(...) result(...))
    from_accumulate: $ => seq(
      choice("accumulate", "acc"),
      "(",
      $.lhs_and_def,
      choice(",", ";"),
      choice(
        seq(
          "init", "(", optional($.block_statements), ")", optional(","),
          "action", "(", optional($.block_statements), ")", optional(","),
          optional(seq("reverse", "(", optional($.block_statements), ")", optional(","))),
          "result", "(", $.expression, ")"
        ),
        $.accumulate_function
      ),
      ")",
      optional(";")
    ),

    block_statements: $ => repeat1(choice(
      $.variable_declaration,
      $.expression_statement
    )),

    // from collect(pattern)
    from_collect: $ => seq(
      "collect",
      "(",
      $.lhs_pattern_bind,
      ")"
    ),

    // from entry-point "my-stream"
    from_entry_point: $ => seq(
      "entry-point",
      $.string_literal
    ),

    // from window myWindow
    from_window: $ => seq(
      "window",
      $.identifier
    ),

    pattern_filter: $ => seq(
      "window",
      ":",
      $.identifier,
      "(",
      commaSep($.expression),
      ")"
    ),

    // ============================================================
    // NAMED CONSEQUENCES
    // ============================================================

    consequence_invocation: $ => choice(
      $.conditional_branch,
      $.named_consequence_invocation
    ),

    // if(condition) do[consequence1] else do[consequence2]
    conditional_branch: $ => seq(
      "if",
      "(",
      $.expression,
      ")",
      choice($.named_consequence_invocation, $.breaking_named_consequence_invocation),
      optional(seq(
        "else",
        choice($.named_consequence_invocation, $.breaking_named_consequence_invocation, $.conditional_branch)
      ))
    ),

    // do[myConsequence]
    named_consequence_invocation: $ => seq(
      "do",
      "[",
      $.identifier,
      "]"
    ),

    // break[myConsequence]
    breaking_named_consequence_invocation: $ => seq(
      "break",
      "[",
      $.identifier,
      "]"
    ),

    // ============================================================
    // RHS (Right Hand Side - THEN clause)
    // ============================================================

    rhs: $ => seq(
      "then",
      optional($.consequence_body),
      repeat($.named_consequence)
    ),

    // The RHS body is essentially arbitrary Java code
    consequence_body: $ => repeat1(choice(
      $.block,
      $.variable_declaration,
      $.drools_insert,
      $.drools_insertLogical,
      $.drools_update,
      $.drools_modify,
      $.drools_delete,
      $.if_statement,
      $.for_statement,
      $.while_statement,
      $.return_statement,
      $.expression_statement,
    )),

    // Drools-specific RHS actions
    
    drools_insert: $ => seq(
      "insert",
      "(",
      $.expression,
      ")",
      optional(";")
    ),

    drools_insertLogical: $ => seq(
      "insertLogical",
      "(",
      $.expression,
      ")",
      optional(";")
    ),

    drools_update: $ => seq(
      "update",
      "(",
      $.expression,
      optional(seq(",", $.expression)),
      optional(seq(",", $.expression)),
      ")",
      optional(";")
    ),

    drools_modify: $ => seq(
      "modify",
      "(",
      $.expression,
      ")",
      $.modify_block,
      optional(";")
    ),

    modify_block: $ => seq(
      "{",
      optional(commaSep1($.method_call)),
      "}"
    ),

    drools_delete: $ => seq(
      choice("delete", "retract"),
      "(",
      $.expression,
      ")",
      optional(";")
    ),

    named_consequence: $ => seq(
      "then",
      "[",
      $.identifier,
      "]",
      optional($.consequence_body)
    ),

    // ============================================================
    // ATTRIBUTES
    // ============================================================

    attributes: $ => seq(
      optional(seq("attributes", optional(":"))),
      $.attribute,
      repeat(seq(optional(","), $.attribute))
    ),

    attribute: $ => choice(
      // Expression attributes: salience, enabled
      seq(
        field("name", "salience"),
        field("value", choice(
          seq("(", $.number, ")"),
          $.number
        ))
      ),
      // Boolean attributes: no-loop, auto-focus, etc.
      seq(
        field("name", choice(
          "enabled",
          "no-loop",
          "auto-focus",
          "lock-on-active",
          "refract",
          "direct"
        )),
        optional(field("value", $.boolean_literal))
      ),
      // String attributes
      seq(
        field("name", choice(
          "activation-group",
          "ruleflow-group",
          "date-effective",
          "date-expires",
          "dialect"
        )),
        field("value", $.string_literal)
      ),
      // String list attributes
      seq(
        field("name", "calendars"),
        field("value", commaSep1($.string_literal)),
      ),
      // Int or chunk attributes
      seq(
        field("name", choice("timer", "duration")),
        field("value", choice(
          $.number,
          seq("(", $.chunk, ")")
        ))
      )
    ),

    // ============================================================
    // EXPRESSIONS
    // ============================================================

    expression: $ => choice(
      $.primary_expression,
      $.binary_expression,
      $.unary_expression,
      $.ternary_expression,
      $.cast_expression,
      $.assignment_expression
    ),

    primary_expression: $ => choice(
      $.identifier,
      $.qualified_name,
      $.literal,
      $.parenthesized_expression,
      $.method_call,
      $.field_access,
      $.array_access,
      $.array_literal,
      $.object_creation,
      "this",
      "super"
    ),

    parenthesized_expression: $ => seq("(", $.expression, ")"),

    binary_expression: $ => choice(
      // Multiplicative
      prec.left(11, seq($.expression, choice("*", "/", "%"), $.expression)),
      // Additive
      prec.left(10, seq($.expression, choice("+", "-"), $.expression)),
      // Shift
      prec.left(9, seq($.expression, choice("<<", ">>", ">>>"), $.expression)),
      // Relational
      prec.left(8, seq($.expression, choice("<", ">", "<=", ">=", "instanceof"), $.expression)),
      // Drools-specific relational
      prec.left(8, seq($.expression, optional("not"), choice(
        "matches",
        "memberOf",
        "contains",
        "excludes",
        "soundslike",
        "str"
      ), $.expression)),
      // Temporal operators with optional time range
      prec.left(8, seq(
        $.expression,
        choice(
          "after",
          "before",
          "coincides",
          "during",
          "includes",
          "finishes",
          "finishedby",
          "meets",
          "metby",
          "overlaps",
          "overlappedby",
          "starts",
          "startedby"
        ),
        optional(seq(
          "[",
          $.expression,
          optional(seq(",", $.expression)),
          "]"
        )),
        $.expression
      )),
      // Equality
      prec.left(7, seq($.expression, choice("==", "!="), $.expression)),
      // Bitwise AND
      prec.left(6, seq($.expression, "&", $.expression)),
      // Bitwise XOR
      prec.left(5, seq($.expression, "^", $.expression)),
      // Bitwise OR
      prec.left(4, seq($.expression, "|", $.expression)),
      // Logical AND
      prec.left(3, seq($.expression, "&&", $.expression)),
      // Logical OR
      prec.left(2, seq($.expression, "||", $.expression)),
    ),

    unary_expression: $ => choice(
      prec.right(12, seq(choice("+", "-", "~", "!"), $.expression)),
      prec.right(12, seq(choice("++", "--"), $.expression)),
      prec.right(12, seq($.expression, choice("++", "--")))
    ),

    ternary_expression: $ => prec.right(1, seq(
      $.expression,
      "?",
      $.expression,
      ":",
      $.expression
    )),

    cast_expression: $ => prec.right(12, seq(
      "(",
      $.type,
      ")",
      $.expression
    )),

    assignment_expression: $ => prec.right(1, seq(
      $.expression,
      choice("=", "+=", "-=", "*=", "/=", "&=", "|=", "^=", "%=", "<<=", ">>=", ">>>="),
      $.expression
    )),

    method_call: $ => prec(13, seq(
      optional(seq(
        field("object", $.expression),
        ".",
      )),
      field("method", $.identifier),
      "(",
      commaSep($.expression),
      ")"
    )),

    field_access: $ => prec(13, seq(
      $.expression,
      choice(".", "?."),
      $.identifier
    )),

    array_access: $ => prec(13, seq(
      $.expression,
      "[",
      $.expression,
      "]"
    )),

    array_literal: $ => seq(
      "[",
      commaSep($.expression),
      "]"
    ),

    object_creation: $ => seq(
      "new",
      $.type,
      "(",
      commaSep($.expression),
      ")"
    ),

    expression_statement: $ => seq(
      $.expression,
      ";"
    ),

    // ============================================================
    // BLOCKS AND STATEMENTS
    // ============================================================

    block: $ => seq(
      "{",
      repeat(choice(
        $.expression_statement,
        $.variable_declaration,
        $.if_statement,
        $.for_statement,
        $.while_statement,
        $.return_statement,
        $.block
      )),
      "}"
    ),

    variable_declaration: $ => seq(
      $.type,
      commaSep1(seq(
        $.identifier,
        optional(seq("=", $.expression))
      )),
      ";"
    ),

    if_statement: $ => seq(
      "if",
      "(",
      $.expression,
      ")",
      choice($.block, $.expression_statement),
      optional(seq("else", choice($.block, $.expression_statement, $.if_statement)))
    ),

    for_statement: $ => seq(
      "for",
      "(",
      choice(
        seq(
          optional($.for_init),
          ";",
          optional($.expression),
          ";",
          optional($.expression)
        ),
        seq($.type, $.identifier, ":", $.expression)
      ),
      ")",
      choice($.block, $.expression_statement)
    ),

    for_init: $ => seq(
      $.type,
      commaSep1(seq(
        $.identifier,
        optional(seq("=", $.expression))
      ))
    ),

    while_statement: $ => seq(
      "while",
      "(",
      $.expression,
      ")",
      choice($.block, $.expression_statement)
    ),

    return_statement: $ => seq(
      "return",
      optional($.expression),
      ";"
    ),

    // ============================================================
    // TYPES
    // ============================================================

    type: $ => choice(
      $.primitive_type,
      $.qualified_type
    ),

    primitive_type: $ => choice(
      "byte",
      "short",
      "int",
      "long",
      "float",
      "double",
      "boolean",
      "char",
      "void"
    ),

    qualified_type: $ => seq(
      $.qualified_name,
      optional($.type_arguments),
      repeat(seq("[", "]"))
    ),

    type_arguments: $ => seq(
      "<",
      commaSep1($.type_argument),
      ">"
    ),

    type_argument: $ => choice(
      $.type,
      seq("?", optional(choice("extends", "super")), optional($.type))
    ),

    // ============================================================
    // ANNOTATIONS
    // ============================================================

    annotation: $ => seq(
      "@",
      $.qualified_name,
      optional($.annotation_args)
    ),

    annotation_args: $ => seq(
      "(",
      optional(choice(
        $.annotation_element_value_pairs,
        $.annotation_value
      )),
      ")"
    ),

    annotation_element_value_pairs: $ => commaSep1($.annotation_element_value_pair),

    annotation_element_value_pair: $ => seq(
      field("key", $.identifier),
      "=",
      field("value", $.annotation_value)
    ),

    annotation_value: $ => choice(
      $.annotation,          // nested annotation
      $.annotation_array,    // array of values
      $.expression           // expression (string, number, identifier, etc.)
    ),

    annotation_array: $ => seq(
      "{",
      optional(commaSep1($.annotation_value)),
      "}"
    ),

    // ============================================================
    // UTILITIES
    // ============================================================

    qualified_name: $ => prec.left(seq(
      $.identifier,
      repeat(seq(".", $.identifier))
    )),

    label: $ => seq($.identifier, ":"),

    unif: $ => seq($.identifier, ":="),

    chunk: $ => /[^)]+/,

    // ============================================================
    // LITERALS
    // ============================================================

    literal: $ => choice(
      $.string_literal,
      $.number,
      $.boolean_literal,
      $.null_literal,
      $.time_interval
    ),

    string_literal: $ => choice(
      /"([^"\\]|\\.)*"/,
      /'([^'\\]|\\.)*'/
    ),

    number: $ => choice(
      /\d+/,                        // Integer
      /\d+\.\d+/,                   // Float
      /0[xX][0-9a-fA-F]+/,          // Hex
      /\d+[lLfFdD]/,                // Long/Float/Double suffix
      /\d+\.\d+[fFdD]/,             // Float/Double with decimal
      /\d+[Bb]/,                    // BigDecimal
      /\d+\.\d+[Bb]/                // BigDecimal with decimal
    ),

    boolean_literal: $ => choice("true", "false"),

    null_literal: $ => "null",

    // Time intervals: 1d2h30m45s
    time_interval: $ => /\d+[dhms]+(\d+[dhms]+)*/,

    identifier: _ => /[$a-zA-Z_][$a-zA-Z0-9_]*/,

    comment: _ => token(choice(
      seq("//", /.*/),
      seq("/*", /[^*]*\*+([^/*][^*]*\*+)*/, "/")
    )),
  }
});

// ============================================================
// HELPER FUNCTIONS
// ============================================================

function commaSep1(rule) {
  return seq(rule, repeat(seq(",", rule)));
}

function commaSep(rule) {
  return optional(commaSep1(rule));
}
