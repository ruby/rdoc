# Stan Lo (st0012) Pull Requests in ruby/ruby Since October 2025

Total: 41 PRs (34 merged, 1 open, 6 closed without merge)

---

## RDoc / Documentation (16 PRs)

### RDoc Version Bumps (8 PRs)

| # | Title | Status | Date | Description |
|---|-------|--------|------|-------------|
| [#16506](https://github.com/ruby/ruby/pull/16506) | Use latest RDoc | Merged | 2026-03-23 | Bumps RDoc to latest to fix `install-doc` failures on some platforms (references ruby/rdoc#1657). +4/-4, 2 files. |
| [#15726](https://github.com/ruby/ruby/pull/15726) | Bump RDoc to 7.0.3 | Merged | 2025-12-24 | Version bump. +4/-3, 2 files. |
| [#15691](https://github.com/ruby/ruby/pull/15691) | Bump RDoc to 7.0.2 | Merged | 2025-12-22 | Version bump. +2/-2, 2 files. |
| [#15628](https://github.com/ruby/ruby/pull/15628) | Bump RDoc to 7.0.1 | Merged | 2025-12-18 | Aliki theme improvements; Aliki became the default theme so generator name no longer needed in config. +2/-4, 3 files. |
| [#15439](https://github.com/ruby/ruby/pull/15439) | Bump RDoc version to 6.17.0 | Merged | 2025-12-07 | Version bump. +1/-1, 1 file. |
| [#15344](https://github.com/ruby/ruby/pull/15344) | Bump RDoc version to 6.16.1 | Merged | 2025-11-28 | Version bump. +1/-1, 1 file. |
| [#14747](https://github.com/ruby/ruby/pull/14747) | Bump RDoc | Merged | 2025-10-08 | Version bump. |

### Documentation Improvements (5 PRs)

| # | Title | Status | Date | Description |
|---|-------|--------|------|-------------|
| [#16494](https://github.com/ruby/ruby/pull/16494) | Add `make html-server` for live-reloading doc preview | Merged | 2026-03-28 | Adds a new `html-server` Makefile target that uses RDoc's `--server` mode to start a local HTTP server with live reload at localhost:4000. Supports custom port via `RDOC_SERVER_PORT=8080`. +15/-3, 2 files. |
| [#16401](https://github.com/ruby/ruby/pull/16401) | Add `make html-server` for live-reloading doc preview | Closed (draft) | 2026-03-22 | Earlier draft of #16494, superseded. Pinned rdoc in `bundled_gems` to server mode commit. +16/-4, 3 files. |
| [#16393](https://github.com/ruby/ruby/pull/16393) | [DOC] Simplify doc setup | Merged | 2026-03-15 | Removed redundant RDoc settings, outdated/obsolete files, and stale `.document` entries. Major cleanup: +0/-567, 8 files changed. |
| [#15339](https://github.com/ruby/ruby/pull/15339) | [DOC] Remove unneeded filename from rdoc-ref links | Merged | 2025-11-27 | Cleaned up rdoc-ref links to remove unnecessary filename prefixes when linking to same-doc targets. +51/-53, 4 files. |
| [#15319](https://github.com/ruby/ruby/pull/15319) | [DOC] Use Aliki as the documentation website theme | Merged | 2025-11-26 | Switched Ruby's documentation website to use the new Aliki theme for RDoc output. |

### Page Documentation Reorganization (2 PRs)

| # | Title | Status | Date | Description |
|---|-------|--------|------|-------------|
| [#15154](https://github.com/ruby/ruby/pull/15154) | Reorganize page documentations | Merged | 2025-11-27 | Reorganized the structure of page-level documentation files for better navigation and discoverability. |
| [#14964](https://github.com/ruby/ruby/pull/14964) | [DOC] Add doc to explain VM stack | Merged | 2025-11-18 | Added documentation explaining Ruby's VM stack architecture. |

### Other Documentation (1 PR)

| # | Title | Status | Date | Description |
|---|-------|--------|------|-------------|
| [#15248](https://github.com/ruby/ruby/pull/15248) | [DOC] Update yjit.md to use a different email | Merged | 2025-11-19 | Updated contact email in YJIT documentation. |

---

## ZJIT (14 PRs)

### Optimizations (4 PRs)

| # | Title | Status | Date | Description |
|---|-------|--------|------|-------------|
| [#15505](https://github.com/ruby/ruby/pull/15505) | ZJIT: Inline `Hash#[]=` | Merged | 2025-12-12 | Added inline optimization for `Hash#[]=` in ZJIT codegen. |
| [#15450](https://github.com/ruby/ruby/pull/15450) | ZJIT: Inline `Hash#key?` and its aliases | Closed (not merged) | -- | Attempted to inline `Hash#key?` and aliases; not merged. |
| [#14898](https://github.com/ruby/ruby/pull/14898) | ZJIT: Optimize variadic cfunc `Send` calls into `CCallVariadic` | Merged | 2025-12-01 | Introduced `CCallVariadic` IR instruction to optimize calls to variadic C functions, avoiding the overhead of generic `Send`. |
| [#14863](https://github.com/ruby/ruby/pull/14863) | ZJIT: Optimize send with block into CCallWithFrame | Merged | 2025-10-20 | Optimized method calls that pass blocks to C functions by introducing `CCallWithFrame` codegen. |

### Refactoring & Code Quality (6 PRs)

| # | Title | Status | Date | Description |
|---|-------|--------|------|-------------|
| [#15448](https://github.com/ruby/ruby/pull/15448) | ZJIT: Avoid redundant SP save in codegen | Merged | 2025-12-08 | Removed unnecessary stack pointer saves in generated code. |
| [#15423](https://github.com/ruby/ruby/pull/15423) | ZJIT: Include local variable names in `Get|SetLocal` insn's print value | Merged | 2025-12-05 | Improved debug output by including local variable names in IR instruction display. |
| [#15334](https://github.com/ruby/ruby/pull/15334) | ZJIT: Standardize method dispatch insns' `recv` field | Merged | 2025-12-01 | Standardized receiver field naming across method dispatch instructions. |
| [#15332](https://github.com/ruby/ruby/pull/15332) | ZJIT: Remove dead unnecessary_transmutes allow | Merged | 2025-11-26 | Removed unused `#[allow]` attributes for transmutes. |
| [#15128](https://github.com/ruby/ruby/pull/15128) | ZJIT: More refactor around type resolution API | Merged | 2025-11-11 | Continued cleanup of the type resolution API in ZJIT. |
| [#15032](https://github.com/ruby/ruby/pull/15032) | ZJIT: Refactor receiver type resolution and record megamorphic profile results | Merged | 2025-11-10 | Refactored how receiver types are resolved and added megamorphic call site profiling. |

### Variable Naming & Types (2 PRs)

| # | Title | Status | Date | Description |
|---|-------|--------|------|-------------|
| [#15021](https://github.com/ruby/ruby/pull/15021) | ZJIT: Standardize variable name for callable method entry | Merged | 2025-10-31 | Consistent naming convention for callable method entry variables. |
| [#14777](https://github.com/ruby/ruby/pull/14777) | ZJIT: Use type alias for num-profile and call-threshold's types | Merged | 2025-10-08 | Type aliases for cleaner profile count and threshold types. |

### Instrumentation & Debugging (2 PRs)

| # | Title | Status | Date | Description |
|---|-------|--------|------|-------------|
| [#14942](https://github.com/ruby/ruby/pull/14942) | ZJIT: Add assertion to ensure codegen functions check overflow after frame pushing | Closed (not merged) | -- | Proposed assertion for frame overflow checking. Not merged. |
| [#14801](https://github.com/ruby/ruby/pull/14801) | ZJIT: Count unoptimized `Send` | Merged | 2025-10-11 | Added counter for unoptimized Send instructions to track optimization opportunities. |

### Other ZJIT (2 PRs)

| # | Title | Status | Date | Description |
|---|-------|--------|------|-------------|
| [#14993](https://github.com/ruby/ruby/pull/14993) | [DOC] ZJIT: Add documentation about native stack and Ruby's VM stack | Merged | 2025-10-30 | Added developer documentation explaining native stack vs. VM stack in ZJIT context. |
| [#14921](https://github.com/ruby/ruby/pull/14921) | ZJIT: Use iseq pointer directly in get/set class var codegen | Merged | 2025-10-23 | Used iseq pointer directly instead of going through indirection for class variable access. |
| [#14698](https://github.com/ruby/ruby/pull/14698) | ZJIT: Allow higher profile num | Merged | 2025-10-01 | Increased the maximum number of profile entries allowed. |

---

## CI / Build System (5 PRs)

| # | Title | Status | Date | Description |
|---|-------|--------|------|-------------|
| [#16660](https://github.com/ruby/ruby/pull/16660) | mkmf: split try_link0 into separate compile and link steps | **Open** | 2026-04-05 | Splits `try_link0` in mkmf into separate compile and link steps for better error diagnostics. Currently open. |
| [#16592](https://github.com/ruby/ruby/pull/16592) | Optimize CI: rebalance compilations, use cheaper result runners | Merged | 2026-03-30 | Rebalanced CI compilation jobs and switched to cheaper runner types for result aggregation. |
| [#16591](https://github.com/ruby/ruby/pull/16591) | Remove dead `Resolve job ID` step from macOS workflow | Merged | 2026-03-30 | Removed a dead CI step from the macOS workflow. |
| [#16513](https://github.com/ruby/ruby/pull/16513) | Parallelize bundled gems test execution | Merged | 2026-03-26 | Made bundled gem tests run in parallel for faster CI. |
| [#16238](https://github.com/ruby/ruby/pull/16238) | Fix man page date check failing on shallow clones | Closed (not merged) | -- | Attempted fix for man page date verification on shallow clones. Not merged. |

---

## C Code / VM (3 PRs)

| # | Title | Status | Date | Description |
|---|-------|--------|------|-------------|
| [#16587](https://github.com/ruby/ruby/pull/16587) | Extract `check_event_support` helper to reduce duplication in `vm_trace.c` | Merged | 2026-03-28 | Extracted a helper function to eliminate duplicated event support checking logic in `vm_trace.c`. |
| [#16198](https://github.com/ruby/ruby/pull/16198) | Extract check_event_support helper to reduce duplication in vm_trace.c | Closed (not merged) | -- | Earlier version of #16587, superseded. |
| [#16196](https://github.com/ruby/ruby/pull/16196) | Fix wrong function names in `rb_bug` messages in vm_trace.c | Merged | 2026-02-19 | Fixed incorrect function names displayed in `rb_bug` error messages. |

---

## Miscellaneous (3 PRs)

| # | Title | Status | Date | Description |
|---|-------|--------|------|-------------|
| [#15955](https://github.com/ruby/ruby/pull/15955) | Ignore AI agents related files | Merged | 2026-01-25 | Added AI agent config files to `.gitignore`. |
| [#15828](https://github.com/ruby/ruby/pull/15828) | Remove ruby-bench excludes | Merged | 2026-01-08 | Removed outdated ruby-bench exclusion entries. |

---

## Summary by Category

| Category | Merged | Open | Closed (not merged) | Total |
|----------|--------|------|---------------------|-------|
| RDoc / Documentation | 14 | 0 | 1 (draft superseded) | 15 |
| ZJIT | 12 | 0 | 2 | 14 |
| CI / Build System | 3 | 1 | 1 | 5 |
| C Code / VM | 2 | 0 | 1 (superseded) | 3 |
| Miscellaneous | 2 | 0 | 0 | 2 |
| **Total** | **33** | **1** | **5** | **39** |

Note: 2 PRs are duplicates/superseded versions (#16401 superseded by #16494, #16198 superseded by #16587), bringing unique efforts to ~37.

---

## Key Themes

### 1. RDoc Stewardship (Biggest Area)
- **6 version bumps** from 6.16.1 through 7.0.3 to latest, keeping Ruby's bundled RDoc current
- **Aliki theme adoption** (#15319, #15628): Switched Ruby docs to the new Aliki theme, made it the default
- **Live reload server** (#16494): Added `make html-server` for live-reloading documentation preview during development
- **Documentation cleanup** (#16393): Massive 567-line deletion removing redundant/stale RDoc config
- **Page reorganization** (#15154): Restructured page-level docs for better navigation
- **rdoc-ref link cleanup** (#15339): Removed unnecessary filename prefixes from internal doc links

### 2. ZJIT Compiler Work
- Inline optimizations for `Hash#[]=` and send-with-block patterns
- New IR instructions: `CCallVariadic`, `CCallWithFrame`
- Extensive refactoring of type resolution, receiver handling, and variable naming
- Developer documentation for VM stack vs native stack

### 3. CI Improvements
- Parallelized bundled gem tests
- Rebalanced CI runners for cost optimization
- Cleaned up dead workflow steps

### 4. VM Trace Improvements
- Extracted `check_event_support` helper in `vm_trace.c`
- Fixed incorrect function names in `rb_bug` messages
