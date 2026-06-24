# DESIGN.md

Single source of truth for the **Aliki** theme's visual language. The generated
HTML documentation — served from `localhost` (`rdoc --server`),
[docs.ruby-lang.org](https://docs.ruby-lang.org), and static GitHub Pages —
implements what's specified here. The implementation lives in one stylesheet,
[`css/rdoc.css`](css/rdoc.css). When a value here drifts from that file, **the
stylesheet is wrong** and should be brought back in line.

This document follows the
[Stitch DESIGN.md format](https://github.com/VoltAgent/awesome-design-md) —
nine sections covering theme, color, type, components, layout, elevation,
guardrails, responsive behavior, and an agent quick reference.

> Scope: this is the **visual** contract only. It does not cover the generator
> pipeline, templates, or JS architecture.

---

## 1. Visual Theme & Atmosphere

**Personality.** Modern, light, content-first. Aliki is a quiet reading surface
for Ruby API docs — the documentation is the product, and the chrome recedes.
It should feel like a well-made developer-docs site, not a framework's default
output.

**Context of use.** Developers read reference docs while coding — scanning for a
method, a signature, a constant. The job is to find the thing and read it
comfortably. Reading measure and code legibility matter more than decoration.

**Mood.** Calm and neutral with a single decisive accent. Warm "stone" grays
carry the text hierarchy; one red accent carries identity and wayfinding
(headings, links-on-hover, active TOC, signature cards). Dark mode is a
first-class, hand-tuned surface — not an inverted afterthought.

**Density.** Comfortable, not cramped. A capped 800 px reading measure, generous
`--space-12` page padding, and a token-driven spacing rhythm. Every element
earns its space; there is no decorative chrome.

**Anti-references.** What Aliki must **not** look or feel like:

- **Not Darkfish** — the predecessor theme it deliberately departs from.
- **Not corporate** — no heavy, dense doc-portal styling.
- **Not cluttered** — sidebars and chrome stay quiet; content leads.

**References (inferred from the implementation, not externally specified).** The
system-font stack, GitHub-style heading anchors, and a flat token system place
Aliki in the family of modern, lightweight developer-doc themes. Treat positive
references as open — the brand is currently defined by its principles and
anti-references, not a named lookalike.

**Surface contexts.**

| Surface                    | Theme                                  | Atmosphere                                                        |
|----------------------------|----------------------------------------|-------------------------------------------------------------------|
| Generated docs (static)    | Light default · Dark via `data-theme`  | The primary reading surface; must work offline / from static hosts |
| Live server (`--server`)   | Same light/dark                        | Servlet pages (root, 404) use lighter chrome — no header/TOC/footer |

Aliki ships a **single brand palette** (red) with explicit **light and dark**
variants — not a multi-theme system.

## 2. Color Palette & Roles

All color is defined as CSS custom properties in
[`css/rdoc.css`](css/rdoc.css): light tokens in `:root`, dark tokens in a
`[data-theme="dark"]` override block that re-declares **only** what differs.
Components reference semantic tokens, never raw hex.

### Semantic roles

| Role               | Token (`--color-…`)        | Meaning                                          |
|--------------------|----------------------------|--------------------------------------------------|
| Brand accent       | `accent-primary`           | Identity + wayfinding (headings, active TOC, sig border) |
| Accent hover       | `accent-hover`             | Hover/darker accent                              |
| Accent subtle      | `accent-subtle`            | Tinted accent fills (buttons, focus ring)        |
| Primary text       | `text-primary`             | Body copy, method names                          |
| Secondary text     | `text-secondary`           | Meta, secondary labels, branch                   |
| Tertiary text      | `text-tertiary`            | Placeholders, snippets, signatures, footer-bottom |
| Page background    | `background-primary`       | Main surface                                     |
| Raised/​sunk bg     | `background-secondary` / `-tertiary` | Footer, modal close, hover fills       |
| Borders            | `border-subtle` / `-default` / `-emphasis` | Hairlines from quiet → strong      |
| Link               | `link-default` / `link-hover` | Body links (default = text color; hover = accent) |
| Code surface       | `code-bg` / `code-border`  | `<pre>` / inline `code`                          |
| Signature card     | `sig-bg`                   | Method/attribute header card                     |
| Nav                | `nav-bg` / `nav-text`      | Left sidebar surface + text                      |
| Table              | `th-background` / `td-background` | Header row + zebra rows                     |

### Brand palette — red ramp (identity, **fixed**)

| Step | Hex       | | Step | Hex       |
|------|-----------|-|------|-----------|
| 50   | `#fdeae9` | | 500  | `#eb544f` |
| 100  | `#fadad3` | | 600  | `#e62923` ← light accent |
| 200  | `#f8bfbd` | | 700  | `#b8211c` |
| 300  | `#f5a9a7` | | 800  | `#8a1915` |
| 400  | `#f07f7b` | | 900  | `#5c100e` |

Light accent = `primary-600` (`#e62923`); dark accent = `primary-500`
(`#eb544f`). **The hue is a fixed brand identity — do not retune it without
approval** (see §7).

### Neutral palette — warm "stone" ramp

`50 #fafaf9 · 100 #f5f5f4 · 200 #e7e5e4 · 300 #d6d3d1 · 400 #a8a29e · 500 #78716c · 600 #57534e · 700 #44403c · 800 #292524 · 900 #1c1917`

### Semantic tokens — resolved values

| Role                  | Light                     | Dark                      |
|-----------------------|---------------------------|---------------------------|
| `text-primary`        | `#1c1917` (neutral-900)   | `#fafaf9` (neutral-50)    |
| `text-secondary`      | `#57534e` (neutral-600)   | `#e7e5e4` (neutral-200)   |
| `text-tertiary`       | `#78716c` (neutral-500)   | `#a8a29e` (neutral-400)   |
| `background-primary`  | `#ffffff`                 | `#1c1917` (neutral-900)   |
| `background-secondary`| `#fafaf9` (neutral-50)    | `#292524` (neutral-800)   |
| `background-tertiary` | `#f5f5f4` (neutral-100)   | `#44403c` (neutral-700)   |
| `border-subtle`       | `#e7e5e4` (neutral-200)   | `#44403c` (neutral-700)   |
| `border-default`      | `#d6d3d1` (neutral-300)   | `#57534e` (neutral-600)   |
| `border-emphasis`     | `#a8a29e` (neutral-400)   | `#d6d3d1` (neutral-300)   |
| `link-default`        | `#1c1917`                 | `#fafaf9`                 |
| `link-hover`          | `#e62923` (primary-600)   | `#eb544f` (primary-500)   |
| `accent-primary`      | `#e62923` (primary-600)   | `#eb544f` (primary-500)   |
| `accent-hover`        | `#b8211c` (primary-700)   | `#f07f7b` (primary-400)   |
| `accent-subtle`       | `#fdeae9` (primary-50)    | `rgb(235 84 79 / 10%)`    |
| `code-bg`             | `#f6f8fa`                 | `#292524` (neutral-800)   |
| `code-border`         | `#d6d3d1`                 | `#44403c` (neutral-700)   |
| `sig-bg`              | `#f5f5f4` (neutral-100)   | `#211f1e` (hand-picked)   |
| `nav-bg` / `nav-text` | `#ffffff` / `#44403c`     | `#1c1917` / `#fafaf9`     |

### Syntax-highlight palette (`--code-*`)

One palette shared across **Ruby, C, and Shell** highlighting. Brighter in dark
mode so tokens stay legible on the dark code surface.

| Token   | Light     | Dark      |
|---------|-----------|-----------|
| blue    | `#1d4ed8` | `#93c5fd` |
| green   | `#047857` | `#34d399` |
| orange  | `#d97706` | `#fbbf24` |
| purple  | `#7e22ce` | `#c084fc` |
| red     | `#dc2626` | `#f87171` |
| cyan    | `#0891b2` | `#22d3ee` |
| gray    | `#78716c` | `#a8a29e` |

### Search-type badge colors

| Type     | Light bg / text       | Dark bg / text        |
|----------|-----------------------|-----------------------|
| class    | `#e6f0ff` / `#0050a0` | `#1e3a5f` / `#93c5fd` |
| module   | `#e6ffe6` / `#006600` | `#14532d` / `#86efac` |
| constant | `#fff0e6` / `#995200` | `#451a03` / `#fcd34d` |
| method   | `#f0e6ff` / `#5200a0` | `#3b0764` / `#d8b4fe` |

### Theme-agnostic tokens (not overridden in dark)

| Token                  | Value                    | Use                              |
|------------------------|--------------------------|----------------------------------|
| `overlay`              | `rgb(0 0 0 / 50%)`       | Modal / mobile-nav backdrop      |
| `emphasis-bg`          | `rgb(255 111 97 / 10%)`  | `strong` / `em` highlight        |
| `emphasis-decoration`  | `rgb(52 48 64 / 25%)`    | `em` dotted underline            |
| `search-highlight-bg`  | `rgb(224 108 117 / 10%)` | Matched-term highlight           |
| `success-bg`           | `rgb(34 197 94 / 10%)`   | Copy-button "copied" state       |

### Success palette
`green-400 #4ade80 · green-500 #22c55e · green-600 #16a34a` — copy-button feedback only.

## 3. Typography Rules

### Font stacks

| Family | Stack                                                                                          |
|--------|------------------------------------------------------------------------------------------------|
| Sans (base + headings) | `-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Helvetica Neue', sans-serif` |
| Mono   | `ui-monospace, 'SFMono-Regular', 'SF Mono', Menlo, Consolas, 'Liberation Mono', monospace`     |

System fonts only — **no web fonts are shipped** (keeps output lightweight; see
§7). Headings reuse the base sans; mono is used for code, method headings, and
type signatures.

### Type scale

| Token   | rem      | px | Token   | rem      | px |
|---------|----------|----|---------|----------|----|
| `xs`    | 0.75     | 12 | `2xl`   | 1.5      | 24 |
| `sm`    | 0.875    | 14 | `3xl`   | 1.875    | 30 |
| `base`  | 1        | 16 | `4xl`   | 2.25     | 36 |
| `lg`    | 1.125    | 18 | `5xl`   | 3        | 48 |
| `xl`    | 1.25     | 20 |         |          |    |

Weights: `normal 400 · medium 500 · semibold 600 · bold 700`.
Line heights: `tight 1.25 · normal 1.5 · relaxed 1.625` (body is relaxed).

### Heading ladder (`main`)

| Element | Size       | Weight    | Notes                                   |
|---------|------------|-----------|-----------------------------------------|
| `h1[class]` (page title) | `2.5em` | bold | Accent color; the class/module name     |
| `h1`    | `3xl` (30) | bold      | tight line-height                       |
| `h2`    | `2xl` (24) | semibold  | `margin-top: space-8`                   |
| `h3`    | `xl` (20)  | semibold  | `margin-top: space-6`                   |
| `h4`    | `lg` (18)  | medium    |                                         |
| `h5`/`h6` | `base` (16) | medium  |                                         |

All headings render in `accent-primary` and carry
`scroll-margin-top: calc(header-height + 2rem)` so anchored links clear the
sticky header.

### Color × text pairing

- Body links default to **text color**, not accent — only hover reveals accent
  (`link-hover`). Keeps prose calm.
- Status/role meaning in search badges is carried by **both** a tinted
  background and a text color, never color alone.
- `strong` and `em` share the accent color + `emphasis-bg` tint; `em` adds a
  dotted underline so emphasis survives in monochrome.

## 4. Component Stylings

Spacing/radius tokens referenced below resolve in §5/§6.

### Header bar (`header.top-navbar`)

| Property   | Value                                                       |
|------------|-------------------------------------------------------------|
| Layout     | Sticky top, `z-fixed` (300), `height: 64px`                 |
| Background | `background-primary` + `border-bottom` hairline + `shadow-sm` |
| Padding    | `0 space-6` (24 px) · gap `space-8` (mobile: `space-4`)      |
| Brand      | `xl` (20) semibold; hover → accent                          |
| Search     | `width: 400px` desktop field (see Search below)             |

### Theme toggle (`.theme-toggle`)

| Property | Value                                                            |
|----------|------------------------------------------------------------------|
| Box      | `2.5rem` square · `radius-md` · 1px `border-default`             |
| Hover    | `background-secondary`, accent border + text, `scale(1.05)`      |
| Active   | `scale(0.95)`                                                    |
| Focus    | accent border + `0 0 0 3px accent-subtle` ring                   |
| Icon     | rotates `15deg` + `scale(1.1)` on hover, `--ease-out-smooth`     |

### Left navigation (`#sidebar-navigation` + `.nav-section`)

| Property        | Value                                                        |
|-----------------|--------------------------------------------------------------|
| Surface         | `nav-bg`, `border-right` hairline, sticky under header, full-height scroll; rules are scoped to `#sidebar-navigation` so the right TOC can use its own `<nav>` semantics |
| Scrollbar       | 6 px, `border-default` thumb (custom, thin)                  |
| Section heading | `lg` semibold in **accent**, `border-bottom`                 |
| Section padding | `margin-top: space-6`, `padding: 0 space-6`                  |
| Link hover      | `padding-left: space-1` nudge + `link-hover` color + underline |
| Collapsible     | `<details>` with `::details-content` `block-size` 200 ms ease + `interpolate-size: allow-keywords` |
| Section icon    | `1.25rem`, accent color · chevron `1rem`, tertiary, rotates `90deg` open |
| Nested list     | `border-left` subtle hairline, `margin-left: 9px` (aligns to icon center) |

### Signature card (`.method-header` / `.method-heading`)

The defining content component — a method or attribute presented as a card.

| Property        | Value                                                        |
|-----------------|--------------------------------------------------------------|
| Card            | `sig-bg` background · 1px `border-subtle` full border · `radius-md` |
| Layout          | two-column grid, `minmax(0, 1fr) auto`, `gap: space-4`; narrows to one column on `≤480px` |
| Padding         | `space-4` desktop, `space-2` on `≤480px`                     |
| Heading group   | `.method-heading-group`, `min-width: 0`; contains method heading(s) and optional method type signature |
| Heading         | flex column, **mono**, `lg`, semibold; name `overflow-wrap: anywhere` |
| Type signature (method) | `pre.method-type-signature` — transparent, dotted top rule via `::before`, `sm` mono, `text-tertiary`, tight, `pre-wrap` |
| Type signature (attribute) | inline after `[RW]` badge, `sm` mono, `text-secondary` |
| Source toggle (`.method-controls summary`) | static grid action inside the card header; inline-flex with `{}` `.method-source-icon`, accent text on `accent-subtle`, `radius-sm`, `sm` medium; hover `primary-100` bg + `primary-300` border + `translateY(-1px)`; active `scale(0.96)` |
| Source reveal   | `.method-source-code` animates `max-height`+`opacity`+`translateY`, `--duration-medium`/`-fast` + `--ease-out-smooth`; revealed `<pre>` uses the standard code border |
| `:target`       | method-detail gets a neutral left-rail indent treatment       |

### Code (`pre`, `code`) + copy button

| Property      | Value                                                          |
|---------------|----------------------------------------------------------------|
| `pre`         | mono, `code-bg`, 1px `code-border`, `radius-md`, `space-4` pad, `sm`, `x-scroll` |
| inline `code` | `code-bg`, 1px `border-subtle`, `0.125rem 0.375rem` pad, `radius-sm`, `0.9em` |
| Copy button   | absolute top/right `space-2`, `2rem` square, `radius-sm`, opacity `0.6` |
| Copy hover    | opacity `1`, `background-tertiary`, `translateY(-1px)`, `shadow-md` |
| Copy active   | `scale(0.92)`                                                  |
| Copied        | `success-bg` + green-500 border + green-600 check (green-400 in dark) |

### Tables

`th`/`td` padding `0.2em 0.4em`, 1px `border-default`; `th` uses
`th-background`; even rows use `td-background`. On `≤480px` tables scroll
horizontally.

### Search

| Element                          | Value                                                       |
|----------------------------------|-------------------------------------------------------------|
| Desktop field (`#search-field`)  | full-width, `space-2 space-4` pad, 1px border, `radius-md`, `base`; focus → accent border + `0 0 0 3px accent-subtle` |
| Desktop dropdown (`#search-results-desktop`) | absolute, `width: 400px`, `max-height: 60vh`, `radius-lg`, `shadow-lg`, `z-popover` (500) |
| Mobile modal (`.search-modal-content`) | centered card, `max-width: 600px`, `max-height: 80vh`, `radius-lg`, `shadow-xl` |
| Modal result item                | `space-3 space-4` pad, `radius-md`, hover `background-secondary` |
| Servlet field                    | pill `border-radius: 1.25rem`, leading 🔍 (`\1F50D`) glyph   |
| Result lines                     | `.search-match` `base` · `.search-namespace` `sm` secondary · `.search-snippet` `sm` tertiary |
| Type badge (`.search-type-*`)    | inline-block, `space-0 space-2` pad, `xs`, weight 500, `radius-sm`, colors per §2 |
| Matched term (`li em`)           | `search-highlight-bg`, `font-style: normal`                 |

### Right TOC (`#table-of-contents`)

| Property      | Value                                                          |
|---------------|----------------------------------------------------------------|
| Layout        | sticky under header, `padding: space-8 space-6`, `border-left` hairline; its internal `.toc-nav` owns its scroll area and does not inherit left-navigation chrome |
| Heading       | `lg` semibold, `text-primary`                                  |
| Indent        | `.toc-h2` `margin-left: space-4`, `.toc-h3` `space-8`; nested `ul` border-left + `space-4` pad |
| Link          | block, `text-secondary`; hover `link-hover` + underline; focus-visible accent outline |
| **Active (scroll-spy)** | `accent-primary` + `font-weight: medium`             |
| Visibility    | hidden `≤1279px`                                               |

### Footer (`footer.site-footer`) + breadcrumb

Footer: `background-secondary`, `border-top`, `padding: space-12 space-6`;
columns via `repeat(auto-fit, minmax(200px, 1fr))`, gap `space-8`; column `h3`
is `sm` semibold with `letter-spacing: 0.05em`; `.footer-bottom` is centered
`xs` `text-tertiary` credit. Breadcrumb (`ol.breadcrumb`) is a flex row at
`125%` font-size.

## 5. Layout Principles

### Spacing scale (`--space-*`)

```
1 · 2 · 3 · 4 · 5 · 6 · 8 · 12 · 16        (4 · 8 · 12 · 16 · 20 · 24 · 32 · 48 · 64 px)
```

Non-linear above `6` — there is no `7`/`9`/`10`/`11`. Anything outside this list
is suspect; reach for the nearest token.

### Page grid (`body`)

| Mode               | Grid                                                            |
|--------------------|----------------------------------------------------------------|
| Default (2-col)    | areas `header / "nav main" / "nav footer"`; columns `300px 1fr` |
| `.has-toc` (3-col) | adds a TOC column `minmax(240px, 18%)`                          |
| `≤1023px`          | collapses to `flex` column; nav becomes an off-canvas drawer    |

Key layout tokens: `sidebar-width 300px · content-max-width 800px ·
header-height 64px · search-width 400px · toc-width minmax(240px, 18%)`.

### Reading measure & density

`main` is capped at **800 px** and centered, with `space-12 space-8` (48 / 32 px)
padding and `relaxed` (1.625) line-height — a comfortable column for prose and
signatures. The left nav and right TOC are sticky and independently scrollable,
so the reading column never jumps.

### Alignment

- Content + nav + TOC: leading-aligned.
- Method source toggle: static trailing action inside the signature card grid.
- Centered text is reserved for empty states and the footer credit.

## 6. Depth & Elevation

Hierarchy comes from **hairline borders, surface tinting, and a restrained
shadow set** — used together. (Unlike some flat systems, Aliki *does* use
shadows, but only for genuinely floating surfaces.)

### Radius scale

| Radius            | Usage                                                   |
|-------------------|----------------------------------------------------------|
| `sm` (4 px)       | inline code, badges, copy button, source-toggle, chips   |
| `md` (6 px)       | `pre`, header controls, theme toggle, search field, modal (small screens) |
| `lg` (8 px)       | search dropdown, search modal content                    |
| `1.25rem` (20 px) | servlet search field (pill)                              |

### Shadow scale

| Token | Light (`rgb(0 0 0 / 10%)`)                 | Dark (40% opacity) | Used by                |
|-------|--------------------------------------------|--------------------|------------------------|
| `sm`  | `0 1px 3px`, `0 1px 2px -1px`              | same geometry      | header bar             |
| `md`  | `0 2px 8px`                                | same               | copy-button hover      |
| `lg`  | `0 10px 15px -3px`, `0 4px 6px -4px`       | same               | nav drawer, search dropdown |
| `xl`  | `0 20px 25px -5px`, `0 8px 10px -6px`      | same               | search modal           |

### Borders & focus

- Three hairline weights: `border-subtle` → `border-default` → `border-emphasis`.
  The 1 px hairline is the primary divider everywhere (nav, header, cards, table).
- **Focus ring:** `box-shadow: 0 0 0 3px accent-subtle` on interactive controls
  (theme toggle, search field, copy button) paired with an accent border.

### Motion

| Token             | Value                       | Where                                  |
|-------------------|-----------------------------|----------------------------------------|
| `transition-fast` | `150ms ease-in-out`         | color/background hovers                |
| `transition-base` | `200ms ease-in-out`         | links, chevron rotation                |
| `transition-slow` | `350ms ease-in-out`         | —                                      |
| `ease-out-smooth` | `cubic-bezier(0.4, 0, 0.2, 1)` | theme-toggle icon, source reveal    |
| `duration-fast/​base/​medium` | `250 / 300 / 350ms` | source-code reveal, theme icon         |

Z-index ladder: `fixed 300 · modal 400 · popover 500`.

## 7. Do's and Don'ts

### Load-bearing guardrails

1. **The red is fixed identity.** Reskin via other tokens freely, but **do not
   change the `--color-primary-*` hue without approval** — it cascades across
   headings, links, active TOC, signature borders, and badges.
2. **Never break static / offline viewing.** Output must render with no server
   on GitHub Pages and `file://`. Don't introduce anything that needs a backend
   or a same-origin `fetch()`.
3. **Accessibility bar = WCAG 2.1 AA + honor `prefers-reduced-motion`.** Treat
   gaps as bugs. ⚠️ **`prefers-reduced-motion` is not yet implemented** (nav
   collapse, TOC scroll, source-reveal, and `::details-content` all animate
   unconditionally) — adding a reduced-motion block is the top open item (§8).
4. **Edit light *and* dark together.** Any new color/semantic token must be
   declared in both `:root` and `[data-theme="dark"]`.
5. **Change tokens, not literals.** Components must reference `--*` tokens.

### Do / Don't

| Don't                                               | Do                                                        |
|-----------------------------------------------------|-----------------------------------------------------------|
| Retune the brand red                                | Reskin via neutrals / semantic tokens; keep the red hue   |
| Hard-code hex in a component rule                   | Reference a semantic token (`accent-primary`, `text-…`)   |
| Add a color in `:root` only                         | Add it to the `[data-theme="dark"]` block too             |
| Use `prefers-color-scheme` for dark                 | Key off the `[data-theme="dark"]` attribute (JS-set)      |
| Add a syntax token class without CSS                | Add `.{ruby,c,sh}-*` rule **and** the emitter together    |
| Ship a web font or image sprite                     | Stay on the system font stack; inline SVG only            |
| Invent a 6th syntax color                           | Map onto the existing `--code-*` seven                    |
| Animate with no reduced-motion guard                | Wrap non-essential motion in `prefers-reduced-motion`     |
| Convey meaning by color alone                       | Pair color with text/weight (badges, emphasis)            |
| Add decorative shadows                              | Use the `sm/md/lg/xl` set only for truly floating surfaces |

## 8. Responsive Behavior

The generated docs are fluid; the layout adapts at five breakpoints.

| Breakpoint            | Behavior                                                                                   |
|-----------------------|--------------------------------------------------------------------------------------------|
| `≤1279px`             | Right **TOC hidden**; `.has-toc` grid drops to 2 columns                                    |
| `≤1023px`             | Body → flex column; **left nav becomes an off-canvas drawer** (`300px`, `shadow-lg`) with an `overlay` backdrop + hamburger (`#sidebar-navigation-toggle`); desktop search swaps to a mobile **search modal**; header padding/gap tighten to `space-4` |
| `768–1023px` (tablet) | Header `0 space-6`; main `space-8 space-6`, full-width                                       |
| `≤480px`              | Nav `width: 85%` (max `320px`); main padding `space-4`; tables scroll; method heading → `base`; signature card padding tightens |
| `≤420px`              | Search modal padding tightens                                                               |
| `(hover: none)`       | Copy button rests at opacity `0.7`                                                           |

### Color scheme

Dark mode is the **`[data-theme="dark"]` attribute** on the document root, set by
`theme-toggle.js` and persisted in `localStorage` (`rdoc-theme`). It is **not**
driven by `prefers-color-scheme`. Light is the default.

### Reduced motion ⚠️ (target, not yet implemented)

The standard: under `prefers-reduced-motion: reduce`, all non-essential
transitions/animations should collapse to instant — the nav-section
`::details-content` block-size tween, the method-source-code reveal, the
theme-toggle icon spin, chevron rotations, and any smooth-scroll. This guard
does not exist yet and should be added to satisfy the AA + reduced-motion bar.

## 9. Agent Prompt Guide

A cheat-sheet for prompting AI tools (or new contributors) to produce
Aliki-consistent UI.

### One-line palette identifier

| Mode  | accent    | bg        | fg        | accent-hover |
|-------|-----------|-----------|-----------|--------------|
| Light | `#e62923` | `#ffffff` | `#1c1917` | `#b8211c`    |
| Dark  | `#eb544f` | `#1c1917` | `#fafaf9` | `#f07f7b`    |

Neutral ramp (warm stone): `#fafaf9 #f5f5f4 #e7e5e4 #d6d3d1 #a8a29e #78716c #57534e #44403c #292524 #1c1917`.

### Syntax colors (light → dark)

```
blue   #1d4ed8 → #93c5fd     purple #7e22ce → #c084fc
green  #047857 → #34d399     red    #dc2626 → #f87171
orange #d97706 → #fbbf24     cyan   #0891b2 → #22d3ee
gray   #78716c → #a8a29e
```

### Font stacks

```
Sans/Headings: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, … sans-serif
Mono:          ui-monospace, 'SFMono-Regular', 'SF Mono', Menlo, Consolas, … monospace
(no web fonts — system stacks only)
```

### Ladders

```
Type:    12 · 14 · 16 · 18 · 20 · 24 · 30 · 36 · 48   (xs…5xl)
Spacing:  4 ·  8 · 12 · 16 · 20 · 24 · 32 · 48 · 64   (space-1…16)
Radius:   4 ·  6 ·  8   (+ 20px servlet pill)
Layout:  sidebar 300 · content 800 · header 64 · search 400 · toc minmax(240, 18%)
```

### Ready-to-use prompt fragments

> "Use the Aliki theme: red accent `#e62923` (light) / `#eb544f` (dark), warm
> stone neutrals, page bg `#fff` / `#1c1917`, text `#1c1917` / `#fafaf9`. Body
> links are text-colored and only turn red on hover. Dark mode keys off a
> `[data-theme="dark"]` attribute, not `prefers-color-scheme`."

> "Layout: 2-column (300 px nav + 800 px content), optional 3rd TOC column
> `minmax(240px, 18%)`; 64 px sticky header. Spacing scale
> 4/8/12/16/20/24/32/48/64; radii 4/6/8. Hairline 1 px borders + a restrained
> sm/md/lg/xl shadow set for floating surfaces only."

> "Type: system sans for everything, mono for code + method headings + RBS
> signatures. Heading ladder h1 30 / h2 24 / h3 20, all in the red accent.
> Comfortable density, 1.625 body line-height. No web fonts, no image sprites."

> "Don't retune the red hue, don't hard-code hex (use `--color-*` tokens), don't
> add a token to `:root` without the dark block, and wrap any new animation in a
> `prefers-reduced-motion` guard."

### Where to look in `css/rdoc.css`

| Asking about…        | Read this                                                       |
|----------------------|-----------------------------------------------------------------|
| Tokens (light)       | `:root` — §1 banner "Design System"                             |
| Tokens (dark)        | `[data-theme="dark"]` block                                     |
| Layout grid          | §2 "Global Styles & Layout"                                     |
| Code / copy button   | §5 "Code and Pre"                                               |
| Header / theme toggle| §6 "Header (Top Navbar)"                                        |
| Left nav (`#sidebar-navigation`) | §7 "Navigation (Left Sidebar)"                             |
| Signature cards, syntax classes | §8 "Main Content" (syntax classes ~`.ruby/.c/.sh-*`) |
| Search (modal + dropdown + badges) | §9 "Search Modal" + the `.search-results` block   |
| TOC scroll-spy       | §10 "Right Sidebar - Table of Contents"                         |
| Footer               | §11 "Footer"                                                    |
| Theme attribute / persistence | `js/theme-toggle.js` (`data-theme`, `localStorage`)    |
