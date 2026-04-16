XML syntax highlighting: TS vs Legacy comparison report
=======================================================

Sample file: `tests/syntax/samples/xml.xml`
Legacy reference: `misc/syntax/xml.syntax`
TS query: `grammars/xml/highlights.scm` (mc-ts-grammars)
TS colors: `misc/syntax-ts/colors.ini` `[xml]`

Aligned with legacy
-------------------

- Tag names (`catalog`, `book`, `title`, `author`, etc.): `white` via
  `@tag.special` - MATCH Now captured via `tag_name` named node instead
  of the old `Name` node.
- Angle brackets and delimiters (`<`, `>`, `</`, `/>`): `white` via
  `@tag.special` - MATCH
- Attribute equals sign (`=`): `yellow` via `@keyword` - MATCH
- Comments (`<!-- -->`): `brightgreen` via `@comment.special` - MATCH
- `<?xml ?>` prolog: `white` via `@keyword` on `prolog` - MATCH
- Entity references (`&amp;`, `&publisher;`, `&#169;`, `&#x20AC;`):
  `white` via `@tag.special` on `entity` - MATCH
- Self-closing elements (`<empty-element/>`, `<br/>`): `white` tags with
  `white` delimiters - MATCH
- Namespaced tag names (`dc:creator`, `dc:description`): `white` via
  `@tag.special` - MATCH

Intentional improvements over legacy
-------------------------------------

- The TS query underwent a complete node name overhaul to match upstream
  grammar changes:
  - `Name` replaced by `tag_name`.
  - `AttValue` replaced by `attribute_value` and `quoted_attribute_value`.
  - `Comment` replaced by `comment`.
  - `XMLDecl` replaced by `prolog`.
  - `doctypedecl` replaced by `doctype`.
  - `CDSect`/`CDStart`/`CDEnd` replaced by `cdata_start`, `cdata_end`,
    `cdata_text`.
  - `CharRef`/`EntityRef` replaced by `entity`.
  - `CharData` replaced by `text`.
  - `Attribute` name part replaced by `attribute_name`.
- Attribute names (`id`, `currency`, `name`, `enabled`, `href`, `rel`,
  etc.): TS colors these as `yellow` (`@keyword`) for the attribute name
  and `brightcyan` for the value. Legacy colors the attribute name as
  `yellow` and the value as `brightcyan`. This is a MATCH in terms of
  the overall visual result.
- Processing instructions (`<?php ?>`, `<?custom-pi ?>`): TS colors the
  entire PI content as `lightgray` via `@variable`. Legacy colors
  individual words as `white`/`red`. The TS approach is cleaner.

Known shortcomings
------------------

- Attribute names: TS colors attribute names as `brightcyan` via
  `@delimiter` and attribute values as `lightgray` via `@variable`.
  Legacy colors attribute names as `yellow` and values as `brightcyan`.
  The colors are swapped between the two engines. The attribute name and
  value are both colored, just with different color assignments.
- `xmlns=` namespace declaration on the first line after `<catalog`: TS
  colors this as `brightcyan`/`lightgray` like regular attributes. Legacy
  colors it as `brightred` with special namespace handling. This loses
  the visual distinction for namespace declarations.
- `<!DOCTYPE>` internal subset: TS colors the `<!` prefix as `yellow`
  via `doctype` and internal DTD declarations (`<!ELEMENT`, `<!ATTLIST`,
  `<!ENTITY`) with `yellow`/`white` patterns. Legacy uses `yellow`
  for the `<!` markers and `white` for DTD keywords like `ELEMENT`,
  `ATTLIST`, with `red` for content in between. The overall structure is
  similar but the internal detail coloring differs.
- `ENTITY` keyword within DOCTYPE: TS colors it as `brightred` via the
  `doctype` capture, matching legacy. `ELEMENT`, `ATTLIST`, `#REQUIRED`,
  `#PCDATA` are colored `white` in both engines.
- CDATA sections: TS colors `<![` and `CDATA` separately (`yellow` and
  `white` respectively) with content in `yellow`/`lightgray`. Legacy
  colors the entire CDATA content as `lightgray`. The TS approach
  provides more structural detail but the content coloring differs.
- Text content between tags: TS colors text as `lightgray` via
  `@variable`. Legacy leaves text as default (no color). This is a minor
  difference - TS explicitly marks text content while legacy does not.
- `<?xml ?>` prolog: TS colors the entire prolog uniformly as `white`.
  Legacy uses `white` on `red` background for the prolog. TS loses the
  distinctive red background visual.
