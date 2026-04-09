# Stan Lo (st0012) -- ruby/rdoc Pull Requests Since October 2025

Total: 85 PRs (67 merged, 5 closed unmerged, 13 open)

---

## Major Feature PRs

### #1432 -- New theme: "Aliki" (MERGED, 2025-10-12 -> 2025-11-15)
- **What:** Brand-new HTML documentation theme to replace Darkfish.
- **Key changes:** 3-column layout, dark mode toggle, right-side table of contents, improved search UI, better mobile design, code paste support. +3074/-11 across 29 files.
- **Named after Stan's cat.**

### #1502 -- Change the default theme to Aliki (MERGED, 2025-12-15 -> 2025-12-17)
- **What:** Makes Aliki the default generator instead of Darkfish.
- **Key changes:** Updated default generator config. +302/-27 across 12 files.

### #1504 -- Rebuild Aliki's searching mechanism (MERGED, 2025-12-16 -> 2025-12-18)
- **What:** Custom search index and improved ranking algorithm for Aliki.
- **Key changes:** Own search index (`js/search_data.js`) instead of shared JsonIndex. Case-sensitive ranking (lowercase -> methods, uppercase -> classes). Type badges in results. Constants included in search. +1376/-18 across 14 files.

### #1620 -- Add server mode with live reload (`rdoc --server`) (MERGED, 2026-02-21 -> 2026-03-14)
- **What:** `rdoc --server[=PORT]` for live-preview documentation with auto-refresh on source changes.
- **Key changes:** New `RDoc::Server` using Ruby's `TCPServer` (no WEBrick). Thread-per-connection. Background file watcher polling mtimes. Incremental re-parse. In-memory page cache. JS polling `/__status` for live reload. `Store#remove_file` and `Store#clear_file_contributions` for surgical re-parsing. `RDoc::Servlet` moved to `RDoc::RI::Servlet`. +1080/-98, 16 files.

### #1665 -- Display RBS type signatures in documentation (OPEN/DRAFT, 2026-03-30)
- **What:** Extract `#:` inline RBS annotations and display type signatures in HTML and RI output.
- **Key changes:** Parse `#:` annotations from comments, load types from `sig/` via `RBS::EnvironmentLoader`, validate via `RBS::Parser`, server-side type name linking using RBS AST locations, Aliki theme integration, `ri` terminal output. Adds `rbs >= 4.0.0` dependency. Marshal v4. +774/-39, 21 files.

---

## Aliki Theme Improvements (all MERGED)

| PR | Title | Date | Key Changes |
|----|-------|------|-------------|
| #1457 | Add classes/modules list to class page sidebar | 2025-11-18 | Sidebar navigation for class pages |
| #1453 | Set default overflow wrap on mobile | 2025-11-16 | Prevent horizontal overflow on mobile |
| #1460 | Remove unnecessary CSS variable declarations | 2025-11-19 | CSS cleanup |
| #1463 | Add stylelint and update CSS | 2025-11-19 -> 2025-11-21 | Linting infrastructure for CSS |
| #1465 | Improve header links | 2025-11-22 | Better header link styling |
| #1466 | Improve light mode link colors | 2025-11-22 | Color improvements for light theme |
| #1471 | Add C syntax highlighting with custom JS highlighter | 2025-11-23 -> 2025-11-25 | C code highlighting without external deps |
| #1472 | Allow customizing Aliki's footer | 2025-11-23 -> 2025-11-25 | Configurable footer content |
| #1476 | Add version query string for cache busting | 2025-11-27 -> 2025-11-28 | Assets get version param to bust caches |
| #1485 | Improve main sidebar | 2025-12-04 -> 2025-12-06 | Better sidebar layout/UX |
| #1487 | Fix source code styling issues | 2025-12-07 | Source code display fixes |
| #1505 | Improve Aliki visuals | 2025-12-16 -> 2025-12-17 | General visual polish |
| #1508 | Fix path links in footers | 2025-12-18 | Footer link corrections |
| #1512 | Fix search dropdown behaviour | 2025-12-19 -> 2025-12-22 | Search UI interaction fixes |
| #1513 | Reduce sidebar list item padding | 2025-12-20 -> 2025-12-21 | Tighter sidebar spacing |
| #1516 | Change sidebar hiding strategy to avoid mobile flickering | 2025-12-21 -> 2025-12-22 | Mobile sidebar animation fix |
| #1603 | Add unique IDs to section headings | 2026-02-08 -> 2026-02-09 | Anchor links for sections |
| #1669 | Style method entries as signature cards | 2026-04-02 -> 2026-04-09 | Method signatures get card-style display |

---

## Markdown / Markup Improvements (all MERGED)

