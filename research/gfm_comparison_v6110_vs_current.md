# GFM Comparison: RDoc v6.11.0 vs Current

Test input: `/tmp/gfm_test_input.md`
v6.11.0 output: `/tmp/gfm_v6110.html`
Current output: `/tmp/gfm_current.html`

## Feature Comparison

| Feature | GFM | RDoc (current) | RDoc v6.11.0 | Notes |
|---------|-----|---------------|-------------|-------|
| ATX Headings (#) | ✅ | ✅ | ✅ | Both support 1-6, optional closing # |
| Setext Headings | ✅ | ✅ | ✅ | = for H1, - for H2 |
| Heading anchors | `#atx-heading-1` | ✅ `#atx-heading-1` | ⚠️ `#label-ATX+Heading+1` | v6.11.0 used `label-` prefix with + encoding. Current uses GitHub-style slugs |
| Paragraphs | ✅ | ✅ | ✅ | Full match |
| Bold/Italic | ✅ | ✅ | ✅ | `**bold**` and `*italic*` work in both |
| Inline code | ✅ | ✅ | ✅ | Single backticks work |
| Indented code blocks | ✅ | ✅ | ✅ | 4 spaces or 1 tab |
| Fenced code (backticks) | ✅ | ✅ | ✅ | Basic ``` works |
| Fenced code (4+ backticks) | ✅ | ❌ | ❌ | Both render as inline `<code>`, not a code block |
| Fenced code (tildes) | ✅ | ❌ | ❌ | v6.11.0: escaped as `<s>~...` (strikethrough conflict). Current: rendered as `<del>` (strikethrough), not code block |
| Info strings (language) | ✅ | ⚠️ | ⚠️ | `ruby` highlighted in both. `bash` highlighted in current, NOT in v6.11.0 (was `class="ruby"`) |
| Blockquotes | ✅ | ✅ | ✅ | Both support blockquotes |
| Lazy continuation | ✅ | ⚠️ | ⚠️ | v6.11.0: merged both lines into one blockquote. Current: split into 2 separate blockquotes. Neither matches GFM exactly |
| Bullet lists | ✅ | ✅ | ✅ | `-`, `*`, `+` all work |
| Ordered lists | ✅ | ⚠️ | ⚠️ | Both render ordered items as unordered `<ul>` — no `<ol>` support |
| Nested lists | ✅ | ⚠️ | ⚠️ | Nesting flattened in both versions |
| Thematic breaks | ✅ | ✅ | ✅ | `---`, `***`, `___` all produce `<hr>` |
| Tables | ✅ | ✅ | ✅ | Basic tables work in both |
| Table inline markdown | ✅ | ✅ | ⚠️ | v6.11.0: `code` in table cell rendered as `'code\`` (broken). Current: renders correctly as `<code>` |
| Strikethrough (~~) | ✅ | ✅ | ❌ | v6.11.0: rendered as escaped `<s>` text. Current: correct `<del>` |
| Links | ✅ | ✅ | ✅ | Both work |
| Link titles | ✅ | ⚠️ | ⚠️ | Both drop the title attribute |
| Images | ✅ | ⚠️ | ✅ | v6.11.0: correct `<img>`. Current: broken — splits alt text (`<img alt="Alt"> text`) |
| HTML blocks | ✅ | ✅ | ✅ | `<div>` blocks pass through |
| Inline HTML | ✅ | ✅ | ✅ | `<em>` works in both |
| Hard line breaks (spaces) | ✅ | ✅ | ✅ | Two trailing spaces → `<br>` |
| Hard line breaks (backslash) | ✅ | ❌ | ❌ | Both render the literal backslash |
| Double backtick code spans | ✅ | ✅ | ✅ | `` `inner` `` preserved in both |

## Summary of Differences

### Fixed in current (was broken in v6.11.0):
1. **Strikethrough** (`~~text~~`) — was escaped as raw `<s>` text, now renders as `<del>`
2. **Heading anchors** — was `#label-ATX+Heading+1`, now GitHub-style `#atx-heading-1`
3. **Bash syntax highlighting** — `bash` code blocks now get proper highlighting, not Ruby highlighting
4. **Table inline code** — `` `code` `` in table cells was broken (rendered as `'code\``), now works

### Broken in current (was working in v6.11.0):
1. **Images** — `![Alt text](image.png)` now splits into `<img alt="Alt"> text` instead of correct `<img alt="Alt text">`

### Broken in both versions (vs GFM):
1. **Fenced code (tildes)** — conflicts with strikethrough syntax
2. **Fenced code (4+ backticks)** — doesn't nest properly
3. **Ordered lists** — rendered as `<ul>` not `<ol>`
4. **Nested lists** — flattened
5. **Hard line breaks (backslash)** — literal backslash shown
6. **Link titles** — title attribute dropped
7. **Lazy continuation** — doesn't match GFM behavior exactly
