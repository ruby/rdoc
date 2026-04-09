# Stan Lo - Conference Talk History & Presentation Style

## Complete Talk List (Chronological)

### 1. RubyKaigi 2017 - "I quit my job to write my own language: Goby"
- **Conference:** RubyKaigi 2017, Hiroshima, Japan (September 18-20, 2017)
- **Bio at the time:** Ruby/Rails developer, cat and boxing lover, junior language designer
- **Topic:** Personal journey of creating the Goby programming language (Ruby-inspired, written in Go). Started by following a book to write the "monkey" language, then gradually expanded -- added a VM and compiler inspired by Ruby 1.9, created file and HTTP libraries, built a web server -- until deciding to quit his job to develop Goby full-time.
- **Key quote:** "That day, for no particular reason, I decided to write my own language."
- **Video:** https://www.youtube.com/watch?v=GRNlTWzoC74
- **Slides:** https://www.slideshare.net/LoStan/goby-and-its-compiler
- **Presentation page:** https://rubykaigi.org/2017/presentations/_st0012.html

### 2. RubyKaigi 2018 - "What would your own version of Ruby look like?"
- **Conference:** RubyKaigi 2018, Sendai, Japan (May 31 - June 2, 2018)
- **Bio at the time:** Ruby/Rails developer at Ticketsolve, Goby language developer
- **Topic:** Explored what developers might change about Ruby if designing their own version. Used the Goby language as a case study to discuss language design choices, philosophy, and trade-offs. Discussed how Goby differs from Ruby through distinct design decisions and unique features.
- **Slides:** Available on SlideShare
- **Video:** Available on RubyKaigi YouTube channel
- **Presentation page:** https://rubykaigi.org/2018/presentations/_st0012.html

### 3. RubyKaigi 2022 - "ruby/debug - The best investment for your productivity"
- **Conference:** RubyKaigi 2022 (September 8, 2022)
- **Duration:** 26 minutes
- **Bio at the time:** Senior developer at Shopify, major contributor to Ruby debugger, Ruby DX Team
- **Topic:** Demonstrated three powerful debugging techniques using ruby/debug: step-debugging, frame navigation, and breakpoint commands. Showed how combining these techniques reduces context switching. Demonstrated scriptable breakpoints to automate debugging workflows.
- **Video:** https://youtu.be/gseo4vdmSjE
- **Slides:** https://st0012.dev/assets/slides/2022-09-08-rubykaigi.pdf (also on GitHub: st0012/slides)
- **Presentation page:** https://rubykaigi.org/2022/presentations/_st0012.html

### 4. LRUG (London Ruby User Group) November 2022 - "ruby/debug - The best investment for your productivity"
- **Conference:** LRUG, November 14, 2022
- **Topic:** Same material as RubyKaigi 2022, adapted for the meetup format. Demonstrated the same 3 debugging techniques (step-debugging, frame navigation, breakpoint commands) and scriptable breakpoints.
- **Video:** MP4 recording available via LRUG
- **Slides:** https://st0012.dev/assets/slides/2022-11-14-lrug.pdf
- **LRUG page:** https://lrug.org/meetings/2022/november/

### 5. RubyKaigi 2023 - "Build a mini Ruby debugger in under 300 lines"
- **Conference:** RubyKaigi 2023, Matsumoto, Japan (May 11, 2023)
- **Duration:** 25 minutes
- **Topic:** Live-coded / walked through building a functional Ruby debugger from scratch in under 300 lines. Covered TracePoint, binding manipulation, and architecture decisions behind ruby/debug. Used a Fibonacci implementation as the running example throughout demos.
- **Key learning outcomes:** Running programs with debugger, setting breakpoints, stepping through code, all in under 300 lines.
- **Video:** https://youtu.be/7uLFVL2KNXo
- **Slides:** https://st0012.dev/assets/slides/2023-05-11-rubykaigi.pdf (also on GitHub: st0012/slides)
- **Presentation page:** https://rubykaigi.org/2023/presentations/_st0012.html

### 6. Ruby World Conference 2025 - RubyPrize 2025 Acceptance Talk
- **Conference:** Ruby World Conference, November 6, 2025
- **Topic:** RubyPrize acceptance speech. Content details not fully public yet.
- **Slides:** https://st0012.dev/assets/slides/2025-11-06-ruby-world-conference.pdf (also on GitHub: st0012/slides)
- **Video:** Not yet published

### 7. RubyKaigi 2026 - "The future of Ruby documentation" (UPCOMING)
- **Conference:** RubyKaigi 2026, Hakodate, Hokkaido (April 22-24, 2026)
- **Scheduled:** Day 2 (April 23), 17:20-17:50, Large Hall
- **Duration:** 30 minutes
- **Language:** English
- **Topic:** Ruby documentation's biggest update in years. Three key initiatives: (1) transitioning from RDoc markup to GitHub Flavored Markdown, (2) embedding RBS type signatures into docs, (3) preparing documentation for AI integration with LLM-compatible formats and agent tooling.
- **Presentation page:** https://rubykaigi.org/2026/presentations/_st0012.html

## Years NOT Speaking at RubyKaigi