| PR | Title | Date | Key Changes |
|----|-------|------|-------------|
| #1538 | Improve code block language detection | 2026-01-01 | Better fenced code block lang detection |
| #1540 | Support GitHub-style heading anchors and link references | 2026-01-03 -> 2026-01-04 | GitHub-compatible `#heading-anchor` links |
| #1541 | Fix Markdown strikethrough not rendering | 2026-01-04 | `~~text~~` now works in HTML output |
| #1548 | Align strikethrough with GitHub Markdown | 2026-01-05 | GFM-compatible strikethrough behavior |
| #1551 | Allow backticks to quote text in RDoc markup too | 2026-01-06 -> 2026-01-07 | Backtick quoting in RDoc (not just Markdown) |
| #1536 | Prevent style rendering in code blocks | 2025-12-31 -> 2026-01-01 | HTML/CSS inside code blocks no longer rendered |
| #1544 | Highlight bash commands | 2026-01-04 -> 2026-01-19 | Shell syntax highlighting |
| #1542 | Rebuild RDoc markup documentation | 2026-01-04 | Updated markup reference docs |
| #1550 | Add comparison with GitHub Flavored Markdown spec | 2026-01-06 -> 2026-04-04 | GFM compatibility reference/tests |
| #1626 | Fix markdown table parser consuming lines without pipes | 2026-02-26 -> 2026-02-27 | Table parser no longer eats non-table lines |
| #1676 | Preserve `#` prefix for unresolved cross-references | 2026-04-09 | Unresolved refs keep their `#` prefix |

---

## Bug Fixes (all MERGED)

| PR | Title | Date | Key Changes |
|----|-------|------|-------------|
| #1529 | Fix comment location marshalling in ClassModule | 2025-12-24 | Marshal serialization fix for comment locations |
| #1599 | Fix `accept_table` with incomplete rows | 2026-02-07 | Table parsing crash fix |
| #1602 | Fix broken legacy rdoc-ref labels and duplicate heading IDs | 2026-02-07 -> 2026-02-09 | Cross-reference and heading ID fixes |
| #1646 | Don't auto-link to non-text source files in cross-references | 2026-03-14 -> 2026-03-21 | Stop linking to binary/non-text files |
| #1647 | Fix server mode live reload for C files | 2026-03-15 -> 2026-03-16 | C file changes now trigger reload |
| #1649 | Fix deadlock on Ctrl+C in server mode | 2026-03-16 | Server shutdown deadlock fix |
| #1657 | Fix encoding error when C parser reads external source files | 2026-03-22 | Encoding fix for C parser |
| #1671 | Fix page links returning 404 in server mode | 2026-04-04 -> 2026-04-09 | Server mode routing fix for page files |
| #1675 | Fix broken sidebar links for chained class aliases | 2026-04-06 | Class alias chain link fix (OPEN) |

---

## Refactoring / Code Cleanup (all MERGED unless noted)

| PR | Title | Date | Status | Key Changes |
|----|-------|------|--------|-------------|
| #1443 | Regroup tests under folder structure | 2025-11-01 -> 2025-11-12 | Merged | Test file reorganization |
| #1468 | Small refactors | 2025-11-23 | Merged | Minor code cleanup |
| #1634 | Refactor `comment_location` from Array to Hash | 2026-03-05 | Merged | Data structure improvement |
| #1642 | Remove dead constants and unused `AnonClass` | 2026-03-12 | Merged | Dead code removal |
| #1644 | Remove unused memoized caches from Context | 2026-03-14 | Merged | Memory/complexity reduction |
| #1623 | Refactor formatter options | 2026-02-22 | Merged | Options handling cleanup |
| #1624 | Stop generating separate page file for `main_page` | 2026-02-23 -> 2026-02-24 | Merged | Simplified page generation |
| #1622 | Decouple Store internals from CodeObject classes | 2026-02-22 | **OPEN/DRAFT** | `Store#resolve_parent`, `Store#resolve_mixin`, consolidated `store=`, fix double `add_file` bug |
| #1617 | Remove Darkfish and JsonIndex generators | 2026-02-19 | **OPEN** | -4993 lines. Blocked on broader adoption discussion. Breaking change. |
| #1616 | Remove deprecated CLI options and directives | 2026-02-19 | Merged | Remove `--accessor`, `--diagram`, `--inline-source`, `:main:`, `:title:` directives. Breaking change. |

---

## CI / Infrastructure (all MERGED)

