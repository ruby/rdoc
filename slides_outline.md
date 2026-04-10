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
- Ruby DX team @Shopify (Ruby & Rails Infrastructure)
- Key collaborator: tompng (Tomoya Ishida)

### Slide 3 — Bold claim
- "The future of Ruby's documentation is about AI"

### Slide 4 — What AI needs from documentation
- AI likes **clear, accurate documentation** — misinformation gets amplified by AI
- AI likes **Markdown** — it can read and write it natively
- AI likes **clear intent** — type signatures tell AI what code does without guessing
- AI likes **quick, deterministic feedback** — coverage checks, missing reference warnings, not "try and see"

### Slide 5 — The twist
- "You know what? All of these help human developers too."
- Clear docs, Markdown, types, fast feedback — these aren't AI requirements, they're good documentation requirements
- AI just raises the stakes

### Slide 6 — The problem
- RDoc was struggling to provide these to humans
- Old theme (Darkfish), no live preview, incomplete Markdown, no type info, parser couldn't handle modern Ruby
- In the AI age, the same RDoc would struggle even more
- "So here's what we did to make RDoc work for us, and our agents"

---

## Section 2: Here's What We Did (~18 min)

> *Walk through each piece of work, framed by what it enables for humans and AI.*

### Slide 7 — Aliki theme (quick)
- Before: Darkfish screenshot → After: Aliki screenshot
- Clear, accurate presentation of documentation
- Dark mode, mobile, fuzzy search, method signature cards
- "Named after my cat. Ships in Ruby 4.0."

