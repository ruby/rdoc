# The Future of Ruby Documentation — Slide Outline

**Speaker:** Stan Lo
**Event:** RubyKaigi 2026, Hakodate (Apr 22-24)
**Duration:** 30 minutes
**Format:** Pre-recorded demos, no live coding

---

## Section 1: The Hook (3-4 min)

### Slide 1 — Title
- "The future of Ruby documentation"
- Stan Lo

### Slide 2 — About me
- Ruby committer, RDoc maintainer
- Ruby DX team @Shopify
- Key collaborator: tompng (Tomoya Ishida)

### Slide 3 — Rubydex
- A Ruby code indexer — `Shopify/rubydex`
- Static code intelligence for Ruby
- Alexandre Terrasa's talk: "Blazing-fast Code Indexing for Smarter Ruby Tools"

### Slide 4 — Bold claim
- "The future of Ruby's documentation is about AI"

### Slide 5 — What AI needs from documentation (part 1)
- AI likes **clear, accurate documentation**
- Misinformation gets amplified by AI

### Slide 6 — What AI needs from documentation (part 2)
- AI likes **Markdown** — it reads and writes it natively
- AI likes **clear intent** — type signatures tell it what code does

### Slide 7 — What helps AI write documentation
- AI likes **quick, deterministic feedback**
- Coverage checks, missing reference warnings — not "try and see"

### Slide 8 — The twist
- "All of these help human developers too."
- These aren't AI requirements — they're good documentation requirements

### Slide 9 — RDoc wasn't providing these
- Old theme, no live preview, incomplete Markdown, no type info
- Parser couldn't handle modern Ruby

### Slide 10 — So here's what we did
- "...to make RDoc work for us, and our agents"

---

## Section 2: Here's What We Did (~14-16 min)

### Slide 11 — Before: Darkfish
- Screenshot of old Darkfish theme

### Slide 12 — After: Aliki
- Dark mode, mobile, fuzzy search, method signature cards
- "Named after my cat. Ships in Ruby 4.0."

### Slide 13 — Server mode demo
- `rdoc --server` — live-reload documentation preview
- Demo video: edit a file → browser auto-refreshes

### Slide 14 — Server mode details
- `rdoc --server` features
- Zero external dependencies, incremental re-parsing
- Connects to Prism for faster re-parse

### Slide 15 — The parser problem
- RDoc's Ruby parser used Ripper (token-stream based)
- Ripper is slow
- Couldn't handle modern Ruby syntax

### Slide 16 — tompng's rewrites
- Pipeline diagram: where the 3 subsystems sit in RDoc
  - Ruby parser → Prism AST visitor
  - Comment directive parser (`:call-seq:`, `:nodoc:`)
  - Inline formatting engine → structured InlineParser
- 43 PRs over 20 months

### Slide 17 — Bug fix example: `__FILE__`
- Before/after comparison showing how `__FILE__` was rendered
- Before: recognized as `<code>` → broken display
- After: rendered as plain text

### Slide 18 — What the rewrites changed
- Prism benchmark: 0.69s vs 0.97s (Ripper) on 112 files (~30% faster)
- Before/after code: Ripper tokens vs Prism AST visit

### Slide 19 — Markdown in RDoc
- Markdown is the universal format — humans and AI both read and write it
- RDoc markup is Ruby-specific, not widely known
- "If you can write a GitHub README, you can write Ruby documentation"

### Slide 20 — The coupling problem
- Pipeline diagram: Markdown parser and RDoc parser both feed through shared InlineParser
- Every Markdown fix is a two-format fix

### Slide 21 — Example: `~~strikethrough~~`
- Before/after: `~~text~~` → broken in v6.11.0, correct `<del>` now
- Fix touches shared code → must verify RDoc markup still works

### Slide 22 — Bash syntax highlighting
- Before/after: bash code blocks — no highlighting vs proper sh-* tokens

### Slide 23 — C syntax highlighting
- Before/after: C code blocks — no highlighting vs proper c-keyword tokens

### Slide 24 — Inline styling in tables
- Before/after: `` `code` `` in table cells was broken, now works

### Slide 25 — GFM compatibility table
- Feature comparison: GFM vs RDoc v6.11.0 vs RDoc current
- 4 fixed, 1 regressed, 7 still broken in both

