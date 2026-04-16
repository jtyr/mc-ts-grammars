#include <tree_sitter/parser.h>

#include <stdbool.h>
#include <string.h>
#include <stdlib.h>
#include <wctype.h>

enum TokenType {
    DOLLAR_QUOTED_STRING_TAG,
    DOLLAR_QUOTED_STRING_CONTENT,
    DOLLAR_QUOTED_STRING_END_TAG,
};

typedef struct {
    char dollar_quoted_string_tag[TREE_SITTER_SERIALIZATION_BUFFER_SIZE];
    unsigned tag_length;
    char current_leading_word[TREE_SITTER_SERIALIZATION_BUFFER_SIZE];
    bool dollar_quoted_string_started;
} Scanner;

static void skip(TSLexer *lexer)
{
    lexer->advance(lexer, true);
}

static void advance(TSLexer *lexer)
{
    lexer->advance(lexer, false);
}

static unsigned serialize(Scanner *scanner, char *buffer)
{
    if (scanner->tag_length + 1 >= TREE_SITTER_SERIALIZATION_BUFFER_SIZE)
        return 0;

    buffer[0] = scanner->dollar_quoted_string_started;
    memcpy(&buffer[1], scanner->dollar_quoted_string_tag, scanner->tag_length);

    return scanner->tag_length + 1;
}

static void deserialize(Scanner *scanner, const char *buffer, unsigned length)
{
    if (length == 0)
    {
        scanner->dollar_quoted_string_started = false;
        scanner->tag_length = 0;
    }
    else
    {
        scanner->dollar_quoted_string_started = buffer[0];
        scanner->tag_length = length - 1;
        memcpy(scanner->dollar_quoted_string_tag, &buffer[1], scanner->tag_length);
    }
}

static bool scan_dollar_quoted_string_content(Scanner *scanner, TSLexer *lexer)
{
    unsigned long pos = 0;

    lexer->result_symbol = DOLLAR_QUOTED_STRING_CONTENT;
    lexer->mark_end(lexer);

    for (;;)
    {
        if (lexer->lookahead == '\0')
            return false;

        if (lexer->lookahead == (unsigned) scanner->dollar_quoted_string_tag[pos])
        {
            if (pos == scanner->tag_length - 1)
                return true;

            if (pos == 0)
            {
                lexer->result_symbol = DOLLAR_QUOTED_STRING_CONTENT;
                lexer->mark_end(lexer);
            }

            pos++;
            advance(lexer);
        }
        else if (pos != 0)
        {
            pos = 0;
        }
        else
        {
            advance(lexer);
        }
    }
}

static bool scan_dollar_quoted_string_tag(Scanner *scanner, TSLexer *lexer)
{
    while (iswspace(lexer->lookahead))
        skip(lexer);

    scanner->tag_length = 0;

    if (lexer->lookahead == '$')
    {
        scanner->dollar_quoted_string_tag[scanner->tag_length++] = lexer->lookahead;
        advance(lexer);
    }
    else
    {
        return false;
    }

    while (iswalpha(lexer->lookahead))
    {
        if (scanner->tag_length >= TREE_SITTER_SERIALIZATION_BUFFER_SIZE - 2)
            return false;

        scanner->dollar_quoted_string_tag[scanner->tag_length++] = lexer->lookahead;
        advance(lexer);
    }

    if (lexer->lookahead == '$')
    {
        scanner->dollar_quoted_string_tag[scanner->tag_length++] = lexer->lookahead;
        advance(lexer);
        scanner->dollar_quoted_string_started = true;
        return true;
    }

    return false;
}

static bool scan_dollar_quoted_string_end_tag(Scanner *scanner, TSLexer *lexer)
{
    unsigned length = 0;

    while (lexer->lookahead != '\0' && length < scanner->tag_length)
    {
        scanner->current_leading_word[length++] = lexer->lookahead;
        advance(lexer);
    }

    if (length != scanner->tag_length)
        return false;

    return memcmp(scanner->current_leading_word, scanner->dollar_quoted_string_tag, length) == 0;
}

static bool scan(Scanner *scanner, TSLexer *lexer, const bool *valid_symbols)
{
    if (valid_symbols[DOLLAR_QUOTED_STRING_TAG] && !scanner->dollar_quoted_string_started)
        return scan_dollar_quoted_string_tag(scanner, lexer);

    if (valid_symbols[DOLLAR_QUOTED_STRING_CONTENT] && scanner->dollar_quoted_string_started)
        return scan_dollar_quoted_string_content(scanner, lexer);

    if (valid_symbols[DOLLAR_QUOTED_STRING_END_TAG] && scanner->dollar_quoted_string_started)
    {
        if (scan_dollar_quoted_string_end_tag(scanner, lexer))
        {
            scanner->dollar_quoted_string_started = false;
            lexer->result_symbol = DOLLAR_QUOTED_STRING_END_TAG;
            return true;
        }
    }

    return false;
}

void *tree_sitter_sql_external_scanner_create(void)
{
    Scanner *scanner = calloc(1, sizeof(Scanner));
    return scanner;
}

bool tree_sitter_sql_external_scanner_scan(void *payload, TSLexer *lexer, const bool *valid_symbols)
{
    Scanner *scanner = (Scanner *) payload;
    return scan(scanner, lexer, valid_symbols);
}

unsigned tree_sitter_sql_external_scanner_serialize(void *payload, char *state)
{
    Scanner *scanner = (Scanner *) payload;
    return serialize(scanner, state);
}

void tree_sitter_sql_external_scanner_deserialize(void *payload, const char *state, unsigned length)
{
    Scanner *scanner = (Scanner *) payload;
    deserialize(scanner, state, length);
}

void tree_sitter_sql_external_scanner_destroy(void *payload)
{
    free(payload);
}
