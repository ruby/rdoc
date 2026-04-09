/**
 * Populate RubyKaigi 2026 talk slides.
 *
 * HOW TO USE:
 * 1. Open the presentation in Google Slides
 * 2. Extensions > Apps Script
 * 3. Paste this entire file, replacing any existing code
 * 4. Click Run (play button) — select populateSlides
 * 5. Authorize when prompted
 * 6. Wait ~10 seconds for all slides to populate
 */

function populateSlides() {
  var pres = SlidesApp.openById('1ufUFpNtWorgNaS-U8qjRLORyx_J5HHN_VuytfYQvWQY');
  var slides = pres.getSlides();

  // Slide content: [slideIndex (0-based), title, body, speakerNotes]
  // slideIndex 0 = title slide (p1), 1 = first content slide (p2), etc.
  var content = [

    // ─── SECTION 1: INTRO (2-3 min) ───

    [0, null, null,
      "Title slide. Pause, let audience settle."],

    [1, "The Future of Ruby Documentation",
      "Stan Lo\n\nRuby committer  ·  RDoc maintainer\nShopify — Developer Experience",
      "Introduce yourself. Ruby committer, RDoc maintainer since [year]. Work at Shopify on Developer Experience — Ruby & Rails Infrastructure team.\n\nMention key collaborators you'll shout out during the talk."],

    [2, "What we'll cover",
      "1. Long overdue — caught up\n    Aliki theme · Server mode · Prism parser\n\n2. Long overdue — getting there\n    Markdown support · RBS type signatures\n\n3. Getting ahead\n    AI, documentation, and the future",
      "Frame the talk as a three-part arc. RDoc hasn't had major investment in years — that changed this past year. We'll go through what's shipped, what's in progress, and how we think about the future."],

    // ─── SECTION 2: RDOC PRIMER + THE PROBLEM (2 min) ───

    [3, "What RDoc does",
      "Ruby's default documentation tool — ships with Ruby since 1.8\n\nParses: Ruby source · C extensions · Markup files\nGenerates: HTML docs · ri terminal docs\nMarkup: RDoc · Markdown · RD · TomDoc\n\nPowers docs.ruby-lang.org",
      "Quick primer. Most people have seen RDoc output but don't think about the tool itself. It's been part of Ruby for over 20 years. It parses your code and comments, and generates documentation in multiple formats."],

    [4, "The honest problem",
      "The Darkfish theme hadn't changed in years\nNo live preview for documentation authors\nRuby parser couldn't handle modern syntax\nMarkdown support was incomplete and buggy\nNo type information in documentation\n\nWe fell behind.",
      "Be honest about where things stood. Darkfish was functional but dated. No dark mode, limited mobile support, basic search. The Ruby parser used Ripper — couldn't handle endless methods, had tightly coupled comment handling. Markdown was bolted on with known issues. Contributors drifted to YARD or stopped writing docs entirely.\n\nBut this is a story about catching up, not complaining."],

    // ─── SECTION 3: CAUGHT UP (6 min) ───

    [5, "Long overdue — caught up",
      "",
      "Section divider. These are table-stakes features that modern documentation should have. Now we have them."],

    [6, "Aliki: before",
      "[Screenshot: Darkfish theme]\n\nThe Darkfish theme\nRDoc's default for over a decade",
      "INSERT SCREENSHOT of Darkfish. Point out: two-column layout, no dark mode, dated visual design, basic search, no mobile optimization, embedded fonts making output heavy."],

    [7, "Aliki: the new default",
      "[Screenshot: Aliki theme]\n\nThree-column layout with right-side TOC\nDark mode with system preference detection\nMobile-first responsive design\nMethod signature cards\nCopy-to-clipboard on code blocks\nC and bash syntax highlighting\nSVG icons · No embedded fonts",
      "INSERT SCREENSHOT of Aliki. Walk through the key improvements. Three columns: sidebar navigation, main content, and a right-side 'On This Page' table of contents with scroll-spy.\n\nDark mode respects system preferences and persists via localStorage. Mobile layout collapses to single column with hamburger menu.\n\nNamed after my cat."],

    [8, "Aliki: search",
      "[Screenshot: Aliki search UI]\n\nCustom search index — no separate generator pass\nTiered scoring: exact > prefix > substring > fuzzy\nNamespace-aware: \"String#\" filters to String methods\nType badges: classes · modules · methods · pages",
      "INSERT SCREENSHOT of search in action. The search was rebuilt from scratch — own index written as .js (not .json) to avoid CORS issues when viewing docs via file:// protocol. Ranking is type-aware: lowercase queries prioritize methods, uppercase prioritize classes."],

    [9, "Aliki: dark mode & mobile",
      "[Screenshots: light/dark side-by-side, mobile view]",
      "INSERT SCREENSHOTS. Side-by-side light and dark mode. Mobile view showing responsive layout, search modal, hamburger sidebar.\n\nDesign system uses CSS custom properties — 1994 lines of CSS with tokens for colors, spacing, typography, shadows, transitions."],

    [10, "rdoc --server",
      "[Demo: live reload in action]\n\nLive-reloading documentation preview\n$ rdoc --server\n$ make html-server  # in ruby/ruby\n\nZero external dependencies — uses Ruby's TCPServer\nIncremental re-parsing — only changed files\nBackground file watcher · Page caching",
      "INSERT PRE-RECORDED DEMO: edit a Ruby file, save, browser auto-refreshes.\n\nThis was one of the most requested features. Built with zero external dependencies — just Ruby's built-in TCPServer. No WEBrick, no rack, no gems.\n\nThe watcher polls file mtimes every second. On change, it only re-parses the changed files, clears contributions from the old version, and invalidates the page cache. Browser polls a /__status endpoint for live reload.\n\nAlso added 'make html-server' to ruby/ruby so core developers can preview documentation changes."],

    [11, "Prism migration",
      "tompng (Tomoya Ishida)\n\nRewrote 3 major subsystems:\n\n1. Ruby parser: Ripper → Prism AST visitor\n    Now handles modern Ruby syntax\n    Fixes 7+ long-standing issues\n\n2. Comment directive parser\n    :call-seq: · :nodoc: · :yields:\n    Fixed double-parsing architecture\n\n3. Inline formatting engine\n    Replaced string-replacing macros\n    with structured parser",
      "Shout out to tompng specifically. This is invisible work that made everything else possible.\n\nThe Ruby parser rewrite was a 20-month effort: added as opt-in (Jul 2024), spent months fixing edge cases and reducing output differences, flipped to default (Feb 2026). Old parser still available via RDOC_USE_RIPPER_PARSER=1.\n\nBut the Prism migration was just one of THREE major rewrites. The comment directive parser had a double-parsing bug where directives were parsed, removed, and processed simultaneously. The inline formatting engine used string-replacing macros (AttributeManager) that caused dozens of bugs — replaced with a proper structured InlineParser.\n\n43 PRs total from tompng. Massive contribution."],

    [12, "What 'caught up' means",
      "Modern reading experience — Aliki\nModern authoring experience — server mode\nModern parsing foundation — Prism\n\nThese were table stakes.\nNow let's talk about what's next.",
      "Brief transition slide. These features bring RDoc up to what users expect from a modern documentation tool. But catching up isn't enough — we need to keep moving forward."],

    // ─── SECTION 4: GETTING THERE (10 min) ───

    [13, "Long overdue — getting there",
      "",
      "Section divider. This is the meatiest part of the talk — active work that's not yet complete."],

    // Part A: Markdown

    [14, "Why Markdown?",
      "Markdown is the industry standard\nRDoc markup is Ruby-specific\n\nEven within the Ruby community,\nRDoc markup isn't widely adopted\n\nIf you can write a GitHub README,\nyou can write Ruby documentation",
      "The case for Markdown is straightforward. Markdown has won. RDoc markup is Ruby-specific and wasn't actively advocated. Switching lowers the barrier for contributing to Ruby core documentation.\n\nThe URL for standard library docs already changed: standard_library_rdoc.html → standard_library_md.html in Ruby 3.4+."],

    [15, "Why it took so long",
      "[Pipeline diagram]\n\nMarkdown parser → RDoc markup strings → Shared InlineParser → HTML\nRDoc parser    → RDoc markup strings → Shared InlineParser → HTML\n                                        ↑ same code path\n\nMarkdown was added ~2012 by reusing RDoc's pipeline\nEvery Markdown fix is a two-format fix",
      "MAKE THIS A CLEAR DIAGRAM — two parsers feeding into one shared pipeline.\n\nThe key insight: when the Markdown parser sees **bold**, it doesn't produce a structured 'bold' node. It outputs the RDoc markup string *bold* or <b>bold</b>. This string then gets re-parsed by the shared InlineParser — the same parser that handles RDoc markup.\n\nThis means any change to the inline parser affects both formats. Any escape rule change in one format can break the other."],

    [16, "Example: ~~strikethrough~~",
      "Markdown ~~text~~ → parser outputs \"<del>text</del>\"\n                          ↓ plain string\n         Shared InlineParser didn't recognize <del>\n                          ↓\n         Strikethrough silently broken for years\n\nFix: modify the shared InlineParser\n→ must verify RDoc markup still works too",
      "One concrete example makes this real. Markdown's strikethrough was 'parsed' correctly — the Markdown parser generated the right string. But the shared InlineParser that processes ALL paragraph text didn't know about <del> tags or ~ as a delimiter.\n\nThe fix required changing the shared InlineParser, which meant testing against both Markdown and RDoc markup to make sure nothing broke.\n\nThis pattern repeats for every Markdown improvement."],

    [17, "What's improved",
      "~~Strikethrough~~ aligned with GFM\nGitHub-style heading anchors (#heading-name)\nTable parsing: inline markdown, incomplete rows\nBash/shell syntax highlighting\nBacktick quoting in RDoc markup too\nbreak_on_newline by default\n\nGFM spec comparison test suite\nSystematic tracking of compatibility",
      "Walk through the concrete improvements. Each of these was a careful fix through the shared pipeline.\n\nThe GFM spec comparison test suite (#1550) is important — it systematically tracks where RDoc's Markdown diverges from GitHub Flavored Markdown, so we can prioritize fixes.\n\nStill not supported: task lists/checkboxes, GitHub-style alerts."],

    [18, "Before and after",
      "[Side-by-side: RDoc markup vs Markdown]\n\nRDoc markup:\n  = Heading\n  *bold*  _italic_  +code+\n  {link text}[url]\n  * bullet item\n\nMarkdown:\n  # Heading\n  **bold**  *italic*  `code`\n  [link text](url)\n  - bullet item",
      "MAKE THIS A CLEAR SIDE-BY-SIDE COMPARISON.\n\nShow the same documentation written in both formats. Markdown is immediately recognizable to any developer. RDoc markup requires learning Ruby-specific syntax.\n\nPoint out that many people already write Markdown in RDoc comments without realizing it doesn't render correctly (e.g., using **bold** which doesn't work in RDoc markup)."],

    [19, "Migration plan",
      "1. Get Markdown to GFM-level quality ← in progress\n2. Build migration tooling (RDoc markup → Markdown)\n3. Migrate ruby-core documentation\n4. Deprecate RDoc markup?\n\nThe URL already changed:\nstandard_library_rdoc.html → standard_library_md.html\n(Ruby 3.4+)",
      "The migration is a multi-step process. Step 1 is where we are now — making Markdown support robust enough that it's a viable replacement.\n\nStep 2 will require automated tooling to convert existing docs. Step 3 is the big one — migrating Ruby core's documentation.\n\nStep 4 is an open question. RDoc markup won't disappear overnight, but if Markdown becomes the recommended format, it could eventually be deprecated.\n\nNote the URL change: Ruby 3.4+ already serves standard library docs at the .md URL instead of the .rdoc URL."],

    // Part B: RBS

    [20, "RBS type signatures in documentation",
      "Inline RBS annotations with #:\n\n#: (String name, ?Integer age) -> User\ndef create_user(name, age = nil)\n  # ...\nend\n\nRDoc extracts these and displays them\nin HTML output and ri",
      "Transition to the second 'getting there' topic. RBS inline annotations use the #: comment syntax — Sorbet-flavored RBS.\n\nRDoc now parses these annotations, validates them via the RBS parser, and displays type signatures in generated documentation. Type names are linked to their corresponding documentation pages."],

    [21, "Demo: RBS in HTML",
      "[Screenshot: HTML output with type signatures]\n\nType signatures displayed on method pages\nType names linked to documentation\nMethod signature cards with types",
      "INSERT PRE-RECORDED DEMO or screenshot showing type signatures rendered in Aliki theme. Show how clicking a type name navigates to that type's documentation page.\n\nThis uses the RBS gem (>= 4.0.0) for parsing and validation. Type name linking uses RBS AST location information to resolve types."],

    [22, "Demo: RBS in ri",
      "[Screenshot: ri terminal output with types]\n\nri String#gsub\n\nShows type signatures in terminal output",
      "INSERT SCREENSHOT of ri output showing type information. Terminal-friendly rendering of type signatures alongside method documentation."],

    [23, "Can RBS replace :call-seq:?",
      ":call-seq:\n  readlines(sep=$/)     -> array\n  readlines(limit)      -> array\n  readlines(sep, limit) -> array\n\n#: (?String sep) -> Array[String]\n#: (Integer limit) -> Array[String]\n#: (String sep, Integer limit) -> Array[String]\n\nThe overlap is significant",
      "Raise this as a question, not a statement. Show the two formats side by side — they express largely the same information.\n\nFor a language that doesn't want typing, writing type signatures for documentation purposes is huge. In ruby/ruby, we'll directly write type signatures for documentation — though we won't typecheck them.\n\ncall-seq is free-form text, hard to parse, inconsistent. RBS is structured, machine-readable, enables tooling."],

    [24, "The gap: default values",
      ":call-seq:\n  commercial(cwyear, cweek=1, cwday=1, sg=nil)\n\nRBS:\n  #: (Integer cwyear, ?Integer cweek, ?Integer cwday, ?Symbol? sg)\n\ncall-seq shows cweek=1 — the actual default\nRBS only says ?Integer — optional, but what default?\n\nIf we want to migrate,\nRBS needs default value support",
      "This is the concrete blocker. call-seq captures the actual default values of parameters. RBS can express that a parameter is optional, but not what its default value is.\n\nThis matters especially for C extensions where there's no Ruby source to inspect — call-seq is the ONLY way to document default values.\n\nThe migration path depends on RBS adding default value syntax. This is TBD — an open question for the RBS and Ruby community."],

    [25, "What's next for RBS in docs",
      "Aiming to ship on docs.ruby-lang.org\n\nOpen question: migration path from call-seq\n  → Depends on RBS default value support\n  → Community discussion needed\n\nLong-term: structured, machine-readable signatures\nreplace free-form text",
      "Status update: PR #1665 in ruby/rdoc, aiming to get it merged and deployed.\n\nThe call-seq → RBS migration is a longer-term question that needs community input. But the direction is clear: structured, machine-readable signatures are better for humans (consistent rendering), tools (IDE integration), and machines (AI consumption)."],

    // ─── SECTION 5: GETTING AHEAD (3 min) ───

    [26, "Getting ahead",
      "",
      "Section divider. How do we avoid falling behind again?"],

    [27, "AI & documentation: what we evaluated",
      "llms.txt — the proposed standard for LLM-friendly docs\n\nWe prototyped it. Then we looked at the data:\n\n10% adoption across 300K domains\nZero measurable impact on AI citations\nML model improved when llms.txt was removed\nZero bot visits from GPTBot, ClaudeBot, etc.\nNo major LLM provider officially supports it\n\nTrade-off: generation time + code complexity\nfor negligible benefit → not pursuing",
      "Sources: SE Ranking study of ~300K domains, Search Engine Journal analysis. XGBoost model literally improved in accuracy when llms.txt was removed as a variable. From mid-Aug to late Oct 2025, llms.txt pages received zero visits from any major AI bot.\n\nWe prototyped the solution. It works. But the data doesn't justify adding complexity to RDoc that affects every user's generation time for a benefit that doesn't exist yet.\n\nThis is responsible maintainership: evaluate with data, not hype."],

    [28, "The real play: better foundations",
      "Instead of special files for LLMs:\n\nMarkdown — universally understood\n  by humans AND machines\n\nRBS types — structured, machine-readable\n  signatures instead of free-form text\n\nClean architecture — enables future\n  tooling we can't predict\n\ngithub.com/st0012/ruby-skills\n  Practical AI tooling for Ruby development\n  Future: RDoc-specific skills",
      "The thesis: don't chase trends. Build foundations that naturally serve all consumers — including future ones we can't predict.\n\nMarkdown is universally parseable. RBS types are structured data. Clean architecture (Prism, InlineParser rewrite) makes future features possible.\n\nruby-skills (109 stars) is a practical example: teaches AI assistants about Ruby version management, authoritative doc sources, test framework nuances. Future: RDoc-specific skills for documentation authoring once the Markdown migration is far enough along."],

    [29, "The philosophy",
      "Evaluate before building\n  Data over hype\n\nInvest in foundations\n  Prism · Markdown · Types\n\nMake documentation first-class\n  in the Ruby experience\n\nThe best way to prepare for the future\nis to get the present right",
      "This is the closing thought for the section. Tie it all together:\n\n1. We evaluated llms.txt with actual data and said no — that's how maintainers should make decisions.\n2. Every foundation we're building (Prism parsing, Markdown support, RBS types) naturally makes docs more consumable by any future tool.\n3. Documentation should be a first-class part of the Ruby experience, not an afterthought.\n\nThe best preparation for whatever comes next is getting the fundamentals right now."],

    // ─── SECTION 6: RECAP (1 min) ───

    [30, "Summary",
      "Caught up                Getting there           Getting ahead\n\nAliki theme              Markdown / GFM          Evaluate with data\nServer mode              RBS type signatures      Build foundations\nPrism parser             call-seq → RBS?          Serve all consumers",
      "One summary slide. Three columns mapping to the three-part arc of the talk.\n\nPause here — let the audience take in the full picture."],

    [31, "Try it today",
      "Contribute to Ruby docs — it's Markdown now!\n\nrdoc --server for your own projects\n\ngithub.com/ruby/rdoc\ndocs.ruby-lang.org\ngithub.com/st0012/ruby-skills",
      "Call to action. The most important message: it's now much easier to contribute to Ruby documentation.\n\nMention the URLs. Encourage people to try rdoc --server on their own projects, try the Aliki theme, and contribute to Ruby core docs."],

    [32, "Thank you",
      "Thank you!\n\ntompng · Shopify DX team\nRuby committers\n\n@st0012",
      "Thank specific people: tompng for the massive Prism and parser rewrites, Shopify DX team, Ruby committers who reviewed and merged PRs.\n\nOpen for questions."],
  ];

  // Populate each slide
  for (var i = 0; i < content.length; i++) {
    var entry = content[i];
    var slideIndex = entry[0];
    var title = entry[1];
    var body = entry[2];
    var notes = entry[3];

    if (slideIndex >= slides.length) {
      Logger.log("Skipping slide " + slideIndex + " — doesn't exist");
      continue;
    }

    var slide = slides[slideIndex];

    // Set speaker notes
    if (notes) {
      slide.getNotesPage().getSpeakerNotesShape().getText().setText(notes);
    }

    // Skip title slide (index 0) — don't modify its shapes
    if (title === null && body === null) continue;

    // Find and replace text in shapes
    var shapes = slide.getShapes();
    var titleSet = false;
    var bodySet = false;

    for (var j = 0; j < shapes.length; j++) {
      var shape = shapes[j];
      var text = shape.getText().asString().trim();

      if (text === "haha" && !titleSet) {
        shape.getText().setText(title || "");
        titleSet = true;
      } else if (text === "nice" && !bodySet) {
        shape.getText().setText(body || "");
        bodySet = true;
      }
    }

    // Fallback: if shapes weren't found by text, try by placeholder type
    if (!titleSet || !bodySet) {
      for (var j = 0; j < shapes.length; j++) {
        var shape = shapes[j];
        var phType = shape.getPlaceholderType();
        if (phType === SlidesApp.PlaceholderType.TITLE && !titleSet) {
          shape.getText().setText(title || "");
          titleSet = true;
        } else if (phType === SlidesApp.PlaceholderType.BODY && !bodySet) {
          shape.getText().setText(body || "");
          bodySet = true;
        }
      }
    }

    if (!titleSet) Logger.log("WARNING: Could not set title on slide " + slideIndex);
    if (!bodySet) Logger.log("WARNING: Could not set body on slide " + slideIndex);
  }

  // Delete unused slides (from the end to avoid index shifting)
  var totalNeeded = 33; // slides 0-32
  for (var i = slides.length - 1; i >= totalNeeded; i--) {
    slides[i].remove();
  }

  Logger.log("Done! Populated " + content.length + " slides, removed " + (slides.length - totalNeeded) + " extras.");
}
