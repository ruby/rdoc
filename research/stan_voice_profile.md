# Stan Lo - Voice & Personality Profile

Based on a close reading of 13 blog posts (2022-2026), his talks page, and monthly updates at st0012.dev.

---

## Core Voice: The Honest Practitioner

Stan writes like someone who is genuinely working through problems in front of you. He is not performing expertise --- he is sharing what he learned, including what confused him. His authority comes from doing the work, not from claiming status.

The single most defining trait: **he leads with what he did not know before he explains what he does know.**

Examples:
- JIT post: "I know how to enable it... But my understanding seems to end here."
- AI language barriers post: "I was a Ruby-only developer... something I'd always dreamed of but was terrified to attempt."
- Blog fix post: matter-of-factly reports what went wrong with his own site.

This is not false humility. It is the voice of someone who genuinely finds the process of learning interesting and wants to document it honestly.

---

## Opening Style: Situational, Not Theatrical

Stan does not use hooks in the conventional "content marketing" sense. He does not open with provocative claims, rhetorical questions, or dramatic stakes. Instead he opens with **context-setting** --- where he is, what he was doing, what prompted the post.

Typical patterns:
- "IRB 1.6 has been released and will become Ruby 3.2's built-in IRB version." (IRB post --- just states the fact)
- "Ruby 3.4 isn't just about shiny language features; it also comes with meaningful documentation updates." (Ruby 3.4 docs post --- mild reframe, then straight into substance)
- "For a decade (2014-2024), I was a Ruby-only developer." (AI barriers post --- personal fact, then builds from there)
- "This is a quick & unpolished collection of my Ruby debugging tips and recommendations." (Debugging tips --- literally announces it is unpolished)

**For a talk:** do not start with a big dramatic opener. Start with a concrete, grounded statement about what the talk is about or what prompted it. If there is a personal angle, state it plainly.

---

## Tone: Conversational-Professional, Never Performative

Stan's writing sits in a specific zone: warm but not chatty, professional but not stiff. Key characteristics:

- **First person throughout.** He says "I" constantly and without apology.
- **Parenthetical asides** are frequent and natural: "(In the rest of the article, I'll use `debug` to refer to `ruby/debug`)" --- these feel like spoken clarifications.
- **Short, direct sentences** mixed with longer explanatory ones. He does not write in a uniform cadence.
- **No exclamation marks** in technical explanations. Very rare in general --- used only in genuine enthusiasm, never for emphasis.
- **Contractions** used naturally (isn't, don't, we'll, I'd).
- **"We" for community, "I" for opinions.** He is precise about this distinction.

Phrases that capture his register:
- "But here's the thing:"
- "So I want to use this post to..."
- "I hope you find these tips useful."
- "I'll keep posting news like this here too"

---

## How He Explains Technical Concepts

Stan's approach is **question-driven and incremental**, not analogy-heavy. He is much more likely to walk through actual code and output than to reach for a metaphor.

Pattern:
1. State what he did not understand
2. Ask explicit questions (sometimes literally numbered)
3. Show real code/output
4. Explain what the code reveals
5. Occasionally use diagrams (ASCII flowcharts for the JIT post)

He does use analogies sparingly and only when they genuinely clarify:
- "AI acts as a second pair of eyes, unblocking us from silly rookie mistakes"
- "we act as a pair of engineers with different strengths"

He does **not** use the "imagine you're a..." or "think of it like a..." patterns common in conference talks.

**For a talk:** lean into showing real things (code, screenshots, tool output) over abstract diagrams. Frame sections as questions the audience might have. Do not over-analogize.

---

## Opinions: Direct but Qualified

Stan has strong opinions and states them clearly, but he almost always includes the boundary conditions of his view. He does not hedge out of uncertainty --- he hedges because he genuinely sees the other side.

Pattern: **State the opinion, then immediately acknowledge the limitation.**

Examples:
- "AI amplifies existing developer habits, good or bad" (strong claim) followed by nuanced exploration of what that means for different kinds of developers.
- Recommends debug over byebug but opens with "Disclaimers: I'm not as experienced with byebug as with debug."
- Advocates Markdown over RDoc markup but frames it as the community's direction, not his personal decree.
- "AI accelerates learning, but human expertise remains irreplaceable for course correction."

He does not write disclaimers performatively. He means them.

**For a talk:** make claims directly, then immediately give the honest caveat. Do not soften the claim beforehand --- state it, then qualify it.

---

## How He Handles Controversy

On the AI-and-open-source topic (his most potentially controversial post), Stan:
- Opens by positioning himself as "not an AI expert"
- Presents his view as time-stamped observation ("end of 2025") that may change
- Avoids moral judgment of people, focuses on behaviors and dynamics
- Names the structural inequality (maintainers lack tools contributors have) without being angry about it
- Gives concrete, actionable advice rather than philosophical hand-wringing

He does not engage in culture-war framing. Even when discussing something polarizing like AI in open source, he stays practical: what can maintainers do, what can contributors do, what can companies do.

---

## Personal Anecdotes: Rare but Potent

