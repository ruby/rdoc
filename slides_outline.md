# The Future of Ruby Documentation — Slide Outline

**Speaker:** Stan Lo
**Event:** RubyKaigi 2026, Hakodate (Apr 22-24)
**Duration:** 30 minutes
**Format:** Pre-recorded demos, no live coding

---

## Section 1: Intro (2-3 min)

### Slide 1 — Title
- "The future of Ruby documentation"
- Stan Lo

### Slide 2 — About me
- Ruby committer, RDoc maintainer
- Shopify — Developer Experience (Ruby & Rails Infrastructure)
- Mention the team and key collaborators (tompng, etc.)

### Slide 3 — What this talk covers
- Three-part arc:
  1. Where we've caught up
  2. Where we're getting there
  3. How we get ahead next time
- Frame: "RDoc hasn't had major investment in years. That changed."

---

## Section 2: RDoc Primer + The Problem (2 min)

### Slide 4 — What RDoc does
- Ruby's default documentation tool (ships with Ruby since 1.8)
- Parses: Ruby source, C extensions, markup files
- Generates: HTML docs, `ri` terminal docs
- Supported markups: RDoc, Markdown, RD, TomDoc
- Powers docs.ruby-lang.org

### Slide 5 — The honest problem
- The Darkfish theme hadn't changed meaningfully in years
- No live preview for doc authors
- Ruby parser couldn't handle modern syntax (endless methods, etc.)
- Markdown support was incomplete and buggy
- No type information in docs
- Contributors drifted to YARD or abandoned docs entirely
- "We fell behind. Let's talk about catching up."

---

## Section 3: Caught Up (6 min)

> *These are table-stakes features modern docs should have. Now we have them.*

### Slide 6 — Section title: "Long overdue — caught up"

### Slide 7 — Aliki theme: before
- Screenshot of Darkfish (the old theme)
- Key problems: no dark mode, limited mobile support, dated visual design, basic search

### Slide 8 — Aliki theme: after
- Screenshot of Aliki
- Key improvements at a glance:
  - Three-column layout (sidebar + content + right-side TOC)
  - Dark mode with system preference detection
  - Advanced search with fuzzy matching and type badges
  - Mobile-first responsive design
  - Method signature cards
  - Copy-to-clipboard on code blocks
  - C and bash syntax highlighting
  - SVG icons, no embedded fonts (lighter output)
- "Named after my cat"

### Slide 9 — Aliki: search
- Demo/screenshot of the search UI
- Tiered scoring: exact > prefix > substring > fuzzy
- Namespace-aware queries (typing `String#` filters to String methods)
- Type badges distinguish classes, modules, methods, pages

### Slide 10 — Aliki: dark mode + mobile
- Side-by-side screenshots: light/dark, desktop/mobile
- System preference detection, localStorage persistence

