# Rustdoc LLM Text Format RFC — rust-lang/rfcs#3751

**PR:** https://github.com/rust-lang/rfcs/pull/3751
**Author:** Folyd
**Date:** December 2024
**Status:** Not merged. Received significant pushback.

## The Proposal

Add an LLM-friendly text output format to `rustdoc`. The author needed an LLM to use the `oas3` crate but got code for v0.4.0 (knowledge cutoff) instead of v0.13.1. The existing rustdoc JSON format is 5.5MB for this crate — too noisy for LLM consumption. A text summary would be <1KB with just the public API.

Proposed URL pattern: `https://docs.rs/oas3/0.11.3/docs.txt`

## Arguments FOR

**Folyd (author):**
- Rustdoc's JSON format is 161,873 lines for a single crate — unsuitable for LLM context windows
- Text formats for LLMs are becoming standard (cites llms.txt)
- AI models can understand arbitrary text — what they need is a suitable format, not more intelligence
- The problem isn't HTML comprehension, it's engineering effort to extract useful info from complex pages

**lebensterben:**
- The format is useful to humans too — "much more readable than other formats when you just need a synopsis of a library"

**ahicks92 (initial skeptic, then converted by Copilot experience):**
- Personal account: Copilot autocompleted full trait impls, macros, 20-30 lines at a time — in niche audio synthesis code doing "horrifying things to the type system"
- "Does my chores, and sometimes reads my mind, producing code in my style" is super valuable
- Two usage modes: beginners chat with it to learn, experts lean on it for boring parts

## Arguments AGAINST

**clarfonthey:**
- "I prefer my oceans unboiled" (environmental cost of LLM usage)
- You can already view collapsed code in IDEs — not adding anything new for humans
- The format isn't searchable, so not useful to humans either
- Feeding info into "statistical models which cannot understand it" is not a good use case
- Links to arxiv.org/abs/2410.05229 (paper on limits of LLM understanding)

**juntyr:**
- The JSON format is already meant to be machine-consumed
- Going through a textual representation just to re-obtain semantic information seems wasteful
- Why not use an external tool like `rusty-man` to produce reduced output?

**ahicks92 (despite being pro-AI, argues against THIS approach):**
- No real reason this can't be an external tool — RFC doesn't have a path for consumption
- Nobody in AI has standardized how to provide context yet
- "Every time anyone says 'AI is like X', 6 months from now that's no longer the case"
- This feels premature given pace of progress
- "Consume complex HTML" will likely be a solved problem by the time this stabilizes
- Rust's RFC process is too slow (4+ months) for a field with 2-year product cycles
- "This RFC argues for stripping context. History argues for providing more context."
- Anthropic is standardizing context via MCP; OpenAI claims coding AI better than most devs
- Would bet significant money that "make a text version as humans" won't matter in 2 years

**workingjubilee (T-rustdoc team member):**
- LLMs are in-flux technology with changing context windows, compression methods, and input requirements
- A "redux" format targeted at current LLM usage is ill-suited for a stability guarantee
- "Very likely it is not the desired format within 3 months, never mind 3 years"
- **Could simply be implemented as a library** that filters the JSON output
- Rustdoc already has a JSON format — use that as the foundation for external tools

**aDotInTheVoid:**
- "The JSON format allows for this to be done outside of rustdoc, and there's no advantage to having this be in rustdoc itself"

## Key Themes from the Discussion

1. **External tool vs. built-in**: Strong consensus that this should be an external tool consuming rustdoc's JSON, not a core rustdoc feature. Mature language toolchains shouldn't bake in AI-specific formats because the requirements change too fast.

2. **Pace of change**: Multiple commenters argue AI capabilities advance faster than RFC processes. Any format designed for today's LLMs will be obsolete by the time it ships.

3. **Strip context vs. provide more context**: The fundamental tension — LLMs currently have limited context windows (argues for stripping), but context windows are growing fast and AI is getting better at processing complex inputs (argues for providing everything).

4. **Environmental concerns**: "Ocean boiling" argument against LLM-optimized tooling.

5. **JSON as the right intermediate format**: Rustdoc already has machine-readable JSON output. The community prefers external tools that transform this JSON rather than adding new output formats to rustdoc itself.

## Relevance to RDoc

The Rust community rejected baking LLM-specific output into rustdoc. But their situation differs from RDoc's:
- Rustdoc already has a JSON output format. RDoc doesn't have an equivalent machine-readable output.
- Rust's RFC process is slow. RDoc can ship features faster as a gem.
- The counter-arguments about pace of change apply equally to RDoc — any AI-specific format may be obsolete soon.
- The "external tool" argument is strong: maybe RDoc should provide good structured data (Markdown, type info) and let external tools (MCP servers, skills) handle AI-specific consumption.