Stan does not tell many stories about himself. When he does, they serve a structural purpose in the argument, not an emotional one. The key biographical facts he shares:

- **Ruby-only developer for a decade (2014-2024).** This fact appears in the AI barriers post as the foundation for the entire argument.
- **Terrified to work in other languages.** Said plainly, not dramatized.
- **Won RubyPrize 2025.** Listed on his talks page without commentary.
- **Maintains IRB, RDoc, debug.gem, contributes to ZJIT.** These appear as context, never as credentials.
- **Bilingual (English/Chinese).** Maintains a Chinese version of his blog with original content for that audience.
- **Works at Shopify** on the Ruby DX team. Mentioned as context, not branding.

He does not tell "origin story" narratives. He does not describe struggles in emotional terms. He states facts about his experience and lets them speak.

**For a talk:** if sharing a personal moment, keep it factual and brief. "I was terrified" works. A three-minute story about the terror does not.

---

## How He Credits Others

Stan is conspicuously generous with credit. This is one of his most distinctive traits.

- Names specific people by name and handle: "@k0kubun and I made" (IRB post), lists 27+ RDoc contributors by handle (Ruby 3.4 docs post).
- Credits the conditions that enabled his growth: "Shopify's Ruby and Rails Infrastructure team is packed with experts who genuinely love sharing their knowledge. Alexander Momchilov, Alexandre Terrasa, Max Bernstein, and many others have been incredibly generous with their time."
- Credits tools and opportunities before crediting himself: he lists mentors, team roadmap changes, and AI tools as the three factors enabling his multi-language shift, placing himself last.
- References others' work with links: "check out this RailsAtScale post by Max", "Kevin Newton wrote..."

**For a talk:** name people. Do not say "some people on the team helped" --- say their names. Do not say "we built" when a specific person drove it.

---

## Humor

Stan's humor is **dry, understated, and rare.** He does not use it as a crutch or a rhythm device.

The clearest example: "I'm genuinely excited that I can now address website issues and publish content from my phone. I'm less excited about hearing 'You can fix this on your phone' in the future." (Blog fix post)

This is the humor of someone who can see the irony in their own situation. It comes at the end, as a throwaway, not as a setup-punchline structure.

Other traces:
- "(It's not named `help` because IRB already uses `help` to look up API documents. I'll explain more about this in the next section.)" --- the parenthetical acknowledging a slightly absurd naming situation.
- Calling his debugging tips "quick & unpolished" --- self-deprecating about the format, not about the content.

**For a talk:** humor should land as an aside, not as a bit. One well-placed dry observation per section is more Stan than recurring jokes.

---

## Self-Assessment: Confident in Work, Humble About Knowledge

Stan is not self-deprecating. He does not put himself down. But he is genuinely modest about the boundaries of his knowledge:

- Confident: publishes roadmaps, advocates for specific technical directions, built tools used by the community.
- Humble: "I assumed... But Ruby keeps both, for good reason." He reports being wrong without embarrassment.
- Honest: "It's hit or miss for the last three" (AI capabilities). He does not oversell.

He has the confidence of someone who ships things and the humility of someone who knows there is more to learn. These coexist naturally --- they do not feel like a performance.

---

## Structure & Pacing

Stan structures posts in three main patterns:

1. **Numbered tips/features** (debugging tips, IRB features, byebug comparison): flat lists with brief explanations. Efficient, reference-oriented.
2. **Narrative progression** (AI barriers, AI and open source): personal observation leads to analysis leads to recommendations. Building toward a thesis.
3. **Roadmap/update** (RDoc roadmap, Ruby 3.4 docs): here-is-what-happened, here-is-what-is-next. Forward-looking.

In all three patterns, sections are short. He rarely writes more than 3-4 paragraphs before a new heading. He uses headers liberally. Tables and comparison charts appear frequently.

**For a talk:** use visible structure. Short sections with clear transitions. Do not build to one big reveal --- give the audience value incrementally throughout.

---

## The "Stan" Fingerprint: Summary for Talk Writing

If you are writing a talk that should sound like Stan Lo, these are the non-negotiable elements:

1. **Start grounded.** Open with what is, not what could be.
2. **Show your learning arc.** "I didn't know X. I investigated. Here's what I found."
3. **Be direct about opinions.** "I think X." Then immediately: "But here's the caveat."
4. **Name people.** Every collaborator, every contributor, every influence.
5. **Show real things.** Code output, tool screenshots, actual diffs. Not abstract slides.
6. **Keep humor dry and incidental.** If it is funny, let it be funny quietly.
7. **Do not oversell.** If something is limited, say so. If the future is uncertain, say so.
8. **End practically.** Give the audience something to try, install, or contribute to.
9. **Write short sections.** Move quickly between topics. Respect the audience's time.
10. **Never perform expertise.** Let the work demonstrate competence. Let the honestly-stated gaps demonstrate integrity.

The overall effect is: a smart, generous person who takes the work seriously but not themselves. Someone you would want to pair with because they would tell you what they actually think while being genuinely curious about what you think.
