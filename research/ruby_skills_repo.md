# st0012/ruby-skills Repository Analysis

## Overview

- **Repository:** <https://github.com/st0012/ruby-skills>
- **Description:** Claude Code plugins for Ruby development
- **Author:** Stan Lo (st0012)
- **License:** MIT
- **Primary Language:** Shell
- **Created:** 2026-01-16
- **Last Updated:** 2026-04-05
- **Stars:** 109
- **Forks:** 6
- **Current Version:** 0.6.0

A Claude Code plugin marketplace that bundles three skills aimed at making Claude more effective in Ruby projects. It detects the user's Ruby version manager, provides authoritative documentation sources, and prevents common test framework API mix-ups.

## Installation

```bash
claude plugin marketplace add st0012/ruby-skills
claude plugin install ruby-skills@ruby-skills
```

No per-project configuration required. The plugin activates automatically via a `SessionStart` hook when it detects a Ruby project (presence of `Gemfile`, `.ruby-version`, `.tool-versions`, or `.mise.toml`).

## Skills (3 total)

### 1. `ruby-version-manager`

Detects the project's Ruby version manager and activates it before every shell command. This works around Claude Code's non-persistent shell by chaining the activation command with every Ruby invocation.

- **Supported managers:** chruby, rbenv, rvm, asdf, mise, rv, shadowenv
- **Version sources:** `.ruby-version`, `.tool-versions`, `.mise.toml`, `Gemfile`
- **Key files:** `detect.sh`, `detect-all-managers.sh`, `set-preference.sh`
- **Handles edge cases:**
  - Multiple managers installed (prompts user for preference)
  - Missing Ruby version (offers to install)
  - No version specifier (suggests latest installed)
  - CI/Docker environments (uses system Ruby directly)

Detection logic is based on Ruby LSP's VS Code extension by Shopify.

### 2. `ruby-resource-map`

Points Claude to authoritative documentation sources and blocks known-bad ones (ruby-doc.org, apidock.com).

Covers:
- Version-specific docs for Ruby 3.2, 3.3, 3.4, 4.0, and master
- Core vs bundled vs default gem distinctions (links to stdgems.org)
- Testing framework docs (minitest, test-unit)
- Typing ecosystem: Sorbet (RBI), RBS, Tapioca, Spoom, Steep
- RBS inline comments (`#:` syntax) with link to Sorbet docs

### 3. `ruby-test-frameworks`

A divergence reference for minitest vs test-unit. These frameworks have deceptively similar APIs with critical naming differences that cause `NoMethodError` at runtime.

Covers:
- Assertion naming mismatches (`assert_raises` vs `assert_raise`, `refute_*` vs `assert_not_*`)
- Assertions unique to each framework
- CLI flag differences for test selection
- Lifecycle/hook differences (`before_setup`/`after_teardown` vs `startup`/`shutdown`/`cleanup`)
- Skip/pending/omit semantics
- Rails-specific aliases that blur the boundary
- minitest 6 breaking changes

RSpec is intentionally excluded -- its API is distinct enough that LLMs rarely confuse it with others.

## Architecture

```
ruby-skills/                            # Marketplace root
+-- .claude-plugin/marketplace.json     # Marketplace definition (v0.6.0)
+-- plugins/ruby-skills/
    +-- .claude-plugin/plugin.json      # Plugin metadata
    +-- hooks/
    |   +-- hooks.json                  # SessionStart hook registration
    |   +-- session-start.sh            # Detects Ruby projects, injects skill context
    +-- skills/
        +-- ruby-version-manager/
        |   +-- SKILL.md               # Full skill instructions
        |   +-- detect.sh              # Version manager detection
        |   +-- detect-all-managers.sh  # Multi-manager detection
        |   +-- set-preference.sh       # Store user preference
        +-- ruby-resource-map/
        |   +-- SKILL.md               # Authoritative resource map
        +-- ruby-test-frameworks/
            +-- SKILL.md               # minitest vs test-unit divergences
```

The `session-start.sh` hook fires on startup/resume/clear/compact. It checks for Ruby project markers, reads the version-manager and resource-map SKILL.md files, and injects their content as `additionalContext` into the session.

