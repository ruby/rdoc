# Markdown for AI Agents — Research

## The Problem
How does an AI agent programmatically get Markdown from a documentation site?

## Current Approaches

### llms.txt (closest to a standard)
- `/llms.txt` (overview + links) and `/llms-full.txt` (complete Markdown)
- Adopted by Anthropic, Cloudflare, Read the Docs, Mintlify (~784 sites)
- No major LLM provider officially consumes it
- Stan already evaluated and rejected based on impact data

### External Proxies
- **Jina Reader** (`r.jina.ai/URL`) — prefix any URL to get Markdown. Widely used.
- **Firecrawl** — API that crawls sites and returns clean Markdown for RAG pipelines
- **Trafilatura, readability** — Libraries for extraction

### Source-as-Markdown (MDN Model)
- MDN content is authored as Markdown on GitHub (`mdn/content`)
- 1:1 mapping between rendered URL and raw `.md` on GitHub
- AI can fetch raw Markdown from GitHub given any MDN URL

### Content Negotiation
- No `Accept: text/markdown` convention exists
- No `.md` URL extension convention
- llms.txt sidesteps content negotiation entirely (separate well-known path, like robots.txt)

## What Doesn't Work Well
- "Copy as Markdown" buttons — requires human action, bad UX
- Manual conversion — transitional approach at best

## Open Questions
- How does an AI agent know Markdown is available without trying?
- Should doc sites serve Markdown at a predictable URL pattern?
- Or should the rendering tool (RDoc) generate Markdown output alongside HTML?
- If RDoc generates `.md` files, how are they discovered?

## Takeaway
No standard exists yet. The field is split between well-known paths (llms.txt), external proxies (Jina), and source-as-Markdown (MDN). This is a genuinely open problem worth discussing honestly.
