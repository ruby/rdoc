# Why Markdown Improvements Are Slow: The Shared IR Problem

## The One-Line Summary

Markdown doesn't have its own intermediate representation — it converts inline syntax to **RDoc markup strings**, which then get re-parsed by a shared inline parser. Fixing Markdown means not breaking RDoc markup, and vice versa.

## The Architecture

```
                     Block-level parsing              Inline parsing            Rendering
                     ─────────────────               ──────────────            ─────────
Markdown source  ──► RDoc::Markdown.parse ──┐
                     (markdown.kpeg)        │
                                            ├──► RDoc::Markup::Document ──► InlineParser ──► ToHtml
                                            │    (Paragraph, Heading,       (shared!)       (shared!)
RDoc markup      ──► RDoc::Markup.parse  ──┘     List, Verbatim, etc.)
                     (parser.rb)                  SAME NODE TYPES
```

## The Core Problem: Two-Phase Parsing

When the Markdown parser encounters `**bold text**`, it does NOT produce a structured "bold" node. Instead:

```ruby
# lib/rdoc/markdown.kpeg, line 303
def strong(text)
  if text =~ /\A[a-z\d.\/-]+\z/i
    "*#{text}*"              # → RDoc word-pair markup string
  else
    "<b>#{text}</b>"         # → RDoc HTML tag string
  end
end
```

The Markdown parser outputs **RDoc-formatted strings** inside `Paragraph` nodes. These strings are then re-parsed by `RDoc::Markup::InlineParser` — the same parser that handles RDoc markup's inline formatting.

## Why This Makes Fixes Hard

### 1. Shared InlineParser
Any change to `InlineParser` (lib/rdoc/markup/inline_parser.rb) affects both Markdown and RDoc markup. Adding strikethrough support for Markdown required modifying the shared parser, which could break RDoc markup rendering.

### 2. Escape Rules Are Coupled
Markdown must escape RDoc-special characters when generating strings:

```ruby
# lib/rdoc/markdown.kpeg, line 309
def rdoc_escape(text)
  text.gsub(/[*+<\\_]/) {|s| "\\#{s}" }
end
```

If InlineParser's escape handling changes, Markdown's escape generation breaks.

### 3. Shared Formatters
All rendering goes through the same `RDoc::Markup::Formatter` subclasses (ToHtml, ToHtmlCrossref, ToRdoc, etc.). Changes to formatters must work for documents produced by both parsers.

### 4. Cross-References Are Unified
Both formats share the same cross-reference linking system via `regexp_handling` in `ToHtmlCrossref`. Link resolution behavior can't diverge between formats.

## Concrete Examples of Cross-Format Breakage

| Fix | What happened |
|-----|---------------|
| **Strikethrough** (Jan 2026) | Markdown parsed `~~text~~` correctly but InlineParser didn't recognize `~` as delimiter or `<del>` tags. Had to modify shared InlineParser. |
| **Backtick quoting** (Jan 2026) | Extended backtick support — had to work in both Markdown and RDoc markup contexts |
| **Table parsing** (Nov 2024) | Markdown table parser's special behavior affected general parsing |
| **Escape handling** (Aug 2024) | Markdown escapes had to align with InlineParser's escape rules |

## What Would Fix This

The ideal fix: give Markdown its own structured inline representation instead of outputting RDoc strings. But this would require:
- A parallel inline node system or tagged nodes that carry format origin
- Separate formatter paths for Markdown-originated vs RDoc-originated content
- Massive test infrastructure changes

This is a fundamental architectural debt from RDoc's original design, where Markdown was bolted on as a second input format that feeds into a pipeline designed for one format.

## tompng's InlineParser Rewrite (Jan 2026)

The replacement of `AttributeManager` with `InlineParser` (PR #1559) was a step forward — it moved from string-replacing macros to structured inline nodes. But the Markdown parser still outputs RDoc-formatted strings that feed into this shared parser, so the coupling remains.

## Talk Framing

This explains why:
1. **Markdown improvements take so long** — every fix must be tested against both formats
2. **The fix space is constrained** — sometimes the "right" Markdown fix would break RDoc markup
3. **It's a 15+ year architectural decision** — Markdown was added to RDoc around 2011-2012, reusing the existing pipeline rather than building a parallel one
4. **Progress is real but incremental** — GFM spec comparison (#1550), strikethrough, heading anchors, table fixes all chipped away at this