### Slide 11 — Live-reload server
- `rdoc --server` or `make html-server` (in ruby/ruby)
- Pre-recorded demo: edit a file → browser auto-refreshes
- Technical highlights:
  - Zero external dependencies (uses Ruby's TCPServer)
  - Incremental re-parsing (only changed files)
  - Background file watcher polling mtimes
  - Page caching with invalidation on change
- "You can now preview documentation as you write it"

### Slide 12 — Prism migration (tompng shout-out)
- **The problem**: RDoc's Ruby parser used Ripper (token-stream based)
  - Couldn't handle modern Ruby syntax
  - Parser logic and comment handling tightly coupled
  - Even small bugs were hard to fix
- **The fix**: tompng (Tomoya Ishida) rewrote it using Prism's AST visitor
  - 20-month effort: opt-in → compatibility fixes → default → post-switch fixes
  - Fixes 7+ tracked long-standing issues
  - Old parser still available via `RDOC_USE_RIPPER_PARSER=1`
- **But that's not all**: tompng also rewrote:
  - Comment directive parser (`:call-seq:`, `:nodoc:`, etc.) — old system double-parsed
  - Inline formatting engine — replaced string-replacing AttributeManager with structured InlineParser
- "Three major subsystem rewrites. Invisible to users, foundational for everything else."
- Thank tompng specifically

### Slide 13 — What "caught up" means
- Modern reading experience (Aliki)
- Modern authoring experience (server mode)
- Modern parsing foundation (Prism)
- "These were table stakes. Now let's talk about what's next."

---

## Section 4: Getting There (10 min)

> *Long overdue work that's actively in progress.*

### Slide 14 — Section title: "Long overdue — getting there"

### Part A: Markdown Support (5 min)

### Slide 15 — Why Markdown?
- Markdown is the industry standard
- RDoc markup is Ruby-specific, not widely known even within the community
- Lowering the contributor barrier for Ruby core docs
- "If you can write a GitHub README, you can contribute to Ruby documentation"

### Slide 16 — Why it took so long: the pipeline
- **Pipeline diagram**:
  ```
  Markdown parser ──┐                    ┌─────────────┐
                    ├─► RDoc::Markup ───►│ Shared       │
  RDoc parser    ──┘    nodes with       │ InlineParser │──► HTML
                        RDoc strings     │ & Formatters │
                        inside           └─────────────┘
  ```
- Markdown was added ~2011 by reusing RDoc's internal pipeline
- Both parsers produce the same node types, share the same inline parser and formatters

### Slide 17 — The coupling problem: concrete example
- Markdown `~~strikethrough~~` → parser outputs `<del>text</del>` as a plain string
- That string feeds into the shared InlineParser
- InlineParser didn't recognize `<del>` → strikethrough silently broken
- Fix: modify the shared InlineParser → must verify RDoc markup still works
- "Every Markdown fix is a two-format fix. That's why progress is incremental."

### Slide 18 — What's improved
- Strikethrough (`~~text~~`) aligned with GFM spec
- GitHub-style heading anchors (`#heading-name` links)
- Table parsing fixes (inline markdown in cells, incomplete rows)
- Bash/shell syntax highlighting
- Backtick quoting in RDoc markup too
- **GFM spec comparison test suite** — systematic tracking of compatibility
- break_on_newline enabled by default

### Slide 19 — Before/after examples
- Side-by-side: same documentation written in RDoc markup vs Markdown
- Show the readability difference
- Show what works today in Markdown that didn't before

### Slide 20 — Migration plan
- Step 1: Get Markdown support to GFM-level quality (in progress)
- Step 2: Migration tooling (converting existing RDoc markup → Markdown)
- Step 3: Migrate ruby-core documentation
- Step 4: Eventually deprecate RDoc markup? (open question)
- "The URL already changed: standard_library_rdoc.html → standard_library_md.html in Ruby 3.4+"

### Part B: RBS Type Signatures (5 min)

### Slide 21 — RBS in documentation
- The `#:` inline annotation syntax (Sorbet-flavored RBS)
- Example:
  ```ruby
  #: (String name, ?Integer age) -> User
  def create_user(name, age = nil)
    # ...
  end
  ```
- RDoc extracts these and displays type signatures in HTML output and `ri`

### Slide 22 — Demo: RBS in HTML
- Pre-recorded: show a class page with type signatures rendered
- Type names are linked to their corresponding documentation pages
- Method signature cards with types

### Slide 23 — Demo: RBS in ri
- Pre-recorded: terminal output showing `ri` with type information
- Types displayed alongside method documentation

### Slide 24 — The question: can RBS replace call-seq?
- Show the overlap:
  ```
  # call-seq:
  #   readlines(sep=$/)     -> array
  #   readlines(limit)      -> array

  #: (?String sep) -> Array[String]
  #: (Integer limit) -> Array[String]
  ```
- Both express: method name, parameters, return type, overloads
- "For a language that doesn't want typing, writing type signatures for documentation — that's huge"

### Slide 25 — The gap: default values
- call-seq shows `sep=$/` — the actual default value
- RBS can only say `?String sep` — optional, but what's the default?
- This matters especially for C extensions where there's no Ruby source to inspect
- "If we want to migrate, RBS needs default value support"

### Slide 26 — What's next for RBS in docs
- Status: aiming to ship on docs.ruby-lang.org (PR #1665)
- Migration path from call-seq: TBD, depends on RBS default value support
- Long-term: structured, machine-readable signatures replace free-form text
- In ruby/ruby, writing type signatures directly for documentation purposes

---

## Section 5: Getting Ahead (3 min)

> *How do we avoid falling behind again?*

### Slide 27 — Section title: "Getting ahead"

### Slide 28 — AI & documentation: what we evaluated
- llms.txt / llms-full.txt: the proposed standard for LLM-friendly docs
- We prototyped it. Then we looked at the data:
  - 10% adoption across 300k domains
  - **Zero measurable impact** on AI citations (SE Ranking / Search Engine Journal study)
  - XGBoost model improved when llms.txt was *removed* as a variable
  - Zero bot visits from GPTBot, ClaudeBot, PerplexityBot
  - No major LLM provider officially supports it
- "The trade-off: generation time + code complexity for all users, for negligible benefit"
- Decision: not pursuing. Responsible maintainership > hype.

### Slide 29 — The real AI play: better foundations
- Instead of special files for LLMs, build docs that are better for *everyone*:
  - Markdown: universally understood by humans AND machines
  - RBS types: structured, machine-readable signatures
  - Clean architecture: enables future tooling we can't predict yet
- ruby-skills (github.com/st0012/ruby-skills): practical AI tooling for Ruby development
  - 109 stars, actively used
  - Teaches AI assistants about Ruby version management, authoritative doc sources, test framework nuances
  - Future: RDoc-specific skills once the feature work lands
- "Don't chase trends. Build good foundations that naturally serve future consumers."

### Slide 30 — The philosophy
- Evaluate before building (data over hype)
- Invest in foundations (Prism, Markdown, types) not band-aids
- Make documentation a first-class part of the Ruby experience
- "The best way to prepare for the future is to get the present right"

---

## Section 6: Recap (1 min)

### Slide 31 — Summary

| Caught up | Getting there | Getting ahead |
|-----------|---------------|---------------|
| Aliki theme | Markdown/GFM | Evaluate with data |
| Server mode | RBS type sigs | Build foundations |
| Prism parser | call-seq → RBS? | Serve all consumers |

### Slide 32 — Call to action
- Contribute to Ruby documentation — it's Markdown now!
- Try `rdoc --server` for your own projects
- Check out ruby-skills for better AI-assisted Ruby development
- Links:
  - github.com/ruby/rdoc
  - docs.ruby-lang.org
  - github.com/st0012/ruby-skills

### Slide 33 — Thank you
- Thank tompng, Shopify team, Ruby committers
- Questions?

---

## Appendix: Research Files

All supporting research is in `research/`:
- `rdoc_prs.md` — 85 PRs in ruby/rdoc since Oct 2025
- `ruby_prs.md` — 41 PRs in ruby/ruby since Oct 2025
- `current_features.md` — Feature state analysis
- `llms_txt_adoption.md` — llms.txt adoption data
- `ruby_skills_repo.md` — ruby-skills repo analysis
- `callseq_vs_rbs.md` — call-seq vs RBS comparison
- `markdown_rdoc_coupling.md` — Markdown/RDoc architectural coupling
- `tompng_prism_work.md` — tompng's contributions

## Timing Budget

| Section | Time | Slides |
|---------|------|--------|
| 1. Intro | 2-3 min | 3 |
| 2. RDoc primer + problem | 2 min | 2 |
| 3. Caught up | 6 min | 8 |
| 4. Getting there | 10 min | 12 |
| 5. Getting ahead | 3 min | 4 |
| 6. Recap | 1 min | 3 |
| **Total** | **~28-30 min** | **~32** |

## Working with the Slides

### Dev Server

Start the dev server (serves files + enables saving):

```bash
node server.js        # http://localhost:8080
node server.js 3000   # custom port
```

Open `http://localhost:8080` in any browser. The slides are served as the default page.

### Editing

Press **E** or hover the top-left corner to enter edit mode. Click any text to edit. Press **N** to open the speaker notes editor. **⌘S** saves everything (slide content + notes) back to the file via the dev server — works from anywhere, any browser, no dialogs.

### Presenter Mode

Press **S** to open the presenter window (timer, current/next slide, speaker notes). Press **B** to blackout the main window.

### Exporting to PDF

Requires Playwright and pdf-lib. One-time setup:

```bash
mkdir -p /tmp/playwright-export && cd /tmp/playwright-export
pnpm init && pnpm add playwright pdf-lib
pnpx playwright install chromium
```

Then export:

```bash
cd /tmp/playwright-export
node /path/to/export-slides.mjs /path/to/the-future-of-ruby-documentation.html
```

Output: `the-future-of-ruby-documentation.pdf` next to the HTML file. Captures at 960x540 viewport with 2x DPR for sharp, readable text.

### Google Slides

Upload the exported PDF to Google Drive. Right-click → Open with → Google Slides. Each page becomes a slide with the content as an image. You can then add speaker notes in Google Slides directly.
