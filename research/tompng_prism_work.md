# tompng's Prism Migration Work in ruby/rdoc

## Overview

tompng (Tomoya Ishida) is a MEMBER-level contributor to ruby/rdoc and the primary author of the Ripper-to-Prism parser migration. This was a complete rewrite of RDoc's Ruby parser, spanning ~20 months from initial PR to becoming the default. tompng has 43 total PRs in ruby/rdoc (33 since 2025, 10 before that).

## The Prism Migration Timeline

### Phase 1: Initial Implementation (Jul 2024)

**[#1144](https://github.com/ruby/rdoc/pull/1144) - Add new ruby parser that uses Prism** (merged 2024-07-31)
- +3042/-7 lines across 6 files. Added `lib/rdoc/parser/prism_ruby.rb`.
- Completely rewrote the Ruby parser using Prism's AST visitor pattern (`Prism::Visitor`) instead of Ripper's token-stream approach.
- Gated behind `ENV['RDOC_USE_PRISM_PARSER']` -- opt-in only.
- Milestone: v6.8.0.

**Why the rewrite was needed:**
- The old `RDoc::Parser::Ruby` used Ripper (token-stream based). Parser logic and comment handling were tightly coupled, making even small bugs hard to fix.
- Modern Ruby syntax was unsupported: endless methods (`def foo() = 1`), semicolon-separated includes (`class A; include M; end`).
- Many long-standing parsing bugs in the old parser.

**How PrismRuby works:**
- Uses `Prism::Visitor` to traverse the AST.
- Comments are classified into "consecutive comments" (linked to next non-blank line) and "modifier comments" (inline on the same line as code).
- Maintains a `module_nesting` stack during class/module traversal.
- Handles metaprogramming comments (starting with `##\n`) and RDoc directives.

### Phase 2: Bug Fixes and Compatibility (Jan-Feb 2025)

**[#1267](https://github.com/ruby/rdoc/pull/1267) - Fix prism_ruby superclass resolve order** (merged 2025-01-03)
- Fixed `SystemStackError` when running `RDOC_USE_PRISM_PARSER=1 make html` in ruby/ruby.
- Root cause: `class Cipher < Cipher; end` inside `OpenSSL::Cipher` caused recursive superclass resolution. Prism parser now resolves superclass before adding the class definition, matching Ruby's evaluation order.

**[#1284](https://github.com/ruby/rdoc/pull/1284) - Reduce document difference between parsers** (merged 2025-02-02)
- +294/-54 lines. Fixed ~15 categories of bugs/incompatibilities between the two parsers.
- Fixed: singleton class constant scoping, `:nodoc:` on multi-line parameter lists, AST traverse order for conditional method definitions, wrong includes from anonymous modules, superclass display for `DelegateClass()`, wrong module nesting for `String.include(Module.new {...})`, and more.
- Included a comprehensive diff of generated HTML for ruby/ruby between the two parsers.

### Phase 3: Architecture Cleanup (Jan 2026)

**[#1580](https://github.com/ruby/rdoc/pull/1580) - Remove module nesting hack from PrismRuby** (merged 2026-02-03)
- PrismRuby previously stored module nesting information in `context.parent` (a hack). Now all constant/module/class paths are resolved by the parser itself.
- Resolves include/extend module names before adding them to the context.

### Phase 4: Becoming the Default (Jan-Feb 2026)

**[#1581](https://github.com/ruby/rdoc/pull/1581) - Change default ruby parser to RDoc::Parser::PrismRuby** (merged 2026-02-17)
- The pivotal PR. PrismRuby is now the default parser.
- Fixes issues: #398, #782, #816, #1555, #885, #1373, #1553.
- Labeled as `breaking-change`. Old parser available via `RDOC_USE_RIPPER_PARSER=1`.
- "Although generated HTML has huge difference, many many bugs are fixed."

### Phase 5: Post-Switch Fixes (Feb 2026)

**[#1595](https://github.com/ruby/rdoc/pull/1595) - Ignore visibility/attr/module_function within blocks** (merged 2026-02-09)
- Fixes incorrect visibility handling inside `Module.new do ... end` blocks (found while generating docs for rails/rails).

**[#1596](https://github.com/ruby/rdoc/pull/1596) - Fix visit_call_node visiting arguments twice** (merged 2026-02-06)

**[#1621](https://github.com/ruby/rdoc/pull/1621) - Support constant assign parsed before class/module definition** (merged 2026-02-22)
- Fixes a doc-coverage check failure in ruby/ruby.

### Still Open / In Progress

**[#1478](https://github.com/ruby/rdoc/pull/1478) - Tokenizer for syntax highlighting using Prism** (open, draft, since 2025-11-29)
- Aims to replace `RDoc::Parser::RipperStateLex` with a Prism-based tokenizer for syntax highlighting.
- This is the remaining Ripper dependency: parsing uses Prism, but syntax highlighting still uses Ripper.

**[#1610](https://github.com/ruby/rdoc/pull/1610) - Lexical scope document control** (open, draft, since 2026-02-13)
- Moves `:startdoc:`, `:stopdoc:`, `:enddoc:`, `:nodoc:` handling from `CodeObject` into the PrismRuby parser itself. Lexical scoping for document control directives.

## Other Significant Contributions (Non-Prism)

### Parsing Infrastructure Rewrites

**[#1149](https://github.com/ruby/rdoc/pull/1149) - Change comment directive parsing** (opened 2024-08-04, merged 2025-11-13)
- Massive overhaul of how RDoc parses comment directives (`:call-seq:`, `:yields:`, `:nodoc:`, etc.).
- Old system: `@preprocess.handle` parsed, removed directives, and processed code objects simultaneously -- leading to double-parsing bugs.
- New system: parse once, extract directives as structured data, then apply.
- +650/-213 lines across 15 files.

**[#1559](https://github.com/ruby/rdoc/pull/1559) - Replace attribute_manager with new inline-format parser** (merged 2026-01-19)
- Eliminated `RDoc::Markup::AttributeManager` (string-replacing/macro-based inline parser) and replaced with a proper structured parser.
- Fixed dozens of long-standing bugs with tidylinks, nested formatting, backslash escapes, and `<b>+code+</b>` combinations.
- +1335/-1819 lines across 33 files (net reduction in code!).

**[#1210](https://github.com/ruby/rdoc/pull/1210) - Stop accepting Document objects as CodeObject#comment** (merged 2025-01-28)

### Aliki Theme Work (Nov 2025)

6 PRs improving the Aliki HTML theme:
- #1454: Scroll margin for headings
- #1455: Fix nav padding
- #1456: Stable TOC active state calculation
- #1458: Fix singleton class module name display
- #1459: TOC scrollable area height
- #1462: Modernize aliki.js
- #1469: Smooth scroll for heading links
- #1486: Fix nav width restriction

### Misc Bug Fixes

- #1039: Delay DidYouMean until NotFoundError#message called (2023)
- #1082: Fix ri completion (2024, merged 2025)
- #1130: Fix module recursive lookup (2024)
- #1147: Fix flaky test (2024)
- #1184: Fix ToRdoc#accept_table (2024)
- #1244: Fix RubygemsHook attribute (2024)
- #1316: Fix module_function test target (2025)
- #1323: Refactor markdown image/link parsing (2025)
- #1337: Fix README example (2025)
- #1347: Fix rubygems hook with --ri option (2025)
- #1425: JRuby compatibility fix (2025)
- #1491: Fix call-seq dedup for aliased names (2025)
- #1515: Fix class/module alias document naming (2025)
- #1531: Fix comment_location for merged ClassModule (2025)
- #1532: Simplify newline handling in TokenStream (2025)
- #1552: Remove italic/bold inside codeblocks (2026)
- #1575: Implement escapes in Markdown-to-RDoc conversion (2026)
- #1611: rubocop autocorrect (2026)

## Summary Statistics

| Category | Count |
|----------|-------|
| Total PRs | 43 |
| Merged | 37 |
| Open (draft) | 4 |
| Closed unmerged | 2 |
| Prism-related (direct) | ~8 |
| Other parser rewrites | 2 major |
| Aliki theme | 6 |
| Bug fixes | ~18 |

## Key Takeaways

1. **Complete Ripper-to-Prism migration for Ruby parsing is done.** PrismRuby is the default since Feb 2026. The old Ripper parser is still available as a fallback via env var.

2. **Syntax highlighting is the last Ripper holdout.** PR #1478 (draft) aims to replace `RipperStateLex` with Prism-based tokenization.

3. **The migration fixed 7+ tracked issues** and dozens of undocumented bugs related to modern Ruby syntax, comment handling, module nesting, visibility, cross-references, and more.

4. **tompng's work goes far beyond Prism.** They also rewrote the comment directive parser (#1149) and the inline formatting engine (#1559) -- both were architecturally problematic subsystems that accumulated bugs for years.

5. **Approach:** methodical, incremental. First added PrismRuby as opt-in, then spent months fixing edge cases and reducing output differences, then flipped the default, then continued fixing post-switch issues.

6. **tompng has MEMBER-level access** to ruby/rdoc and self-merges many of their PRs.