- **2019, 2020, 2021** - No RubyKaigi talks (2020/2021 were pandemic years)
- **2024** - Not a speaker at RubyKaigi 2024
- **2025** - Not a speaker at RubyKaigi 2025

## Podcast Appearances

- **Code and the Coding Coders who Code it, Episode 43** - Discussed his journey from Taiwan to London, work on debug gem and IRB, Ruby LSP, Sorbet/Prism integration, and maintaining Ruby documentation. https://podcast.drbragg.dev/episodes/episode-43-stan-lo/

## Slides Repository

All slide decks are hosted on GitHub: https://github.com/st0012/slides
- `2022-09-08-rubykaigi/`
- `2022-11-14-lrug/`
- `2023-05-11-rubykaigi/`
- `2025-11-06-ruby-world-conference/`

(2017 and 2018 slides were on SlideShare, predating the GitHub repository.)

---

## Presentation Style Analysis

### Talk Structure Patterns

1. **"Build-something-from-scratch" format** (2017, 2023): Stan's strongest talks walk the audience through building something step by step. The 2017 Goby talk traced the journey of building an entire language; the 2023 debugger talk built a functional debugger from scratch. This "let's build it together" approach demystifies complex internals.

2. **Practical demo-driven** (2022): The ruby/debug talk was structured around demonstrating 3 specific techniques, then showing how they compose together. Not theoretical -- shows real workflows.

3. **Personal narrative arc** (2017, 2018): Early talks used personal storytelling ("I quit my job...") as the backbone. The journey provides emotional engagement alongside the technical content.

### Distinctive Characteristics

- **Accessibility focus:** Makes complex internals (debugger architecture, language design, documentation systems) approachable. Titles like "in under 300 lines" set a clear, achievable scope.
- **Running examples:** Uses a single concrete example (Fibonacci in the debugger talk) throughout the entire presentation, building features incrementally against the same code.
- **Humor and personality:** The 2017 talk had a Forrest Gump-style recurring line ("That day, for no particular reason..."). Lighthearted tone even on technical topics.
- **Pragmatic framing:** Talks are pitched as "here's how this helps you" rather than "here's how it works." The 2022 title literally says "best investment for your productivity."
- **Compact scope:** Talks typically cover one tool or concept in depth rather than surveying multiple topics. 25-30 minute format.

### Topic Evolution

| Era | Focus | Role |
|-----|-------|------|
| 2017-2018 | Goby language design | Independent developer / Ticketsolve |
| 2022-2023 | ruby/debug debugger | Shopify Ruby DX Team, debugger contributor |
| 2025-2026 | RDoc / Ruby documentation | Shopify Ruby DX Team, RDoc maintainer, Ruby committer |

Each era reflects his current primary open-source focus. The 2026 talk represents a natural evolution as he's now the RDoc maintainer pushing major modernization.

### What Makes His Talks Work

1. **He builds the thing he's talking about** -- whether it's a language, a debugger, or a documentation system. This gives him deep authority and lets him explain "why" not just "what."
2. **Clear promise in the title** -- "in under 300 lines," "the best investment for your productivity," "the future of Ruby documentation." Audience knows exactly what they'll get.
3. **Progressive complexity** -- starts simple, adds features one at a time, ends with a complete working system.
4. **Developer empathy** -- frames everything in terms of developer pain points and workflows, not abstract architecture.

---

## Relevant Blog Posts (st0012.dev)

These posts provide context for his expertise and how he communicates technical ideas in writing:

- **ruby/debug cheatsheet** (Sep 2022) - https://st0012.dev/2022/09/08/ruby-debug-cheatsheet/
- **Setup ruby/debug with VSCode** (Aug 2022) - https://st0012.dev/2022/08/08/setup-ruby-debug-with-vscode/
- **From byebug to ruby/debug** (Aug 2022) - https://st0012.dev/2022/08/08/from-byebug-to-ruby-debug/
- **What's new in Ruby 3.2's IRB?** (Dec 2022) - https://st0012.dev/2022/12/09/whats-new-in-ruby-3-2-irb/
- **A RDoc Maintainer's View on Ruby's Documentation** (Nov 2024) - https://st0012.dev/2024/11/02/a-rdoc-maintainer-s-view-on-ruby-s-documentation/
- **Ruby 3.4 Documentation: A Step Towards Better Ruby Documentation** (Dec 2024) - https://st0012.dev/2024/12/26/ruby-3-4-docs/
- **My RDoc roadmap for 2026** (Jan 2026) - https://st0012.dev/2026/01/12/my-rdoc-roadmap-for-2026/
- **Ruby Skills: Teaching Claude Code About Ruby's Tooling** (Jan 2026) - https://st0012.dev/2026/01/24/ruby-skills-teaching-claude-code-about-ruby-tooling-and-ecosystem/
- **My Ruby Debugging Tips in 2025** (Mar 2025) - https://st0012.dev/2025/03/13/my-ruby-debugging-tips-in-2025/
- **AI and Open Source: A Maintainer's Take** (Dec 2025) - https://st0012.dev/2025/12/30/ai-and-open-source-a-maintainer-s-take-end-of-2025/