## RDoc-Related Content

There is **no dedicated RDoc skill**. RDoc is only referenced tangentially:

- The `ruby-resource-map` skill links to `standard_library_rdoc.html` for Ruby 3.2 and 3.3 (the older URL scheme that used RDoc-generated pages).
- For Ruby 3.4+, the links changed to `standard_library_md.html`, reflecting the switch from RDoc to Markdown for standard library documentation pages.
- No skill covers RDoc usage, configuration, markup syntax, or documentation generation.

This represents a potential gap -- a skill that teaches Claude how to write good RDoc comments, use RDoc markup correctly, or generate documentation with RDoc could be valuable.

## Recent Activity

### Commits (latest)

| Date | Summary |
|------|---------|
| 2026-04-05 | Add ruby-test-frameworks skill and testing references |
| 2026-04-04 | Remove ruby-lsp plugin (now supported natively by Claude Code) |
| 2026-04-04 | Expand skill descriptions in README |
| 2026-01-24 | Simplify ruby-version-manager skill |
| 2026-01-22 | Add ruby-resource-map skill |
| 2026-01-18 | Support detecting version identifier from parent folder |
| 2026-01-17 | Initial ruby-lsp plugin |

### Pull Requests

| # | Title | State | Author | Date |
|---|-------|-------|--------|------|
| 10 | Add ruby-test-frameworks skill | MERGED | st0012 | 2026-04-04 |
| 9 | Remove ruby-lsp plugin | MERGED | st0012 | 2026-04-04 |
| 8 | fix(ruby-lsp): handle exec-style version managers | CLOSED | douglas | 2026-03-12 |
| 6 | Add rubocop-linting skill | OPEN | thomaspmurphy | 2026-02-04 |
| 5 | Shorten readme | MERGED | st0012 | 2026-01-24 |
| 4 | Add ruby-resource-map skill | MERGED | st0012 | 2026-01-22 |
| 2 | Support detecting version from parent folder | MERGED | st0012 | 2026-01-18 |
| 1 | Add ruby-lsp plugin | MERGED | st0012 | 2026-01-17 |

### Open Issues

| # | Title | Author | Date |
|---|-------|--------|------|
| 7 | ruby-lsp plugin: .lsp.json validation fails + launch script broken with mise | dexory-github-bot | 2026-02-28 |
| 3 | Feature/Documentation Request: compatibility with other tools besides Claude Code | brandonzylstra | 2026-01-20 |

### Notable

- The ruby-lsp plugin was **removed** in PR #9 (2026-04-04) because Claude Code now supports it natively. Issue #7 and closed PR #8 are now moot.
- PR #6 (rubocop-linting skill) is still open from an external contributor (thomaspmurphy). It adds `detect.sh` and `run.sh` for RuboCop with integration into the version-manager skill.
- Issue #3 asks about compatibility with tools other than Claude Code (Cursor, Windsurf, etc.).

## Key Takeaways for RDoc Talk

1. **Proof of concept for Ruby ecosystem skills:** The repo demonstrates that focused, domain-specific skills (version management, documentation sources, test framework nuances) meaningfully improve LLM behavior in Ruby projects.

2. **Documentation quality matters for LLMs:** The `ruby-resource-map` skill exists specifically because Claude was hallucinating APIs and using outdated docs. Blocking bad sources (ruby-doc.org, apidock.com) and pointing to authoritative ones improved results. This is directly relevant to RDoc's role as the documentation generator for Ruby's own docs.

3. **The standard_library URL change:** The resource map captures the shift from `standard_library_rdoc.html` (Ruby 3.2-3.3) to `standard_library_md.html` (Ruby 3.4+), reflecting RDoc's Markdown support improvements.

4. **No RDoc authoring skill exists:** There is no skill teaching Claude how to write good RDoc documentation, use RDoc directives correctly, or avoid common RDoc markup mistakes. This could be a compelling addition, especially given RDoc's role in generating the official Ruby documentation that LLMs consume.

5. **Community interest:** 109 stars and external contributions show demand for Ruby-specific LLM tooling. The repo has been actively maintained with regular skill additions.
