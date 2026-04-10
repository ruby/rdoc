# AI Documentation Skills — Research

## Key Insight
No major doc generator (JSDoc, YARD, Sphinx, RDoc) has shipped AI-specific features yet. All AI integration happens at the consumption layer (MCP servers), not the generation layer.

## Doc Generator AI Efforts

### Rustdoc — Markdown Output (Pre-RFC, active)
- Proposal: `cargo doc --output-format markdown` for agent-consumable API docs
- Also: `rustdoc-md` crate that converts rustdoc JSON to Markdown today
- Cargo issue: github.com/rust-lang/cargo/issues/16720
- Internals discussion: internals.rust-lang.org/t/pre-rfc-add-llm-text-version-to-rustdoc/22090
- **Most relevant parallel to what RDoc could do**

### llms.txt Standard
- `/llms.txt` (summaries) and `/llms-full.txt` (full Markdown)
- 600+ adopters: Anthropic, Stripe, Cloudflare, Cursor
- Doc-site-side effort, not doc-generator-side
- Stan already evaluated and rejected based on impact data

## Consumption-Layer Tools (MCP Servers)

### Dash MCP Server
- Official MCP from Kapeli (Dash 8+)
- Search installed docsets, list docs, extract content
- github.com/Kapeli/dash-mcp-server

### Context7 (Upstash)
- Resolves library names to version-specific documentation
- **Vercel measured: task pass rate 53% → 100% with version-matched docs**
- github.com/upstash/context7

### DevDocs MCP
- Multiple implementations wrapping devdocs.io
- Local search across downloaded docsets

### Espressif (ESP32)
- Hardware vendor shipping dedicated MCP server for their docs
- developer.espressif.com/blog/2026/04/doc-mcp-server/

## Takeaway for RDoc
- RDoc could be the first major doc generator to add AI-specific output
- Rust community is working on the same idea (Markdown output from doc tool)
- The consumption layer (MCP servers) is ahead of the generation layer
- Question: should RDoc generate Markdown alongside HTML, or expose an MCP interface?
