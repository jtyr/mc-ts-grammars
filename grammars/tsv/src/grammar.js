/**
 * @file TSV grammar for tree-sitter
 * @author Amaan Qureshi <amaanq12@gmail.com>
 * @license MIT
 */

const defineGrammar = require('./_parent/common/define-grammar');

module.exports = defineGrammar('tsv', '\t');
