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

### Slide 3 — Bold claim
- "The future of Ruby's documentation is about AI"

### Slide 4 — What AI needs (part 1)
- AI likes **clear, accurate documentation**
- Misinformation gets amplified by AI

### Slide 5 — What AI needs (part 2)
- AI likes **Markdown** — it reads and writes it natively
- AI likes **clear intent** — type signatures tell it what code does

### Slide 6 — What AI needs (part 3)
- AI likes **quick, deterministic feedback**
- Coverage checks, missing reference warnings — not "try and see"

### Slide 7 — The twist
- "All of these help human developers too."
- These aren't AI requirements — they're good documentation requirements

### Slide 8 — RDoc wasn't providing these
- Old theme, no live preview, incomplete Markdown, no type info
- Parser couldn't handle modern Ruby

### Slide 9 — So here's what we did
- "...to make RDoc work for us, and our agents"

---

## Section 2: Here's What We Did (~16 min)

### Slide 10 — Aliki theme (quick)
- Before: Darkfish screenshot → After: Aliki screenshot
- Dark mode, mobile, fuzzy search, method signature cards
- "Named after my cat. Ships in Ruby 4.0."

### Slide 11 — Server mode
- `rdoc --server` — live-reload documentation preview
- Demo: edit a file → browser auto-refreshes
- Zero external dependencies, incremental re-parsing

### Slide 12 — The parser problem
- RDoc's Ruby parser used Ripper (token-stream based)
- Couldn't handle modern Ruby syntax
- Parser logic and comment handling tightly coupled

### Slide 13 — tompng's rewrites
- Pipeline diagram: where the 3 subsystems sit in RDoc
  - Ruby parser → Prism AST visitor
  - Comment directive parser (`:call-seq:`, `:nodoc:`)
  - Inline formatting engine → structured InlineParser
- 43 PRs over 20 months

### Slide 14 — What the rewrites changed
- Code example: before/after (e.g., Ripper tokens vs Prism AST visit)
- "Three subsystem rewrites. Invisible to users, foundational for everything else."

### Slide 15 — Why Markdown?
- Markdown is the universal format — humans and AI both read and write it
- RDoc markup is Ruby-specific, not widely known
- "If you can write a GitHub README, you can contribute to Ruby documentation"

### Slide 16 — Markdown: the coupling problem
- Pipeline diagram:
  ```
  Markdown parser ──┐                    ┌─────────────┐
                    ├─► RDoc::Markup ───►│ Shared       │
  RDoc parser    ──┘    nodes with       │ InlineParser │──► HTML
                        RDoc strings     │ & Formatters │
                        inside           └─────────────┘
  ```
- Every Markdown fix is a two-format fix

### Slide 17 — Markdown: concrete example
- `~~strikethrough~~` → `<del>text</del>` as plain string
- SharedInlineParser didn't recognize `<del>` → silently broken
- Fix touches shared code → must verify RDoc markup still works

### Slide 18 — Markdown: what's improved
- Strikethrough, heading anchors, table fixes, syntax highlighting
- GFM spec comparison test suite
- Migration started: `standard_library_md.html` in Ruby 3.4+

### Slide 19 — RBS type signatures
- The `#:` inline annotation syntax
- Example:
  ```ruby
  #: (String name, ?Integer age) -> User
  def create_user(name, age = nil)
  ```
- RDoc extracts and displays in HTML and `ri`

### Slide 20 — RBS in HTML demo
- Screenshot: class page with type signatures rendered
- Type names are clickable links to their documentation

### Slide 21 — AI helped us get here
- RDoc is huge and complex — without dedicated maintainers, change was slow
- tompng and I became active in 2024 — progress, but limited

### Slide 22 — AI accelerated the pace
- Since mid-2025, AI helped me increase my output significantly
- tompng's work was his own — but AI helped me keep up with reviewing it
- "The pace is accelerating. Not because we're working harder, but because we have better tools."

---

## Section 3: What's Still Ahead (~8 min)

### Slide 23 — RDoc's priority
- Better contributing experience
- Target: Ruby's official docs (docs.ruby-lang.org) and gem docs
- Make documentation easier to write and maintain

### Slide 24 — Setting good standards
- RBS signatures are a start — structured, machine-readable contracts
- We'll revisit supported directives for clarity
- Whether users adopt a type checker is their choice — RDoc supports both

### Slide 25 — Better tools for writing docs
- For humans: server mode
- For AI agents: improved CLI
  - `rdoc -C` coverage: what's missing or incorrect
  - `ri --format=markdown`: query Ruby docs directly

### Slide 26 — For consuming documentation
- For humans: Aliki theme improved the reading experience
- For AI: we evaluated and found nothing proven yet

### Slide 27 — We prototyped llms.txt
- The most complete standard for LLM-friendly docs
- 10% adoption across 300k domains, zero measurable impact on AI citations
- No major LLM provider officially consumes it

### Slide 28 — Markdown output for AI?
- No standard for serving Markdown versions of documentation pages
- We considered generating Markdown output from RDoc
- Prioritizing this now creates more risk than reward

### Slide 29 — Rustdoc tried this too
- Rustdoc RFC (rust-lang/rfcs#3751): proposed LLM-friendly text output
- Community rejected it: "This should be an external tool"
- T-rustdoc team: "Very likely not the desired format within 3 months, never mind 3 years"

### Slide 30 — The landscape
- No major doc generator has shipped AI-specific output features
- All AI-docs integration happens at the consumption layer (MCP servers, Dash, DevDocs)
- Doc generators should focus on producing good output
- "If I missed anything in this space, I'd love to hear about it after the talk"

### Slide 31 — Documentation has more leverage now
- docs.ruby-lang.org is what AI models train on and what AI tools reference
- In the AI age, every improvement to Ruby's docs gets amplified

### Slide 32 — Types in docs, not type checking at generation
- Endoh benchmark (March 2026): Ruby is #1 for AI code generation ($0.36/run)
- Adding a type checker at generation time costs 2-3× overhead
- Types already in documentation give AI the information without that cost

### Slide 33 — The honest constraint
- The AI consumption space moves fast
- Nothing is proven effective yet
- We keep the foundation solid and wait for the dust to settle

---

## Section 4: Recap + Close (~2 min)

### Slide 34 — Summary
- In the AI age, documentation has more leverage than ever
- RDoc's priority: make docs easier to write and maintain
- The foundation is rebuilt: Prism, Markdown, server mode, RBS, Aliki

### Slide 35 — Call to action
- Contribute to Ruby documentation — it's Markdown now
- Try `rdoc --server` for your own projects
- Links:
  - github.com/ruby/rdoc
  - docs.ruby-lang.org

### Slide 36 — Thank you
- Thank tompng (Tomoya Ishida), Shopify Ruby DX team, Ruby committers
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
- `type_sigs_ai_performance.md` — Deep research: types + AI (10 sources, verified)
- `ai_documentation_skills.md` — Documentation tools + AI landscape
- `markdown_for_agents.md` — Markdown for AI agents: approaches and open questions
- `rustdoc_llm_rfc.md` — Rustdoc LLM RFC discussion (rust-lang/rfcs#3751)

## Timing Budget

| Section | Time | Slides |
|---------|------|--------|
| 1. The hook | 3-4 min | 9 |
| 2. Here's what we did | ~14-16 min | 13 |
| 3. What's still ahead | ~8-9 min | 11 |
| 4. Recap + close | ~2 min | 3 |
| **Total** | **~28-30 min** | **36** |

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