### Slide 26 — RBS type signatures
- The `#:` inline annotation syntax
- RDoc extracts and displays in HTML and `ri`

### Slide 27 — RBS in HTML output
- Screenshot: class page with type signatures rendered
- Type names are clickable links to their documentation

---

## Section 3: What's Still Ahead (~8-9 min)

### Slide 28 — RDoc's priority [CONTRIBUTING]
- Better contributing experience
- Target: Ruby's official docs and gem docs
- Make documentation easier to write and maintain

### Slide 29 — Setting good standards [CONTRIBUTING]
- RBS signatures are a start — structured, machine-readable contracts
- We'll revisit supported directives for clarity

### Slide 30 — Better tools for writing docs [CONTRIBUTING]
- For humans: `rdoc --server` (live preview)
- For AI agents: `rdoc -C` (coverage — what's missing)
- For AI agents: `ri --format=markdown` (query docs directly)

### Slide 31 — For consuming documentation [LLM-READY DOCS]
- For humans: Aliki improved the reading experience
- For AI: we evaluated and found nothing proven yet

### Slide 32 — Rustdoc: community and maintainers said no [LLM-READY DOCS]
- RFC #3751 proposed LLM-friendly text output for Rustdoc
- T-rustdoc team: "Very likely not the desired format within 3 months, never mind 3 years"
- Community consensus: "This should be an external tool"
- Footnote: github.com/rust-lang/rfcs/pull/3751

### Slide 33 — ExDoc: shipped it [LLM-READY DOCS]
- ExDoc v0.40.0 (Jan 2026): Markdown output formatter + llms.txt
- Enabled by default — every Elixir project gets it
- First major doc tool to ship AI-oriented output

### Slide 34 — We prototyped llms.txt [LLM-READY DOCS]
- The most complete standard for LLM-friendly docs
- ~10% adoption across 300K domains, zero measurable impact on AI citations
- No major LLM provider officially consumes it
- Footnote: SE Ranking study (seranking.com/blog/llms-txt)

### Slide 35 — RDoc: studying while building the foundation [LLM-READY DOCS]
- We're watching how these approaches play out
- Priority now: make the documentation better at the source
- Any AI-specific format risks being obsolete in months

---

## Section 4: Recap + Close (~2 min)

### Slide 36 — Summary
- AI reads Ruby's docs too now — improving them helps everyone
- RDoc's priority: make docs easier to write and maintain
- The foundation is rebuilt: Prism, Markdown, server mode, RBS, Aliki

### Slide 37 — Try it today
- Contribute to Ruby documentation — it's Markdown now
- Try `rdoc --server` for your own projects
- github.com/ruby/rdoc
- docs.ruby-lang.org

### Slide 38 — Thank you
- Thank tompng (Tomoya Ishida), Shopify Ruby DX team, Ruby committers
- @st0012 (GitHub), @st0012.dev (BlueSky)

---

## Appendix: Research Files

All supporting research is in `research/`:
- `rdoc_prs.md` — 85 PRs in ruby/rdoc since Oct 2025
- `ruby_prs.md` — 41 PRs in ruby/ruby since Oct 2025
- `current_features.md` — Feature state analysis
- `llms_txt_adoption.md` — llms.txt adoption data
- `callseq_vs_rbs.md` — call-seq vs RBS comparison
- `markdown_rdoc_coupling.md` — Markdown/RDoc architectural coupling
- `tompng_prism_work.md` — tompng's contributions
- `tompng_comment_formatting_rewrites.md` — InlineParser replacement details
- `type_sigs_ai_performance.md` — Deep research: types + AI (10 sources, verified)
- `ai_documentation_skills.md` — Documentation tools + AI landscape
- `markdown_for_agents.md` — Markdown for AI agents: approaches and open questions
- `rustdoc_llm_rfc.md` — Rustdoc LLM RFC discussion (rust-lang/rfcs#3751)
- `gfm_comparison_v6110_vs_current.md` — GFM feature comparison with actual HTML output

## Timing Budget

| Section | Time | Slides |
|---------|------|--------|
| 1. The hook | 3-4 min | 10 |
| 2. Here's what we did | ~14-16 min | 17 |
| 3. What's still ahead | ~8-9 min | 8 |
| 4. Recap + close | ~2 min | 3 |
| **Total** | **~28-30 min** | **38** |

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