### Slide 8 — Server mode (~2 min)
- `rdoc --server` — live-reload documentation preview
- Demo: edit a file → browser auto-refreshes
- Zero external dependencies (Ruby's TCPServer)
- Incremental re-parsing, only changed files
- **Why it matters**: fast feedback loop for doc authors — humans and AI agents both benefit from seeing changes immediately

### Slide 9 — Prism parser: the foundation (~3 min)
- RDoc's Ruby parser used Ripper (token-stream based)
  - Couldn't handle modern Ruby syntax (endless methods, pattern matching, etc.)
  - Parser logic and comment handling tightly coupled
  - Even small bugs were hard to fix
- tompng rewrote it using Prism's AST visitor
  - 20-month effort, now the default
  - Fixes 7+ long-standing issues
- But that's not all — tompng also rewrote:
  - Comment directive parser (`:call-seq:`, `:nodoc:`, etc.)
  - Inline formatting engine (replaced string-replacing AttributeManager with structured InlineParser)
- "Three major subsystem rewrites. Invisible to users, foundational for everything else."
- **Why it matters**: accurate parsing → accurate documentation → AI and humans both get correct information
- **Needs visual aids:**
  - Diagram showing where these 3 subsystems sit in RDoc's pipeline (source → parser → directives → inline formatting → output)
  - Code examples: before/after for each subsystem (e.g., Ripper token stream vs Prism AST visit, old directive double-parse vs new single-pass, string replacement vs structured nodes)
  - Keep it concrete — show a real Ruby snippet going through each stage

### Slide 10 — Markdown support: why it matters (~2 min)
- Markdown is the universal format — humans write it, AI reads and writes it
- RDoc markup is Ruby-specific, not widely known
- "If you can write a GitHub README, you can contribute to Ruby documentation"
- **For AI**: Markdown output is something AI agents can consume directly

### Slide 11 — Markdown: why it took so long
- Pipeline diagram:
  ```
  Markdown parser ──┐                    ┌─────────────┐
                    ├─► RDoc::Markup ───►│ Shared       │
  RDoc parser    ──┘    nodes with       │ InlineParser │──► HTML
                        RDoc strings     │ & Formatters │
                        inside           └─────────────┘
  ```
- Markdown was added ~2011 by reusing RDoc's internal pipeline
- Both parsers produce the same node types, share the same inline parser and formatters
- "Every Markdown fix is a two-format fix. That's why progress is incremental."

### Slide 12 — Markdown: concrete coupling example
- `~~strikethrough~~` → parser outputs `<del>text</del>` as a plain string
- That string feeds into the shared InlineParser
- InlineParser didn't recognize `<del>` → strikethrough silently broken
- Fix requires touching the shared InlineParser → must verify RDoc markup still works

### Slide 13 — Markdown: what's improved
- Strikethrough, heading anchors, table fixes, syntax highlighting
- GFM spec comparison test suite for systematic tracking
- `break_on_newline` enabled by default
- Migration already started: `standard_library_rdoc.html` → `standard_library_md.html` in Ruby 3.4+

### Slide 14 — RBS type signatures: clear intent (~3 min)
- The `#:` inline annotation syntax
- Example:
  ```ruby
  #: (String name, ?Integer age) -> User
  def create_user(name, age = nil)
    # ...
  end
  ```
- RDoc extracts these and displays in HTML output and `ri`
- **Why it matters**: structured, machine-readable signatures — AI knows the types without guessing

### Slide 15 — RBS in HTML demo
- Pre-recorded: class page with type signatures rendered
- Type names linked to their documentation pages

### Slide 16 — The AI accelerator (honest aside, ~2 min)
- RDoc is huge and complex. Without dedicated maintainers, it was impossible to change at pace.
- When tompng and I became active maintainers in 2024, we made progress — but limited
- Since mid-2025, AI capabilities helped me greatly increase my output
  - Writing code, reviewing tompng's PRs, exploring unfamiliar subsystems
- tompng's work was his own — but AI helped me keep up with reviewing it
- "The pace is accelerating. Not because we're working harder, but because we have better tools."

---

## Section 3: What's Still Ahead (~6-7 min)

### Slide 17 — RDoc's position
- We prioritize **better contributing experience**
  - Target: Ruby's official docs (docs.ruby-lang.org) and gem docs
  - Goal: make documentation easier to write and maintain
- Support and promote ways to provide more useful information
  - RBS signatures are a start — structured, machine-readable method contracts
  - We'll revisit all supported directives to set good standards
- Whether users adopt type signatures or a type checker is their choice — RDoc supports both
- `ri` already outputs Markdown (`ri --format=markdown`) — a bridge to AI that exists today

### Slide 18 — For consuming documentation
- **For humans**: we improved the reading experience on the web (Aliki theme)
- **For AI**: we evaluated the options and found nothing proven yet
  - llms.txt: most complete standard for LLM-friendly docs
    - We prototyped it. 10% adoption, zero measurable impact on AI citations
    - No major LLM provider officially consumes it
  - No standard exists for serving Markdown versions of documentation pages
  - We considered generating Markdown output from RDoc
    - Prioritizing this now creates more risk (slowing down generation, complicating internal improvements) than the reward

### Slide 19 — Other communities are asking the same questions
- Rustdoc RFC (rust-lang/rfcs#3751): proposed LLM-friendly text output for `cargo doc`
  - Community rejected it: "This should be an external tool"
  - T-rustdoc team: "Very likely it is not the desired format within 3 months, never mind 3 years"
  - Key argument: AI changes faster than language toolchain processes
- No major doc generator has shipped AI-specific output features
- All current AI-docs integration happens at the consumption layer (MCP servers, tools like Dash/DevDocs), not the generation layer
- Our conclusion aligns: doc generators should focus on producing good output, let the ecosystem build consumption tools

### Slide 20 — What we're doing for AI, concretely
- In the AI age, documentation has more leverage — especially core and library docs
  - docs.ruby-lang.org is what AI models train on and what AI tools reference
- RDoc can make contributing and maintaining docs easier for both humans and AI:
  - **Setting good standards**: RBS display is a start. Revisiting directives for clarity.
  - **Better authoring tools**: server mode for humans. Improved CLI for AI agents.
    - `rdoc -C` coverage: helps AI know what's missing/incorrect (PR #1659)
    - `ri --format=markdown`: AI agents can query Ruby docs directly
  - **Endoh benchmark** (March 2026): Ruby is already #1 for AI code generation ($0.36/run)
    - Adding a type checker at generation time costs 2-3× overhead
    - Types already in documentation give AI the information without that cost
- The AI consumption space moves fast and nothing is proven effective yet
- So we keep the foundation solid and wait for the dust to settle

---

## Section 4: Recap + Close (~2 min)

### Slide 21 — Summary
- In the AI age, documentation has more leverage than ever
- RDoc's priority: make docs easier to write and maintain
  - Prism, Markdown, server mode, RBS, Aliki — the foundation is rebuilt
- For AI: we evaluated, we're honest about what works, and we build good foundations
- "The best way to prepare for the future is to get the present right"

### Slide 22 — Call to action
- Contribute to Ruby documentation — it's Markdown now!
- Try `rdoc --server` for your own projects
- Links:
  - github.com/ruby/rdoc
  - docs.ruby-lang.org
  - github.com/st0012/ruby-skills

### Slide 23 — Thank you
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
| 1. The hook | 3-4 min | 6 |
| 2. Here's what we did | ~16-18 min | 10 |
| 3. What's still ahead | ~6-7 min | 4 |
| 4. Recap + close | ~2 min | 3 |
| **Total** | **~28-30 min** | **~23** |

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
