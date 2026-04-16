#include <stdbool.h>
#include <stdint.h>
#include <tree_sitter/parser.h>
#include <stdio.h>
#include <signal.h>


enum TokenType {
  UNDELIMITED_CODE_BLOCK,
  ERROR_SENTINEL
};

void *tree_sitter_bison_external_scanner_create() {
    return NULL;
}

void tree_sitter_bison_external_scanner_destroy(void* payload) {
  (void) payload; // Suppress unused argument warning
}

unsigned tree_sitter_bison_external_scanner_serialize(
  void *payload,
  char *buffer
) {
  (void) payload;
  (void) buffer;
  return 0;
}

void tree_sitter_bison_external_scanner_deserialize(
  void *payload,
  const char *buffer,
  unsigned length
) {
  (void) payload;
  (void) buffer;
  (void) length;
}

/**
   Advance the lexer to the end of the string. It takes in account backslashes.
   When calling, the lookahead must be a quote, and when it ends the lookahead will be
   the caracter just after the closing quote.
 */
void eat_entire_string(TSLexer* lexer, int32_t quote_symbol) {
  lexer->advance(lexer, false);

  bool backslash_active = false;

  while (!lexer->eof(lexer)) {
	if (!backslash_active && lexer->lookahead == quote_symbol) {
	  lexer->advance(lexer, false);
	  break;
	}
	if (!backslash_active && lexer->lookahead == '\\') {
	  backslash_active = true;
	} else {
	  backslash_active = false;
	}
	lexer->advance(lexer, false);
  }
}

void eat_entire_multiline_comment(TSLexer* lexer) {

  int32_t previous_char = 0;
  lexer->advance(lexer, false);

  while (!lexer->eof(lexer)) {
	if (previous_char == '*' && lexer->lookahead == '/') {
	  lexer->advance(lexer, false);
	  break;
	}
	previous_char = lexer->lookahead;
	lexer->advance(lexer, false);
  }
}

void eat_entire_simple_comment(TSLexer* lexer) {

  lexer->advance(lexer, false);

  while (!lexer->eof(lexer)) {
	if (lexer->lookahead == '\n') {
	  lexer->advance(lexer, false);
	  break;
	}
	lexer->advance(lexer, false);
  }
}

void eat_entire_comment(TSLexer* lexer) {
  if (!lexer->eof(lexer)) {
	lexer->advance(lexer, false);
	if (lexer->lookahead == '*') {
	  eat_entire_multiline_comment(lexer);
	}
	else {
	  if (lexer->lookahead == '/') {
		eat_entire_simple_comment(lexer);
	  }
	}
  }
}

void error_recovery(TSLexer* lexer) {
  while (!lexer->eof(lexer)) {
	switch (lexer->lookahead) {
	case '\"':
	  eat_entire_string(lexer, '\"');
	  continue;
	case '\'':
	  eat_entire_string(lexer, '\'');
	  continue;
	case '%':
	case ';':
	  lexer->mark_end(lexer);
	  return;
	}
	lexer->advance(lexer, false);
  }
  lexer->mark_end(lexer);
}

bool tree_sitter_bison_external_scanner_scan(
  void *payload,
  TSLexer *lexer,
  const bool *valid_symbols) {

  (void) payload;

  if (valid_symbols[ERROR_SENTINEL]) {
	error_recovery(lexer);
	lexer->result_symbol = ERROR_SENTINEL;
	return true;
  }

  int scope_level = 0;
  uint32_t previous_char = 0;

  lexer->result_symbol = UNDELIMITED_CODE_BLOCK;

  while (!lexer->eof(lexer) && !(scope_level == 0 && lexer->lookahead == '}')) {

	switch (lexer->lookahead) {
	case '\"':
	  eat_entire_string(lexer, '\"');
	  continue;
	  break;
	case '\'':
	  eat_entire_string(lexer, '\'');
	  continue;
	  break;
	case '/':
	  eat_entire_comment(lexer);
	  break;
	case '{':
	  scope_level++;
	  break;
	case '}':
	  scope_level--;
	  break;
	case '%': // Opening digraph, supported by bison, "<%" is equivalent to "{"
	  if (previous_char == '<')
		scope_level++;
	  break;
	case'>': // Closing digraph, supported by bison, "%>" equivalent to "}"
	  if (previous_char == '%')
		scope_level--;
	  break;
	}

	lexer->advance(lexer, false);
  }

  previous_char = lexer->lookahead;
  lexer->mark_end(lexer);

  return true;
}
