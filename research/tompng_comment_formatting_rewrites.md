# tompng's Comment Directive & Inline Formatting Rewrites

## Overview

tompng (tomoya ishida) made two major rewrites to RDoc:

1. **Prism Ruby parser compatibility** (PR #1284, merged as `eb85efb5`) -- 10 commits fixing bugs in `RDoc::Parser::PrismRuby` to reach parity with the old Ripper-based parser, then PR #1581 switched the default parser to PrismRuby
2. **InlineParser replacing AttributeManager** (PR #1559, merged as `9456e795`) -- complete rewrite of inline formatting from a string-substitution/macro engine to a proper recursive-descent parser producing structured AST nodes

---

## Part 1: InlineParser (PR #1559)

### What was replaced

`RDoc::Markup::AttributeManager` -- a string-replacing/macro-based inline parser that used non-printing character substitution (NUL bytes, chars 0x00-0x08) to mark formatting boundaries in a flat string. It converted text into a "flow" (array of strings and `AttrChanger` objects), which formatters then walked linearly.

**Deleted files (7):**
- `lib/rdoc/markup/attribute_manager.rb` (432 lines)
- `lib/rdoc/markup/attributes.rb` (70 lines)
- `lib/rdoc/markup/attr_changer.rb` (22 lines)
- `lib/rdoc/markup/attr_span.rb` (35 lines)
- `lib/rdoc/markup/regexp_handling.rb` (40 lines)
- `test/rdoc/markup/attribute_manager_test.rb` (474 lines)
- `test/rdoc/markup/attributes_test.rb` (39 lines)

**Created files (2):**
- `lib/rdoc/markup/inline_parser.rb` (321 lines)
- `test/rdoc/markup/inline_parser_test.rb` (265 lines)

Net: -1264 / +1827 across 31 files.

### Architectural change

Old (AttributeManager):
- Flat string with sentinel characters marking format boundaries
- Regexp-based TIDYLINK handling as a "regexp_handling" macro
- `convert_flow` walked a flat array of strings + AttrChanger markers
- Architecture mismatch: structured inline styles represented as flat string operations

New (InlineParser):
- Recursive-descent parser producing nested AST: `{ type: :BOLD, children: [string_or_node, ...] }`
- TIDYLINK is a first-class syntax construct with its own `{ type: :TIDYLINK, url: ..., children: [...] }`
- Formatters traverse the tree via `handle_BOLD`, `handle_EM`, `handle_TT`, `handle_TIDYLINK`, etc.
- Regexp handling (crossref, hyperlink) applied only to text nodes after parse, not to the raw string

### Bugs fixed / behavior changes in the inline formatting

#### 1. Tidylink nested formatting now works correctly

Old: `{Label with *bold* text}[url]` -- formatting inside tidylink labels frequently failed because the regexp-based TIDYLINK macro couldn't handle nested structure.

New: Works correctly; the parser treats `{...}[url]` as a containing node with children that can include `*bold*`, `_em_`, etc.

Test: `test/rdoc/markup/inline_parser_test.rb:173-179`

#### 2. Simplified tidylink restricted to alphanumeric labels

Old: ``a*_`+<b>c[foo]`` would turn the entire preceding text into a link: `<a href="foo">a*_`+&lt;b&gt;c</a>`. This made simplified tidylinks conflict with other syntaxes.

New: Only `Alphanumeric[url]` (must start with a letter) is treated as a simplified tidylink.

From PR description: "This is terrible, it can't coexist with other syntaxes like `*word*` `_word_` `+word+`. We should restrict characters and recommend `{label}[url]`."

Test: `test/rdoc/markup/inline_parser_test.rb:148-153`

#### 3. `C1.m[:sym]` no longer swallowed by tidylink

Old: `C1.m[:sym]` rendered as `<a href="C1.html#method-c-m"><code>C1.m[:sym]</code></a>` -- the `[:sym]` was consumed as a link URL.

New: `<a href="C1.html#method-c-m"><code>C1.m</code></a>[:sym]` -- only `C1.m` is the crossref; `[:sym]` remains plain text.

Test: `test/rdoc/markup/to_html_crossref_test.rb:243-248`

#### 4. Cross-references disabled in word-pair markup (`*word*`, `_word_`)

New behavior: `*C1*` renders as `<strong>C1</strong>` (no crossref link), while `<b>C1</b>` renders as `<strong><a href="C1.html"><code>C1</code></a></strong>` (crossref still active).

Rationale: Word-pair types (`BOLD_WORD`, `EM_WORD`, `TT`) are leaf nodes with no regexp handling; tag-based types (`BOLD`, `EM`) contain text nodes where regexp handling runs.

Test: `test/rdoc/markup/to_html_crossref_test.rb:255-259` (`test_crossref_disabled_in_word_pair`)

#### 5. Hyperlinks/rdoc-ref/rdoc-image suppressed inside tidylink labels

Old: `{See http://example.com}[README.txt]` -- the URL inside the label would be converted to a hyperlink, breaking the tidylink.

New: Regexp handling for hyperlinks is disabled inside tidylink labels. Only rdoc-image gets special treatment when it's the entire label.

Tests:
- `test/rdoc/markup/to_html_test.rb:1052` (`test_convert_hyperlink_disabled_inside_tidylink`)
- `test/rdoc/markup/to_html_test.rb:1057` (`test_convert_rdoc_image_inside_tidylink`)
- `test/rdoc/markup/to_html_test.rb:1068` (`test_convert_rdoc_label_disabled_inside_tidylink`)

#### 6. Cross-references suppressed inside tidylink labels

New: `{rdoc-ref:C1.m http://example.com C1}[url]` renders as a single link to `url` with all of the label text, without internal crossref processing.

Test: `test/rdoc/markup/to_html_crossref_test.rb:250-252` (`test_suppress_link_inside_tidylink_label`)

#### 7. Proper error recovery for unclosed/mismatched tags

Old: Unclosed tags could corrupt surrounding formatting.

New: Explicit error recovery rules:
- Closing tags invalidate unclosed tags; unclosed tags become plain text
- Unmatched closing tags become plain text
- Nested tidylinks invalidate outer tidylinks

Tests: `test/rdoc/markup/inline_parser_test.rb:223-268`

#### 8. `__FILE__` / `__send__` exceptions for underscore word pairs

`__FILE__`, `__LINE__`, `__send__` are NOT treated as em-word (`_FILE_` inside `__...__`); they remain plain text.

Code: `lib/rdoc/markup/inline_parser.rb:242-244`
Test: `test/rdoc/markup/inline_parser_test.rb:84-85`

### Follow-up InlineParser fixes

**`306ca6e5` -- Handle in_tidylink_label check correctly, fix edge cases of link/rdoc-ref/rdoc-image in tidylink label**
- Added tests for `hyperlink_disabled_inside_tidylink`, `rdoc_image_inside_tidylink`, `rdoc_label_disabled_inside_tidylink`
- 4 files changed, +50/-13

**`cc9dcdf8` -- Simplify inline parser state**
- Internal simplification, no behavior change

**`bb771be4` -- Move suppressed-crossref backslash removing logic to regexp_handling**
- Moved backslash-removal for suppressed cross-references from the formatter to the regexp handling phase

**`1b7488d5` -- Use strscan in InlineParser token scan**
- Performance improvement using StringScanner

---

## Part 2: Prism Ruby Parser Bugs Fixed (PR #1284 + follow-ups)

The `accept_legacy_bug?` test marker is defined in `test/rdoc/parser/prism_ruby_test.rb`:
- Line 2382: `RDocParserPrismRubyTest` returns `false`
- Line 2396: `RDocParserRipperRubyWithPrismRubyTestCasesTest` returns `true`

The Ripper-based test class only runs when `ENV['RDOC_USE_RIPPER_PARSER']` is set (line 2404). Every `accept_legacy_bug?` guard documents a bug in the old Ripper parser that the new Prism parser fixes.

### Catalog of `accept_legacy_bug?` guarded bugs

| Line(s) | Test method | Old (Ripper) bug | Fixed (Prism) behavior |
|---------|-------------|------------------|----------------------|
| 325 | `test_class_module_nodoc` | `:nodoc:` on `module MBaz::M` not properly applied; documentable list incorrect | Correctly filters to `['Baz', 'MBaz']` |
| 603 | `test_method_definition` | `three(x)` arglists not parsed when `def three x` uses space-separated param | Correctly reports `three(x)` |
| 720 | `test_define_method` | `define_method :baz` inside `class << self` not marked as singleton | Correctly sets `singleton = true` |
| 757 | `test_method_definition_nested_inside_block` | `def` inside blocks (e.g., `included do`) incorrectly documented; `baz1` inside unknown block documented | Rejects `def` inside metaprogramming blocks; only documents `[:foo, :bar, :baz2, :baz3]` |
| 882 | `test_singleton_class_nonself` | `class << ::Bar` and `class << Baz1` incorrectly created extra modules | Only `['A', 'A::Foo', 'Bar']` modules exist |
| 920 | `test_singleton_class` | `def self.dummy2` inside `class << self` and `def self.dummy4` inside `class << Foo` incorrectly documented as regular methods | Correctly filtered out |
| 953 | `test_singleton_class_meta_method` | `:method: m4` inside `class << self` not treated as singleton | Correctly sets `singleton = true` |
| 1072 | `test_module_function` | `module_function def m4` -- old parser fails to make instance copy private and doesn't create singleton copy for `m4` | Correctly handles `module_function def m4` |
| 1097 | `test_class_method_visibility` | `private_class_method`/`public_class_method` with `def` argument not handled | `['m1', 'm3', 'm5']` correctly public |
| 1129 | `test_undocumentable_change_visibility` | Not implemented: old parser can't handle `private 42, :m` or `private def self.m1` edge cases | Correctly ignores non-standard visibility calls |
| 1164 | `test_method_visibility_change_in_subclass` | Not implemented: `private :m1` / `public :m2` in subclass B not tracked | Creates visibility-changed method entries in subclass |
| 1266 | `test_alias_method_visibility` | `alias_method` visibility not correct; `foo` should be `:private` after `private :foo`, `foo2` should stay `:public` | Correct visibility for aliased methods |
| 1275 | `test_invalid_alias_method` | Old parser doesn't reject invalid `alias_method` calls (0 args, 3 args, non-symbol) | Only valid `alias_method :new, :old` documented |
| 1321 | `test_attributes_stopdoc_nodoc` | `attr :attr1, :attr2` treated as single attribute; `rw` set to wrong value | Correctly creates 2 attributes per `attr`; 8 total |
| 1393-1413 | `test_attributes_nodoc` / `test_attributes_nodoc_track` | `:nodoc:` on multi-arg `attr_reader`/`attr_writer`/`attr_accessor` not applied to all attrs | Correct count: 4 documented / 12 with `:nodoc` tracking |
| 1504, 1559 | `test_meta_attributes` / `test_meta_attributes_named` | `:attr:` directive produces wrong `rw` value (not `'R'`) | Correctly sets `rw = 'R'` for `:attr:` |
| 1595-1601 | `test_constant` | Constants in wrong namespaces; `::C` not placed in Object; line numbers wrong | Constants placed in correct classes with correct line numbers |
| 1721 | `test_constant_with_singleton_class` | Constants inside `class <<Bar` mishandled | Correctly assigns constants in singleton class contexts |
| 1778 | `test_true_false_nil_method` | `def nil.foo` creates `NilClass::foo` (class method separator) | Creates `NilClass#foo` (instance method on singleton) |
| 1810 | `test_include_extend_to_singleton_class` | Not implemented: `include I` inside `class << self` not converted to `extend` | Correctly converts to extend |
| 1828 | `test_include_with_module_nesting` | Not implemented: module nesting context not resolved for `include M` | Resolves `include M` to correct module via nesting |
| 1861 | `test_various_argument_include` | Not implemented: multi-arg `include A, B` and invalid `include 42, C` not handled | Handles multi-arg; rejects non-constant args |
| 2120 | `test_include_extend_suppressed_within_block` | `include M` / `extend N` inside metaprogramming blocks incorrectly applied to outer class | Suppressed inside blocks; only direct `include O`/`extend O` applied |
| 2162 | `test_visibility_methods_suppressed_within_block` | `private_class_method :s_pri` inside `Module.new do` block incorrectly applied | Block-level visibility changes suppressed |
| 2166 | `test_alias_method_suppressed_within_block` | `alias_method` inside blocks incorrectly applied to outer class | `alias_method` suppressed inside blocks |

### Key commits in PR #1284

| Commit | Description |
|--------|-------------|
| `7b3331b0` | Reduce the difference between PrismRuby and Ruby parsers (foundational) |
| `14dc2e90` | Suppress include and extend inside method block |
| `01cbb99d` | Fix constant defined in singleton class, class constant_path, module constant_path |
| `89667183` | Strip prefix `::` from superclass name |
| `69bb46de` | Reject documenting `def` inside block |
| `c5d96a81` | Accept "new" and "initialize" method both documented |
| `25f1df9b` | Fix wrong test for class defined inside singleton class |
| `0299ae14` | Fix superclass override when class Object is documented |
| `2973d9de` | Support `:nodoc:` on method definition parameter end line |
| `de966075` | pend->omit test that RDoc::Parser::Ruby has a bug or does not support |

### Post-#1284 follow-ups

| PR | Commit | Description |
|----|--------|-------------|
| #1581 | `78ca6f50` | **Switch default parser to PrismRuby.** Fixes issues #398, #782, #816, #885, #1373, #1553, #1555 |
| #1595 | `7e1157ae` | Ignore visibility method, attr definition, module_function within block (found in rails/rails) |

---

## Part 3: Other tompng Fixes (Not Parser or Inline)

| Commit | Description |
|--------|-------------|
| `906a72b0` | Document is not a Comment -- stops mixing `Document` with `Comment` in `CodeObject#comment`, fixing a class of potential bugs from Marshal round-trips |
| `49551988` | Simplify section add/remove comment logic |
| `f5a67bdc` | Fix `ToRdoc#accept_table` -- table alignment was broken; added `accept_table_align` tests for ANSI, BS, RDoc formatters |
| `61f11a6c` | Simplify newline handling of comment token in `TokenStream#to_html` |
| `acaf13dd` | Fix ri completion to always return candidates starting with a given name |
| `b59ca2f9` | Delay DidYouMean until `NotFoundError#message` is called |
| `40a66900` | Use ASCII character in HTML file |

---

## Summary of User-Facing Changes

### Things that now work correctly (InlineParser)

1. `{Bold *label*}[url]` -- formatting inside tidylink labels
2. `C1.m[:sym]` -- no longer swallowed as a link URL
3. `__FILE__` and `__send__` -- no longer mis-parsed as emphasis
4. Unclosed `<b>` or mismatched `</i>` -- graceful degradation to plain text
5. `{See http://example.com}[url]` -- hyperlinks inside tidylink labels not double-processed

### Things that now work correctly (Prism parser)

1. `:nodoc:` on multi-line method params (`def foo(arg1,\n  arg2) # :nodoc:`)
2. `define_method` inside `class << self` correctly marked singleton
3. `include`/`extend`/`alias_method` inside metaprogramming blocks suppressed
4. `module_function def m` correctly creates private instance + public singleton
5. Constants in `class <<Bar` / `module ::Foo::Bar` placed in correct namespace
6. `def nil.foo` creates `NilClass#foo` not `NilClass::foo`
7. Multi-arg `attr_reader :a, :b # :nodoc:` applies nodoc to all attributes
8. Visibility changes in subclasses tracked

### Intentional behavior change (InlineParser)

Simplified tidylink `word[url]` now restricted to identifiers starting with a letter. Old behavior where `a*_`+<b>c[foo]` became a link is no longer supported. Use `{label}[url]` instead.
