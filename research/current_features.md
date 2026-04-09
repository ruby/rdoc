# RDoc Current Feature State (branch: stan-talk-prep)

Research for RubyKaigi talk preparation. Based on code at `/Users/hung-wulo/src/github.com/Shopify/rdoc-talk-prep`.

---

## 1. Aliki Theme

**What it is:** A modern, from-scratch HTML theme that subclasses `RDoc::Generator::Darkfish`. Authored by Stan Lo. Located at `lib/rdoc/generator/aliki.rb` with templates in `lib/rdoc/generator/template/aliki/`.

### How it differs from Darkfish

| Feature | Darkfish | Aliki |
|---------|----------|-------|
| Layout | Two-column (sidebar + content) | Three-column (sidebar + content + right-side TOC) |
| Dark mode | None | Full dark mode with `data-theme` toggle, localStorage persistence, and system preference detection |
| CSS size | 702 lines, ships embedded fonts (Lato, SourceCodePro) | 1994 lines, uses system font stack (no embedded fonts = lighter output) |
| CSS architecture | Flat styles | Design system with CSS custom properties (tokens for colors, spacing, typography, shadows, transitions, z-index) |
| JS files | 2 files (260 lines total: darkfish.js, search.js) | 7 files: aliki.js, theme-toggle.js, search_controller.js, search_navigation.js, search_ranker.js, c_highlighter.js, bash_highlighter.js |
| Search | Basic search.js | Custom ranked search with fuzzy matching, namespace/method-aware queries, tiered scoring (exact > prefix > substring > fuzzy), type-aware priority, search snippets, type badges |
| Search index | Uses JsonIndex generator (separate pass) | Built-in `write_search_index` / `build_search_index` (no extra generator needed), writes `js/search_data.js` |
| Mobile | No specific mobile support | Responsive grid layout, mobile search modal, hamburger sidebar toggle, viewport-aware JS |
| Syntax highlighting | None for C or shell code | Client-side C highlighter (keywords, types, macros, strings, preprocessor directives, Ruby C API types like VALUE/ID) and bash/shell highlighter (prompts, commands, options, strings, env vars, comments) |
| TOC | Server-side sidebar TOC only | Auto-generated right-sidebar "On This Page" TOC from headings with IntersectionObserver scroll-spy, smooth scrolling |
| Code blocks | Plain `<pre>` | Copy-to-clipboard buttons dynamically added to all `<pre>` elements |
| Header/Footer | Minimal | Top navbar with brand, search bar, theme toggle; customizable footer via `footer_content` option in `.rdoc_options` |
| Open Graph / SEO | None | Full Open Graph and Twitter Card meta tags, canonical URL support, rich `<meta>` descriptions |
| Icons | Silk icon sprites (images/) | Inline SVG symbol sprites (no image files) |
| Breadcrumbs | Yes | Yes (same approach) |
| Method entries | Standard list | Styled as "signature cards" (commit dc7a1679) |
| Ancestor tree | Shows parent class only | Full ancestor chain with recursive nested `<ul>` |
| Source language | `<pre>` (no class) | `<pre class="c">` or `<pre class="ruby">` via `method.source_language` - enables language-specific highlighting |

### Key design decisions
- Sidebar is hidden by default with `hidden` attribute, shown by JS on large viewports. This avoids sidebar flicker on mobile page load.
- Search data is written as `.js` (not `.json`) to avoid CORS issues when viewing generated docs via `file://` protocol.
- `resolve_url(rel_prefix, url)` helper ensures absolute URLs pass through unchanged while relative URLs get prefixed correctly.

---

## 2. Markdown Support (GFM)

**Parser:** `lib/rdoc/markdown.kpeg` (PEG grammar compiled to `lib/rdoc/markdown.rb`).

### Default extensions enabled
- `definition_lists` - PHP Markdown Extra style
- `github` - fenced code blocks, syntax highlighting, tables, strikethrough
- `html` - raw HTML blocks
- `notes` - footnotes
- `strike` - `~~strikethrough~~`

### GFM features supported
- Fenced code blocks (triple backtick with optional language tag)
- Tables (header, alignment, body rows with inline markdown in cells)
- Strikethrough (`~~text~~`)
- Auto-linking of bare URLs
- Underscores in words are never treated as emphasis

### `break_on_newline` extension
- Converts all newlines into hard line breaks (GFM-style). Commit `d62b0321` enabled this by default. **Note:** it is listed as an extension but NOT in `DEFAULT_EXTENSIONS` in the kpeg source - it appears the default enablement may be done elsewhere or the commit was on a different branch.

### Recent markdown improvements (from git log)
- `bd0e544f` - Fix blockquote lazy continuation parsing
- `d62b0321` - Enable `break_on_newline` by default
- `c59a7a89` - Fix table parser consuming lines without pipes
- `52b24c2d` - Implement escapes in Markdown-to-RDoc conversion
- `0602d13b` - Align strikethrough with GitHub Markdown spec
- `39f5a2d9` - Fix backslash handling in table cell code spans
- `eaac67d3` - Support markdown syntax in table cells
- `393c0e87` - Add comparison with GitHub Flavored Markdown spec

