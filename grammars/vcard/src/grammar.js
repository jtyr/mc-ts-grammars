/**
 * @file vCard parser
 * @author Titouan Real <titouan.real@gmail.com>
 * @license APACHE-2.0 OR MIT
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

module.exports = grammar({
  name: "vcard",

  extras: ($) => ["\r\n", "\n"],

  rules: {
    source_file: ($) =>
      seq(repeat(seq($.property, choice("\r\n", "\n"))), optional($.property)),

    _line_continuation: ($) => choice("\r\n ", "\n ", "\r\n\t", "\n\t"),

    property: ($) =>
      seq(
        optional(seq($.group, ".")),
        $.property_name,
        repeat(seq(";", $.parameter)),
        ":",
        seq($.property_value, repeat(seq(",", $.property_value))),
      ),

    group: ($) => repeat1(choice(/[A-Za-z0-9-]/, $._line_continuation)),

    property_name: ($) => repeat1(choice(/[A-Za-z0-9-]/, $._line_continuation)),

    property_value: ($) => repeat1(choice(/[^,\r\n]/, $._line_continuation)),

    parameter: ($) =>
      seq(
        $.parameter_name,
        "=",
        $.parameter_value,
        repeat(seq(",", $.parameter_value)),
      ),

    parameter_name: ($) =>
      repeat1(choice(/[A-Za-z0-9-]/, $._line_continuation)),

    parameter_value: ($) =>
      choice(
        seq('"', repeat1(choice(/[^\x00-\x1F]/, $._line_continuation)), '"'),
        repeat1(choice(/[^";:,\x00-\x1F]/, $._line_continuation)),
      ),
  },
});
