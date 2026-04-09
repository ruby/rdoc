# llms.txt Adoption Research (for RubyKaigi talk)

## Key Takeaway

llms.txt has **no measurable impact** on AI citations. As an RDoc maintainer, the trade-off (generation time + code complexity) isn't worth the negligible benefit.

## Adoption Numbers

- **10.13%** of ~300,000 domains analyzed have an llms.txt file (SE Ranking study)
- **~9 out of 10 websites** haven't adopted it
- **0.3%** adoption among the top 1,000 most visited websites globally
- Adoption is flat across traffic tiers: low (9.88%), mid (10.54%), high (8.27%)

## Effectiveness: No Measurable Impact

- **No correlation** between having llms.txt and AI citation frequency
- XGBoost ML model **improved accuracy when llms.txt was removed** as a variable
- Statistical methods used: Spearman correlation, XGBoost regression, SHAP analysis
- From mid-Aug to late Oct 2025: llms.txt pages received **zero visits** from Google-Extended, GPTBot, PerplexityBot, or ClaudeBot

## Platform Support

- **No major LLM provider** currently supports llms.txt (not OpenAI, not Anthropic, not Google)
- Google AI Overviews rely on traditional SEO signals, not llms.txt
- OpenAI/Anthropic have not officially recognized it as a ranking signal

## Sources

- [SE Ranking: "LLMs.txt: Why Brands Rely On It and Why It Doesn't Work"](https://seranking.com/blog/llms-txt/)
- [Search Engine Journal: "LLMs.txt Shows No Clear Effect On AI Citations, Based On 300k Domains"](https://www.searchenginejournal.com/llms-txt-shows-no-clear-effect-on-ai-citations-based-on-300k-domains/561542/)
- [Rankability LLMS.txt Adoption Report](https://www.rankability.com/llms-report/)
- [PPC.land: "llms.txt adoption stalls as major AI platforms ignore proposed standard"](https://ppc.land/llms-txt-adoption-stalls-as-major-ai-platforms-ignore-proposed-standard/)

## Talk Framing

This is a good example of **responsible maintainership** — evaluating hype vs. real impact before adding complexity. The data shows:

1. The spec exists but nobody reads it (zero bot visits)
2. Having it doesn't help (no citation correlation)
3. Major platforms explicitly don't use it
4. Adding it to RDoc would increase generation time and code complexity for all users

**Better alternative**: Focus on making documentation itself better (Markdown migration, better structure, RBS types) — these improve docs for both humans AND AI consumption naturally.