| PR | Title | Date | Key Changes |
|----|-------|------|-------------|
| #1431 | Rescue RuboCop rake tasks require error | 2025-10-07 | Graceful fallback when RuboCop unavailable |
| #1434 | Add Herb linter and fix HTML/ERB issues | 2025-10-16 -> 2025-10-20 | HTML/ERB linting infrastructure |
| #1439 | Add AGENTS.md and CLAUDE.md | 2025-10-29 -> 2025-10-31 | AI coding assistant config |
| #1449 | Fix erb linting errors | 2025-11-14 | ERB template fixes |
| #1461 | Stop generating docs for Aliki's .rhtml templates | 2025-11-19 | Exclude templates from self-documentation |
| #1503 | Bump setup-ruby to v1.270.0 | 2025-12-16 | CI dependency update |
| #1514 | Fix herb linting errors in ERB templates | 2025-12-20 | More template lint fixes |
| #1543 | Bump setup-ruby to latest | 2026-01-04 | CI dependency update |
| #1545 | Use Playwright MCP for e2e testing | 2026-01-04 -> 2026-01-09 | End-to-end testing approach |
| #1604 | Add `/release-check` Claude Code skill | 2026-02-08 -> 2026-02-09 | Automated release audit tooling |
| #1619 | Add breaking-change category to release notes | 2026-02-21 | Release notes categorization |
| #1625 | Add CI check for RI backward compatibility | 2026-02-23 -> 2026-02-24 | Ensure RI format doesn't break across versions |
| #1645 | Fix herb linter offenses in ERB templates | 2026-03-14 | Template lint fixes |
| #1658 | Fix `:stopdoc:` directive being undone for C classes | 2026-03-22 | Closed without merge (behavior was correct) |

---

## Server Mode Follow-ups (all MERGED)

| PR | Title | Date | Key Changes |
|----|-------|------|-------------|
| #1647 | Fix server mode live reload for C files | 2026-03-15 | C file watching support |
| #1648 | Print timing for page requests and re-parsing | 2026-03-15 -> 2026-03-16 | Performance diagnostics |
| #1649 | Fix deadlock on Ctrl+C in server mode | 2026-03-16 | Clean shutdown |
| #1671 | Fix page links returning 404 in server mode | 2026-04-04 -> 2026-04-09 | Routing fix |

---

## Version Bumps (all MERGED)

| PR | Title | Date |
|----|-------|------|
| #1429 | Bump version to 6.15.0 | 2025-10-03 |
| #1441 | Bump version to 6.15.1 | 2025-10-31 |
| #1474 | Bump version to 6.16.0 | 2025-11-25 |
| #1506 | Bump version to 7.0.0 | 2025-12-17 |
| #1510 | Bump version to 7.0.1 | 2025-12-18 |
| #1608 | Bump version to 7.2.0 | 2026-02-09 |

---

## Other Open PRs (not yet merged)

| PR | Title | Date | Notes |
|----|-------|------|-------|
| #1470 | Use Prism instead of Ripper for Ruby source tokenization | 2025-11-23 | Alternative tokenizer |
| #1484 | Add `hide` option to hide pages from sidebar | 2025-12-04 | Sidebar control |
| #1495 | Avoid linking file paths inside backticks | 2025-12-14 | Cross-reference refinement |
| #1507 | [PoC] Rename `TopLevel` to `File` | 2025-12-17 | Proof-of-concept refactor |
| #1568 | Create doc checker system | 2026-01-19 | Documentation quality tooling |
| #1627 | Fix Markdown blockquote parsing | 2026-02-28 | Blockquote lazy continuation |
| #1628 | Enable `break_on_newline` extension by default for Markdown | 2026-03-01 | Markdown newline behavior |
| #1659 | Add RDoc coverage check for C extensions in ruby-core CI | 2026-03-22 | Coverage tooling for C code docs |
| #1663 | Overhaul coverage report | 2026-03-28 | Coverage report improvements |
| #1675 | Fix broken sidebar links for chained class aliases | 2026-04-06 | Link fix |
| #1676 | Preserve `#` prefix for unresolved cross-references | 2026-04-09 | Cross-ref display fix |

---

## Docs

| PR | Title | Date | Status |
|----|-------|------|--------|
| #1496 | Replace `CONTRIBUTING.rdoc` with `CONTRIBUTING.md` | 2025-12-14 | Merged |
| #1629 | Move `RubygemsHook` doc to the right place | 2026-03-02 | Merged |

---

## Summary by Theme

### 1. Aliki Theme (complete overhaul of RDoc's visual output)
- Created from scratch (#1432), made default (#1502), rebuilt search (#1504)
- 18+ follow-up PRs for polish: sidebar, mobile, dark mode, styling, search UX

### 2. Server Mode (`rdoc --server`)
- Live-reload development server (#1620) with 4 follow-up bug fixes
- Custom TCPServer, incremental re-parsing, file watching, no external deps

### 3. RBS Type Signatures (in progress)
- #1665 (draft): Parse `#:` annotations, display in HTML/RI, link type names
- Depends on #1669 (signature card design, merged)

### 4. Markdown/Markup Compatibility
- Strikethrough, heading anchors, backtick quoting, code highlighting, table parsing
- GFM spec comparison (#1550)

### 5. Legacy Removal
- Deprecated CLI options removed (#1616)
- Darkfish removal proposed (#1617, open)
- Dead code cleanup (#1642, #1644)

### 6. Architecture/Refactoring
- Store-CodeObject decoupling (#1622, open/draft)
- Formatter options refactor (#1623)
- comment_location data structure (#1634)
- RI backward compatibility CI (#1625)

### 7. Releases
- 6.15.0 -> 6.15.1 -> 6.16.0 -> 7.0.0 -> 7.0.1 -> 7.2.0
