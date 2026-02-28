# Markdown Reference

This document is the comprehensive reference for Markdown support in RDoc.
It covers all syntax, extensions, and formatting options available.

For Ruby-specific features that require actual code (like cross-reference targets
and directives that only work in Ruby comments), see RDoc::Example.

## About the Examples

- Examples show Markdown syntax.
- Rendered output is shown in blockquotes where helpful.

## Blocks

Markdown documents consist of various block types:

- [Paragraphs](#paragraphs): ordinary text blocks.
- [Headings](#headings): section titles.
- [Code Blocks](#code-blocks): verbatim text with syntax highlighting.
- [Blockquotes](#blockquotes): quoted passages.
- [Lists](#lists): bullet, numbered, and definition lists.
- [Tables](#tables): tabular data.
- [Horizontal Rules](#horizontal-rules): visual separators.

### Paragraphs

A paragraph is one or more consecutive lines of text,
separated from other blocks by blank lines.

Example:

```markdown
This is the first paragraph. It can span
multiple lines.

This is the second paragraph.
```

Single newlines within a paragraph become spaces in the output.

### Headings

#### ATX-Style Headings

Use `#` characters at the start of a line. Levels 1-6 are supported:

```markdown
# Heading Level 1
## Heading Level 2
### Heading Level 3
#### Heading Level 4
##### Heading Level 5
###### Heading Level 6
```

Optional closing `#` characters are allowed:

```markdown
## Heading ##
```

#### Setext-Style Headings

Underline text with `=` for level 1 or `-` for level 2:

```markdown
Heading Level 1
===============

Heading Level 2
---------------
```

### Code Blocks

#### Indented Code Blocks

Indent code by 4 spaces or 1 tab:

```markdown
This is a paragraph.

    def hello
      puts "world"
    end

This is another paragraph.
```

#### Fenced Code Blocks

Use triple backticks with an optional language identifier:

    ```ruby
    def hello
      puts "world"
    end
    ```

Supported languages for syntax highlighting: `ruby` (and `rb` alias) with server-side
highlighting, and `c`, `bash`/`sh`/`shell`/`console` with client-side JavaScript highlighting.
Other info strings are accepted and added as a CSS class but receive no highlighting.

### Blockquotes

Prefix lines with `>`:

```markdown
> This is a blockquote.
> It can span multiple lines.
>
> Multiple paragraphs are supported.
```

Blockquotes can contain other elements:

```markdown
> ## Heading inside blockquote
>
> - List item 1
> - List item 2
>
> Code inside blockquote:
>
>     def example
>       :ok
>     end
```

Nested blockquotes:

```markdown
> Outer quote
>
> > Nested quote
```

### Lists

#### Bullet Lists

Use `*`, `+`, or `-` followed by a space:

```markdown
* Item 1
* Item 2
* Item 3
```

Or:

```markdown
- Item 1
- Item 2
- Item 3
```

#### Numbered Lists

Use digits followed by `.` and a space:

```markdown
1. First item
2. Second item
3. Third item
```

The actual numbers don't matter; they're renumbered in output:

```markdown
1. First
1. Second
1. Third
```

#### Nested Lists

Indent with 4 spaces to nest:

```markdown
* Item 1
    * Nested item A
    * Nested item B
* Item 2
    1. Numbered nested
    2. Also numbered
```

#### Definition Lists

Use a term on one line, then `:` followed by the definition:

```markdown
term
:   Definition of the term.

cat
:   A small furry mammal.

ant
:   A little insect.
```

Multiple definitions for one term:

```markdown
apple
:   A fruit
:   A technology company
```

### Tables

Create tables with pipes and dashes:

```markdown
| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
| Cell 1   | Cell 2   | Cell 3   |
| Cell 4   | Cell 5   | Cell 6   |
```

#### Column Alignment

Use colons to specify alignment:

```markdown
| Left     | Center   | Right    |
|:---------|:--------:|---------:|
| Left     | Center   | Right    |
| aligned  | aligned  | aligned  |
```

- `:---` or `---` for left alignment (default)
- `:---:` for center alignment
- `---:` for right alignment

Tables support inline formatting in cells:

```markdown
| Feature     | Syntax          |
|-------------|-----------------|
| **Bold**    | `**text**`      |
| *Italic*    | `*text*`        |
| `Code`      | `` `text` ``    |
```

### Horizontal Rules

Use three or more `-`, `*`, or `_` on a line by themselves:

```markdown
---

* * *

___
```

## Text Markup

Inline text can be formatted with various markup:

- [Italic](#italic): emphasized text.
- [Bold](#bold): strong emphasis.
- [Bold and Italic](#bold-and-italic): combined emphasis.
- [Strikethrough](#strikethrough): deleted text.
- [Inline Code](#inline-code): monospace text.

### Italic

Use single asterisks or underscores:

```markdown
This is *italic* text.
This is _also italic_ text.
```

> This is *italic* text.
> This is _also italic_ text.

**Note:** Underscores within words are not interpreted as emphasis:

```markdown
foo_bar_baz remains plain text
```

### Bold

Use double asterisks or underscores:

```markdown
This is **bold** text.
This is __also bold__ text.
```

> This is **bold** text.
> This is __also bold__ text.

### Bold and Italic

Use triple asterisks or underscores:

```markdown
This is ***bold and italic*** text.
This is ___also bold and italic___ text.
```

> This is ***bold and italic*** text.
> This is ___also bold and italic___ text.

### Strikethrough

Use double tildes:

```markdown
This is ~~strikethrough~~ text.
```

> This is ~~strikethrough~~ text.

### Inline Code

Use backticks:

```markdown
Use the `puts` method.
```

> Use the `puts` method.

For code containing backticks, use multiple backticks:

```markdown
Use `` `backticks` `` in code.
```

> Use `` `backticks` `` in code.

## Links

### Inline Links

```markdown
[Link text](https://example.com)
```

> [Link text](https://example.com)

With optional title (title is parsed but not used in RDoc output):

```markdown
[Link text](https://example.com "Title")
```

### Reference Links

Define a reference, then use it:

```markdown
[Link text][ref]

[ref]: https://example.com
```

Implicit reference (link text matches reference):

```markdown
[Example][]

[Example]: https://example.com
```

### Autolinks

URLs and emails in angle brackets become links:

```markdown
<https://example.com>
<user@example.com>
```

> <https://example.com>
> <user@example.com>

### Cross-References

Link to RDoc-documented classes, modules, and methods:

```markdown
[RDoc module](rdoc-ref:RDoc)
[Options class](rdoc-ref:RDoc::Options)
[document method](rdoc-ref:RDoc::RDoc#document)
```

See [rdoc.rdoc](rdoc.rdoc) for complete cross-reference documentation.

## Images

Basic image syntax:

```markdown
![Alt text](path/to/image.png)
```

Image as a link:

```markdown
[![Alt text](image.png)](https://example.com)
```

## Anchor Links

RDoc supports GitHub-style anchor links. You can link to any heading using its
anchor, which is the heading text converted to lowercase with spaces replaced
by hyphens and special characters removed.

For example:

* [Link to Footnotes](#footnotes)
* [Link to Blockquotes](#blockquotes)
* [Link to Anchor Links](#anchor-links)

When multiple headings produce the same anchor, RDoc appends `-1`, `-2`, etc.
to subsequent duplicates, matching GitHub's behavior.

## Footnotes

### Reference Footnotes

Add a footnote reference in text, then define it:

```markdown
Here is some text[^1] with a footnote[^note].

[^1]: This is the first footnote.
[^note]: This is another footnote.
```

### Inline Footnotes

Create footnotes inline:

```markdown
Here is text ^[with an inline footnote].
```

Footnotes are collected and rendered at the bottom of the section,
separated by a horizontal rule.

## HTML

### Block HTML

Raw HTML blocks are preserved:

```markdown
<div class="note">
  <p>This is HTML content.</p>
</div>
```

Supported block-level tags include: `<address>`, `<blockquote>`, `<div>`,
`<fieldset>`, `<form>`, `<h1>`-`<h6>`, `<ol>`, `<p>`, `<pre>`, `<table>`, `<ul>`.

### Inline HTML

Inline HTML is also preserved:

```markdown
This has <b>bold</b> and <em>emphasized</em> HTML.
```

## Special Characters

### Escaping

Use backslash to escape special characters:

```markdown
\*not italic\*
\`not code\`
\[not a link\]
\# not a heading
```

Escapable characters: `` ` \ : | * _ { } [ ] ( ) # + . ! > < - ``

### HTML Entities

Named, decimal, and hexadecimal entities are supported:

```markdown
&copy; &mdash; &pi;
&#65; &#x41;
```

## Line Breaks

End a line with two or more spaces for a hard line break:

```markdown
Line one
Line two
```

## Directives

RDoc directives work in Markdown files within Ruby comments.
Use the `:markup: markdown` directive to specify Markdown format.

```ruby
# :markup: markdown

# This class uses **Markdown** for documentation.
#
# ## Features
#
# - Bold with `**text**`
# - Italic with `*text*`
class MyClass
end
```

Common directives (same as RDoc markup):

- `:nodoc:` - Suppress documentation
- `:doc:` - Force documentation
- `:stopdoc:` / `:startdoc:` - Start/stop documentation parsing
- `:call-seq:` - Custom calling sequence
- `:section:` - Create documentation sections

See [rdoc.rdoc](rdoc.rdoc) for complete directive documentation.

## Comparison with RDoc Markup

| Feature | RDoc Markup | Markdown |
|---------|-------------|----------|
| Headings | `= Heading` | `# Heading` |
| Bold | `*word*` | `**word**` |
| Italic | `_word_` | `*word*` |
| Monospace | `+word+` or `` `word` `` | `` `word` `` |
| Links | `{text}[url]` | `[text](url)` |
| Code blocks | Indent beyond margin | Indent 4 spaces or fence |
| Block quotes | `>>>` | `>` |
| Tables | Not supported | Supported |
| Strikethrough | `<del>text</del>` | `~~text~~` |
| Footnotes | Not supported | `[^1]` |

## Notes and Limitations

1. **Link titles are parsed but not used** - The title in `[text](url "title")` is ignored.

2. **Underscores in words** - `foo_bar` is never italicized; emphasis requires whitespace boundaries.

3. **Footnotes are collapsed** - Multiple paragraphs in a footnote become a single paragraph.

4. **Syntax highlighting** - Only `ruby`/`rb` (server-side) and `c`, `bash`/`sh`/`shell`/`console` (client-side) receive syntax highlighting. Other info strings are accepted but not highlighted.

5. **Fenced code blocks** - Only triple backticks are supported. Tilde fences (`~~~`) are not supported as they conflict with strikethrough syntax. Four or more backticks for nesting are also not supported.

6. **Auto-linking** - RDoc automatically links class and method names in output, even without explicit link syntax.

## Comparison with GitHub Flavored Markdown (GFM)

This section compares RDoc's Markdown implementation with the
[GitHub Flavored Markdown Spec](https://github.github.com/gfm/) (Version 0.29-gfm, 2019-04-06).

### Block Elements

| Feature | GFM | RDoc | Notes |
|---------|:---:|:----:|-------|
| ATX Headings (`#`) | ✅ | ✅ | Both support levels 1-6, optional closing `#` |
| Setext Headings | ✅ | ✅ | `=` for H1, `-` for H2 |
| Paragraphs | ✅ | ✅ | Full match |
| Indented Code Blocks | ✅ | ✅ | 4 spaces or 1 tab |
| Fenced Code (backticks) | ✅ 3+ | ⚠️ 3 only | RDoc doesn't support 4+ backticks for nesting |
| Fenced Code (tildes) | ✅ `~~~` | ❌ | Conflicts with strikethrough syntax |
| Info strings (language) | ✅ any | ⚠️ limited | `ruby`/`rb`, `c`, and `bash`/`sh`/`shell`/`console` highlighted; others accepted as CSS class |
| Blockquotes | ✅ | ✅ | Full match, nested supported |
| Lazy Continuation | ✅ | ⚠️ | Continuation text is included in blockquote but line break is lost (becomes a space) |
| Bullet Lists | ✅ | ✅ | `*`, `+`, `-` supported |
| Ordered Lists | ✅ `.` `)` | ⚠️ `.` only | RDoc doesn't support `)` delimiter; numbers are always renumbered from 1 |
| Nested Lists | ✅ | ✅ | 4-space indentation |
| Tables | ✅ | ✅ | Full alignment support |
| Thematic Breaks | ✅ | ✅ | `---`, `***`, `___` |
| HTML Blocks | ✅ 7 types | ⚠️ | See below |

#### HTML Blocks

GFM defines 7 types of HTML blocks:

| Type | Description | GFM | RDoc | Notes |
|------|-------------|:---:|:----:|-------|
| 1 | `<script>`, `<pre>` | ✅ | ✅ | |
| 1 | `<style>` | ✅ | ❌ | Available via `css` extension (disabled by default) |
| 2 | HTML comments `<!-- -->` | ✅ | ✅ | |
| 3 | Processing instructions `<? ?>` | ✅ | ❌ | |
| 4 | Declarations `<!DOCTYPE>` | ✅ | ❌ | |
| 5 | CDATA `<![CDATA[ ]]>` | ✅ | ❌ | |
| 6 | Block-level tags | ✅ | ⚠️ | |
| 7 | Any complete open/close tag | ✅ | ❌ | |

RDoc uses a whitelist of block-level tags defined in
[lib/rdoc/markdown.kpeg](https://github.com/ruby/rdoc/blob/master/lib/rdoc/markdown.kpeg)
(see `HtmlBlockInTags`). HTML5 semantic elements like `<article>`, `<section>`,
`<nav>`, `<header>`, `<footer>` are not supported.

### Inline Elements

| Feature | GFM | RDoc | Notes |
|---------|:---:|:----:|-------|
| Emphasis `*text*` `_text_` | ✅ | ⚠️ | Intraword emphasis not supported (see [Notes](#notes-and-limitations)) |
| Strong `**text**` `__text__` | ✅ | ✅ | Full match |
| Combined `***text***` | ✅ | ✅ | Full match |
| Code spans | ✅ | ✅ | Multiple backticks supported |
| Inline links | ✅ | ✅ | Full match |
| Reference links | ✅ | ✅ | Full match |
| Link titles | ✅ | ⚠️ | Parsed but not rendered |
| Images | ✅ | ✅ | Full match |
| Autolinks `<url>` | ✅ | ✅ | Full match |
| Hard line breaks | ✅ | ⚠️ | 2+ trailing spaces only; backslash `\` at EOL not supported |
| Backslash escapes | ✅ | ⚠️ | Subset of GFM's escapable characters (e.g., `~` not escapable) |
| HTML entities | ✅ | ✅ | Named, decimal, hex |
| Inline HTML | ✅ | ⚠️ | `<b>` converted to `<strong>`, `<i>` to `<em>`; `<strong>` itself is escaped |

### GFM Extensions

| Feature | GFM | RDoc | Notes |
|---------|:---:|:----:|-------|
| Strikethrough `~~text~~` | ✅ | ✅ | Full match |
| Task Lists `[ ]` `[x]` | ✅ | ❌ | Not supported |
| Extended Autolinks | ✅ | ⚠️ | See below |
| Disallowed Raw HTML | ✅ | ❌ | No security filtering |

#### GFM Extended Autolinks

GFM automatically converts certain text patterns into links without requiring
angle brackets (`<>`). RDoc also auto-links URLs and `www.` prefixes through
its cross-reference system, but the behavior differs from GFM.

GFM recognizes these patterns:

- `www.example.com` — text starting with `www.` followed by a valid domain
- `https://example.com` — URLs starting with `http://` or `https://`
- `user@example.com` — valid email addresses

RDoc auto-links `www.` prefixes and `http://`/`https://` URLs similarly to GFM.
However, bare email addresses like `user@example.com` are not auto-linked;
use `<user@example.com>` instead.

### RDoc-Specific Features (not in GFM)

- [Definition Lists](#definition-lists)
- [Footnotes](#footnotes)
- [Cross-references](#cross-references)
- [Anchor Links](#anchor-links)
- [Directives](#directives)