### Markdown output (`lib/rdoc/markup/to_markdown.rb`)
- `RDoc::Markup::ToMarkdown` converts RDoc's internal markup tree back to Markdown format
- Subclasses `ToRdoc`, overrides heading markers to `#`/`##`/etc.
- Handles lists (bullet, numbered, definition/label)

### What is NOT supported
- Task lists / checkboxes
- GitHub-style alerts (`> [!NOTE]`, `> [!WARNING]`)
- Autolinks without angle brackets (bare URL auto-linking is RDoc-specific, not the GFM autolink extension)

---

## 3. RBS Integration

**Status: Not present in this branch.**

Grep for `rbs`, `RBS`, `type_sig`, `rbs_` across `lib/` returned zero matches. There is no RBS type signature parsing, display, or integration in the generator, parser, or templates.

The memory file mentions prior investigation into "RBS Integration Phase 1" with inline `#:` type sigs in HTML output, but this code is not on the current `stan-talk-prep` branch.

---

## 4. LLM/AI Support (llms.txt)

**Status: Not present.**

Grep for `llms`, `llm`, `LLM`, `llms.txt` across the entire codebase (`.rb` files and all files) returned zero relevant matches. There is no `llms.txt` generator, no LLM-friendly output format, and no AI-related features.

---

## 5. Server Mode (Live Reload)

**File:** `lib/rdoc/server.rb` (394 lines)

### Architecture
- Invoked via `rdoc --server` (added in commit `3c6f5f6f`)
- Uses Ruby's built-in `TCPServer` - no WEBrick, no external dependencies
- Binds to `127.0.0.1:<port>`
- Multi-threaded: one thread per client connection, plus a background file watcher thread
- Uses the Aliki generator exclusively (`RDoc::Generator::Aliki`)

### Live reload mechanism
1. Background watcher thread polls source file mtimes every 1 second
2. Detects modified, new, and deleted files
3. On change: re-parses only changed files via `@rdoc.parse_file(f)`, clears stale contributions, refreshes generator data, invalidates page cache
4. Injects a `<script>` polling snippet before `</body>` in every HTML response
5. Browser polls `/__status` every 1 second, comparing `last_change` timestamp
6. If timestamp changed, browser does `location.reload()`

### Request routing
- `/__status` - returns JSON `{last_change: <float>}` for live reload
- `/css/*`, `/js/*` - serves static assets from Aliki template directory (with path traversal protection)
- `/js/search_data.js` - dynamically generated search index
- `/index.html` - calls `@generator.generate_index`
- `/table_of_contents.html` - calls `@generator.generate_table_of_contents`
- `/ClassName.html` - looks up class/module in store, renders via generator
- `/filename.html` - looks up text page in store
- 404s rendered through `generate_servlet_not_found`

### Page caching
- Pages are cached in `@page_cache` (hash)
- Cache is fully invalidated on any file change (entire hash cleared)
- Mutex protects all shared state (`@page_cache`, `@last_change_time`, store operations)

### Terminal output
- Prints clickable hyperlink to terminal using OSC 8 escape sequences
- Logs `<status> <path> (<duration>ms)` for page requests
- Logs re-parse timing: `Re-parsed <files> (<duration>ms)`
- Status/asset requests are not logged (to reduce noise)

### Recent fixes
- `e4e332f2` - Print timing for page requests and re-parsing
- `237f113d` - Fix deadlock on Ctrl+C
- `78325e18` - Fix live reload for C files
- `8323a434` - Fix page links returning 404

---

## 6. Markup Generator (`lib/rdoc/generator/markup.rb`)

This is NOT a standalone generator - it is a mixin module (`RDoc::Generator::Markup`) included into `RDoc::CodeObject` and `RDoc::Context::Section`. It provides HTML rendering helpers used by the Darkfish/Aliki generators:

- `description` - renders a CodeObject's comment as HTML
- `formatter` - creates an `RDoc::Markup::ToHtmlCrossref` formatter for cross-reference linking
- `aref_to(target_path)` / `as_href(from_path)` - relative URL generation between pages
- `cvs_url(url, full_path)` - web repository link construction
- `canonical_url` - builds canonical URL using `@store.options.canonical_root`
- `RDoc::MethodAttr#markup_code` - converts token stream to HTML with optional line numbers
- `RDoc::ClassModule#description` - renders from `@comment_location` (multi-file comment support)

The separate `RDoc::Markup::ToMarkdown` class in `lib/rdoc/markup/to_markdown.rb` converts RDoc markup tree back to Markdown text output (headings, lists, etc.) but is not used by any generator for documentation output.

---

## Summary for Talk

### Shipping / Ready
1. **Aliki theme** - Complete modern theme with dark mode, responsive layout, three-column design, advanced search, C/bash syntax highlighting, copy-to-clipboard, SVG icons, Open Graph metadata, customizable footer
2. **Server mode** - Zero-dependency live-reload server using TCPServer, file watching with incremental re-parsing, page caching
3. **GFM improvements** - Tables with inline markdown, strikethrough aligned with GFM spec, blockquote fixes, fenced code blocks, GFM spec comparison tests

### Not present
4. **RBS integration** - No type signature display in generated docs
5. **LLM support** - No `llms.txt` generation or LLM-friendly output
6. **Markdown output generator** - `ToMarkdown` exists as a formatter but is not wired to any documentation output generator
