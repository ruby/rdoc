# frozen_string_literal: true
require_relative 'helper'
require 'pp'

require_relative '../../lib/rdoc'
require_relative '../../lib/rdoc/markdown'

class RDocMarkdownTestTest < RDoc::TestCase

  MARKDOWN_TEST_PATH = File.expand_path '../MarkdownTest_1.0.3/', __FILE__

  def setup
    super

    @parser = RDoc::Markdown.new
  end

  def test_amps_and_angle_encoding
    input = File.read "#{MARKDOWN_TEST_PATH}/Amps and angle encoding.text"

    doc = @parser.parse input

    expected =
      doc(
        para("AT&T has an ampersand in their name."),
        para("AT&T is another way to write it."),
        para("This & that."),
        para("4 \\< 5."),
        para("6 > 5."),
        para("Here's a {link}[http://example.com/?foo=1&bar=2] with " +
             "an ampersand in the URL."),
        para("Here's a link with an amersand in the link text: " +
             "{AT&T}[http://att.com/]."),
        para("Here's an inline {link}[/script?foo=1&bar=2]."),
        para("Here's an inline {link}[/script?foo=1&bar=2]."))

    assert_equal expected, doc
  end

  def test_auto_links
    input = File.read "#{MARKDOWN_TEST_PATH}/Auto links.text"

    doc = @parser.parse input

    # TODO verify rdoc auto-links too
    expected =
      doc(
        para("Link: http://example.com/."),
        para("With an ampersand: http://example.com/?foo=1&bar=2"),
        list(:BULLET,
          item(nil, para("In a list?")),
          item(nil, para("http://example.com/")),
          item(nil, para("It should."))),
        block(
          para("Blockquoted: http://example.com/")),
        para("Auto-links should not occur here: " +
             "<code><http://example.com/></code>"),
        verb("or here: <http://example.com/>\n"))

    assert_equal expected, doc
  end

  def test_backslash_escapes
    input = File.read "#{MARKDOWN_TEST_PATH}/Backslash escapes.text"

    doc = @parser.parse input

    expected =
      doc(
        para("These should all get escaped:"),

        para("Backslash: \\\\"),
        para("Backtick: `"),
        para("Asterisk: \\*"),
        para("Underscore: \\_"),
        para("Left brace: {"),
        para("Right brace: }"),
        para("Left bracket: ["),
        para("Right bracket: ]"),
        para("Left paren: ("),
        para("Right paren: )"),
        para("Greater-than: >"),
        para("Hash: #"),
        para("Period: ."),
        para("Bang: !"),
        para("Plus: \\+"),
        para("Minus: -"),

        para("These should not, because they occur within a code block:"),

        verb("Backslash: \\\\\n",
             "\n",
             "Backtick: \\`\n",
             "\n",
             "Asterisk: \\*\n",
             "\n",
             "Underscore: \\_\n",
             "\n",
             "Left brace: \\{\n",
             "\n",
             "Right brace: \\}\n",
             "\n",
             "Left bracket: \\[\n",
             "\n",
             "Right bracket: \\]\n",
             "\n",
             "Left paren: \\(\n",
             "\n",
             "Right paren: \\)\n",
             "\n",
             "Greater-than: \\>\n",
             "\n",
             "Hash: \\#\n",
             "\n",
             "Period: \\.\n",
             "\n",
             "Bang: \\!\n",
             "\n",
             "Plus: \\+\n",
             "\n",
             "Minus: \\-\n"),

        para("Nor should these, which occur in code spans:"),

        para("Backslash: <code>\\\\</code>"),
        para("Backtick: <code>\\`</code>"),
        para("Asterisk: <code>\\*</code>"),
        para("Underscore: <code>\\_</code>"),
        para("Left brace: <code>\\{</code>"),
        para("Right brace: <code>\\}</code>"),
        para("Left bracket: <code>\\[</code>"),
        para("Right bracket: <code>\\]</code>"),
        para("Left paren: <code>\\(</code>"),
        para("Right paren: <code>\\)</code>"),
        para("Greater-than: <code>\\></code>"),
        para("Hash: <code>\\#</code>"),
        para("Period: <code>\\.</code>"),
        para("Bang: <code>\\!</code>"),
        para("Plus: <code>\\+</code>"),
        para("Minus: <code>\\-</code>"),

        para("These should get escaped, even though they're matching pairs for",
             hard_break, "other Markdown constructs:"),

        para("\\*asterisks\\*"),
        para("\\_underscores\\_"),
        para("`backticks`"),

        para("This is a code span with a literal backslash-backtick " +
             "sequence: <code>\\`</code>"),

        para("This is a tag with unescaped backticks " +
             "<span attr='`ticks`'>bar</span>."),

        para("This is a tag with backslashes " +
             "<span attr='\\\\backslashes\\\\'>bar</span>."))

    assert_equal expected, doc
  end

  def test_blockquotes_with_code_blocks
    input = File.read "#{MARKDOWN_TEST_PATH}/Blockquotes with code blocks.text"

    doc = @parser.parse input

    expected =
      doc(
        block(
          para("Example:"),
          verb("sub status {\n",
               "    print \"working\";\n",
               "}\n"),
          para("Or:"),
          verb("sub status {\n",
               "    return \"working\";\n",
               "}\n")))

    assert_equal expected, doc
  end

  def test_code_blocks
    input = File.read "#{MARKDOWN_TEST_PATH}/Code Blocks.text"

    doc = @parser.parse input

    expected =
      doc(
        verb("code block on the first line\n"),
        para("Regular text."),

        verb("code block indented by spaces\n"),
        para("Regular text."),

        verb("the lines in this block  \n",
             "all contain trailing spaces  \n"),
        para("Regular Text."),

        verb("code block on the last line\n"))

    assert_equal expected, doc
  end

  def test_code_spans
    input = File.read "#{MARKDOWN_TEST_PATH}/Code Spans.text"

    doc = @parser.parse input

    expected = doc(
      para("<code><test a=\"</code> content of attribute <code>\"></code>"),
      para("Fix for backticks within HTML tag: " +
           "<span attr='`ticks`'>like this</span>"),
      para("Here's how you put <code>`backticks`</code> in a code span."))

    assert_equal expected, doc
  end

  def test_hard_wrapped_paragraphs_with_list_like_lines
    input = File.read "#{MARKDOWN_TEST_PATH}/Hard-wrapped paragraphs with list-like lines.text"

    doc = @parser.parse input

    expected =
      doc(
        para("In Markdown 1.0.0 and earlier. Version",
             hard_break, "8. This line turns into a list item.",
             hard_break, "Because a hard-wrapped line in the",
             hard_break, "middle of a paragraph looked like a",
             hard_break, "list item."),
        para("Here's one with a bullet.",
             hard_break, "\\* criminey."))

    assert_equal expected, doc
  end

  def test_horizontal_rules
    input = File.read "#{MARKDOWN_TEST_PATH}/Horizontal rules.text"

    doc = @parser.parse input

    expected =
      doc(
        para("Dashes:"),

        rule(1),
        rule(1),
        rule(1),
        rule(1),
        verb("---\n"),

        rule(1),
        rule(1),
        rule(1),
        rule(1),
        verb("- - -\n"),

        para("Asterisks:"),

        rule(1),
        rule(1),
        rule(1),
        rule(1),
        verb("***\n"),

        rule(1),
        rule(1),
        rule(1),
        rule(1),
        verb("* * *\n"),

        para("Underscores:"),

        rule(1),
        rule(1),
        rule(1),
        rule(1),
        verb("___\n"),

        rule(1),
        rule(1),
        rule(1),
        rule(1),
        verb("_ _ _\n"))

    assert_equal expected, doc
  end

  def test_inline_html_advanced
    input = File.read "#{MARKDOWN_TEST_PATH}/Inline HTML (Advanced).text"

    @parser.html = true

    doc = @parser.parse input

    expected =
      doc(
        para("Simple block on one line:"),
        raw("<div>foo</div>"),
        para("And nested without indentation:"),
        raw(<<-RAW.chomp))
<div>
<div>
<div>
foo
</div>
<div style=">"/>
</div>
<div>bar</div>
</div>
        RAW

    assert_equal expected, doc
  end

  def test_inline_html_simple
    input = File.read "#{MARKDOWN_TEST_PATH}/Inline HTML (Simple).text"

    @parser.html = true

    doc = @parser.parse input

    expected =
      doc(
       para("Here's a simple block:"),
       raw("<div>\n\tfoo\n</div>"),

       para("This should be a code block, though:"),
       verb("<div>\n",
            "\tfoo\n",
            "</div>\n"),

       para("As should this:"),
       verb("<div>foo</div>\n"),

       para("Now, nested:"),
       raw("<div>\n\t<div>\n\t\t<div>\n\t\t\tfoo\n" +
           "\t\t</div>\n\t</div>\n</div>"),

       para("This should just be an HTML comment:"),
       raw("<!-- Comment -->"),

       para("Multiline:"),
       raw("<!--\nBlah\nBlah\n-->"),

       para("Code block:"),
       verb("<!-- Comment -->\n"),

       para("Just plain comment, with trailing spaces on the line:"),
       raw("<!-- foo -->"),

       para("Code:"),
       verb("<hr />\n"),

       para("Hr's:"),
       raw("<hr>"),
       raw("<hr/>"),
       raw("<hr />"),

       raw("<hr>"),
       raw("<hr/>"),
       raw("<hr />"),

       raw("<hr class=\"foo\" id=\"bar\" />"),
       raw("<hr class=\"foo\" id=\"bar\"/>"),
       raw("<hr class=\"foo\" id=\"bar\" >"))

    assert_equal expected, doc
  end

  def test_inline_html_comments
    input = File.read "#{MARKDOWN_TEST_PATH}/Inline HTML comments.text"

    doc = @parser.parse input

    expected =
      doc(
        para("Paragraph one."),

        raw("<!-- This is a simple comment -->"),

        raw("<!--\n\tThis is another comment.\n-->"),

        para("Paragraph two."),

        raw("<!-- one comment block -- -- with two comments -->"),

        para("The end."))

    assert_equal expected, doc
  end

  def test_links_inline_style
    input = File.read "#{MARKDOWN_TEST_PATH}/Links, inline style.text"

    doc = @parser.parse input

    expected =
      doc(
        para("Just a {URL}[/url/]."),
        para("{URL and title}[/url/]."),
        para("{URL and title}[/url/]."),
        para("{URL and title}[/url/]."),
        para("{URL and title}[/url/]."),
        para("{Empty}[]."))

    assert_equal expected, doc
  end

  def test_links_reference_style
    input = File.read "#{MARKDOWN_TEST_PATH}/Links, reference style.text"

    doc = @parser.parse input

    expected =
      doc(
        para("Foo {bar}[/url/]."),
        para("Foo {bar}[/url/]."),
        para("Foo {bar}[/url/]."),

        para("With {embedded [brackets]}[/url/]."),

        para("Indented {once}[/url]."),
        para("Indented {twice}[/url]."),
        para("Indented {thrice}[/url]."),
        para("Indented [four][] times."),

        verb("[four]: /url\n"),

        rule(1),

        para("{this}[foo] should work"),
        para("So should {this}[foo]."),
        para("And {this}[foo]."),
        para("And {this}[foo]."),
        para("And {this}[foo]."),

        para("But not [that] []."),
        para("Nor [that][]."),
        para("Nor [that]."),

        para("[Something in brackets like {this}[foo] should work]"),
        para("[Same with {this}[foo].]"),

        para("In this case, {this}[/somethingelse/] points to something else."),
        para("Backslashing should suppress [this] and [this]."),

        rule(1),

        para("Here's one where the {link breaks}[/url/] across lines."),
        para("Here's another where the {link breaks}[/url/] across lines, " +
             "but with a line-ending space."))

    assert_equal expected, doc
  end

  def test_links_shortcut_references
    input = File.read "#{MARKDOWN_TEST_PATH}/Links, shortcut references.text"

    doc = @parser.parse input

    expected =
      doc(
        para("This is the {simple case}[/simple]."),
        para("This one has a {line break}[/foo]."),
        para("This one has a {line break}[/foo] with a line-ending space."),
        para("{this}[/that] and the {other}[/other]"))

    assert_equal expected, doc
  end

  def test_literal_quotes_in_titles
    input = File.read "#{MARKDOWN_TEST_PATH}/Literal quotes in titles.text"

    doc = @parser.parse input

    # TODO support title attribute
    expected =
      doc(
        para("Foo {bar}[/url/]."),
        para("Foo {bar}[/url/]."))

    assert_equal expected, doc
  end

  def test_markdown_documentation_basics
    input = File.read "#{MARKDOWN_TEST_PATH}/Markdown Documentation - Basics.text"

    doc = @parser.parse input

    expected =
      doc(
        head(1, "Markdown: Basics"),

        raw(<<-RAW.chomp),
<ul id="ProjectSubmenu">
    <li><a href="/projects/markdown/" title="Markdown Project Page">Main</a></li>
    <li><a class="selected" title="Markdown Basics">Basics</a></li>
    <li><a href="/projects/markdown/syntax" title="Markdown Syntax Documentation">Syntax</a></li>
    <li><a href="/projects/markdown/license" title="Pricing and License Information">License</a></li>
    <li><a href="/projects/markdown/dingus" title="Online Markdown Web Form">Dingus</a></li>
</ul>
        RAW

        head(2, "Getting the Gist of Markdown's Formatting Syntax"),

        para("This page offers a brief overview of what it's like to use Markdown.",
             hard_break, "The {syntax page}[/projects/markdown/syntax] provides complete, detailed documentation for",
             hard_break, "every feature, but Markdown should be very easy to pick up simply by",
             hard_break, "looking at a few examples of it in action. The examples on this page",
             hard_break, "are written in a before/after style, showing example syntax and the",
             hard_break, "HTML output produced by Markdown."),

        para("It's also helpful to simply try Markdown out; the {Dingus}[/projects/markdown/dingus] is a",
             hard_break, "web application that allows you type your own Markdown-formatted text",
             hard_break, "and translate it to XHTML."),

        para("<b>Note:</b> This document is itself written using Markdown; you",
             hard_break, "can {see the source for it by adding '.text' to the URL}[/projects/markdown/basics.text]."),

        head(2, "Paragraphs, Headers, Blockquotes"),

        para("A paragraph is simply one or more consecutive lines of text, separated",
             hard_break, "by one or more blank lines. (A blank line is any line that looks like a",
             hard_break, "blank line -- a line containing nothing spaces or tabs is considered",
             hard_break, "blank.) Normal paragraphs should not be intended with spaces or tabs."),

        para("Markdown offers two styles of headers: _Setext_ and _atx_.",
             hard_break, "Setext-style headers for <code><h1></code> and <code><h2></code> are created by",
             hard_break, "\"underlining\" with equal signs (<code>=</code>) and hyphens (<code>-</code>), respectively.",
             hard_break, "To create an atx-style header, you put 1-6 hash marks (<code>#</code>) at the",
             hard_break, "beginning of the line -- the number of hashes equals the resulting",
             hard_break, "HTML header level."),

        para("Blockquotes are indicated using email-style '<code>></code>' angle brackets."),

        para("Markdown:"),

        verb("A First Level Header\n",
             "====================\n",
             "\n",
             "A Second Level Header\n",
             "---------------------\n",
             "\n",
             "Now is the time for all good men to come to\n",
             "the aid of their country. This is just a\n",
             "regular paragraph.\n",
             "\n",
             "The quick brown fox jumped over the lazy\n",
             "dog's back.\n",
             "\n",
             "### Header 3\n",
             "\n",
             "> This is a blockquote.\n",
             "> \n",
             "> This is the second paragraph in the blockquote.\n",
             ">\n",
             "> ## This is an H2 in a blockquote\n"),

        para("Output:"),

        verb("<h1>A First Level Header</h1>\n",
             "\n",
             "<h2>A Second Level Header</h2>\n",
             "\n",
             "<p>Now is the time for all good men to come to\n",
             "the aid of their country. This is just a\n",
             "regular paragraph.</p>\n",
             "\n",
             "<p>The quick brown fox jumped over the lazy\n",
             "dog's back.</p>\n",
             "\n",
             "<h3>Header 3</h3>\n",
             "\n",
             "<blockquote>\n",
             "    <p>This is a blockquote.</p>\n",
             "\n",
             "    <p>This is the second paragraph in the blockquote.</p>\n",
             "\n",
             "    <h2>This is an H2 in a blockquote</h2>\n",
             "</blockquote>\n"),

        head(3, "Phrase Emphasis"),
        para("Markdown uses asterisks and underscores to indicate spans of emphasis."),

        para("Markdown:"),

        verb("Some of these words *are emphasized*.\n",
             "Some of these words _are emphasized also_.\n",
             "\n",
             "Use two asterisks for **strong emphasis**.\n",
             "Or, if you prefer, __use two underscores instead__.\n"),

        para("Output:"),

        verb("<p>Some of these words <em>are emphasized</em>.\n",
             "Some of these words <em>are emphasized also</em>.</p>\n",
             "\n",
             "<p>Use two asterisks for <strong>strong emphasis</strong>.\n",
             "Or, if you prefer, <strong>use two underscores instead</strong>.</p>\n"),

        head(2, "Lists"),

        para("Unordered (bulleted) lists use asterisks, pluses, and hyphens (<code>*</code>,",
             hard_break, "<code>+</code>, and <code>-</code>) as list markers. These three markers are",
             hard_break, "interchangeable; this:"),

        verb("*   Candy.\n",
             "*   Gum.\n",
             "*   Booze.\n"),

        para("this:"),

        verb("+   Candy.\n",
             "+   Gum.\n",
             "+   Booze.\n"),

        para("and this:"),

        verb("-   Candy.\n",
             "-   Gum.\n",
             "-   Booze.\n"),

        para("all produce the same output:"),

        verb("<ul>\n",
             "<li>Candy.</li>\n",
             "<li>Gum.</li>\n",
             "<li>Booze.</li>\n",
             "</ul>\n"),

        para("Ordered (numbered) lists use regular numbers, followed by periods, as",
             hard_break, "list markers:"),

        verb("1.  Red\n",
             "2.  Green\n",
             "3.  Blue\n"),

        para("Output:"),

        verb("<ol>\n",
             "<li>Red</li>\n",
             "<li>Green</li>\n",
             "<li>Blue</li>\n",
             "</ol>\n"),

        para("If you put blank lines between items, you'll get <code><p></code> tags for the",
             hard_break, "list item text. You can create multi-paragraph list items by indenting",
             hard_break, "the paragraphs by 4 spaces or 1 tab:"),

        verb("*   A list item.\n",
             "\n",
             "    With multiple paragraphs.\n",
             "\n",
             "*   Another item in the list.\n"),

        para("Output:"),

        verb("<ul>\n",
             "<li><p>A list item.</p>\n",
             "<p>With multiple paragraphs.</p></li>\n",
             "<li><p>Another item in the list.</p></li>\n",
             "</ul>\n"),

        head(3, "Links"),

        para("Markdown supports two styles for creating links: _inline_ and",
             hard_break, "_reference_. With both styles, you use square brackets to delimit the",
             hard_break, "text you want to turn into a link."),

        para("Inline-style links use parentheses immediately after the link text.",
             hard_break, "For example:"),

        verb("This is an [example link](http://example.com/).\n"),

        para("Output:"),

        verb("<p>This is an <a href=\"http://example.com/\">\n",
             "example link</a>.</p>\n"),

        para("Optionally, you may include a title attribute in the parentheses:"),

        verb("This is an [example link](http://example.com/ \"With a Title\").\n"),

        para("Output:"),

        verb("<p>This is an <a href=\"http://example.com/\" title=\"With a Title\">\n",
             "example link</a>.</p>\n"),

        para("Reference-style links allow you to refer to your links by names, which",
             hard_break, "you define elsewhere in your document:"),

        verb("I get 10 times more traffic from [Google][1] than from\n",
             "[Yahoo][2] or [MSN][3].\n",
             "\n",
             "[1]: http://google.com/        \"Google\"\n",
             "[2]: http://search.yahoo.com/  \"Yahoo Search\"\n",
             "[3]: http://search.msn.com/    \"MSN Search\"\n"),

        para("Output:"),

        verb("<p>I get 10 times more traffic from <a href=\"http://google.com/\"\n",
             "title=\"Google\">Google</a> than from <a href=\"http://search.yahoo.com/\"\n",
             "title=\"Yahoo Search\">Yahoo</a> or <a href=\"http://search.msn.com/\"\n",
             "title=\"MSN Search\">MSN</a>.</p>\n"),

        para("The title attribute is optional. Link names may contain letters,",
             hard_break, "numbers and spaces, but are _not_ case sensitive:"),

        verb("I start my morning with a cup of coffee and\n",
             "[The New York Times][NY Times].\n",
             "\n",
             "[ny times]: http://www.nytimes.com/\n"),

        para("Output:"),

        verb("<p>I start my morning with a cup of coffee and\n",
             "<a href=\"http://www.nytimes.com/\">The New York Times</a>.</p>\n"),

        head(3, "Images"),

        para("Image syntax is very much like link syntax."),

        para("Inline (titles are optional):"),

        verb("![alt text](/path/to/img.jpg \"Title\")\n"),

        para("Reference-style:"),

        verb("![alt text][id]\n",
             "\n",
             "[id]: /path/to/img.jpg \"Title\"\n"),

        para("Both of the above examples produce the same output:"),

        verb("<img src=\"/path/to/img.jpg\" alt=\"alt text\" title=\"Title\" />\n"),

        head(3, "Code"),

        para("In a regular paragraph, you can create code span by wrapping text in",
             hard_break, "backtick quotes. Any ampersands (<code>&</code>) and angle brackets (<code><</code> or",
             hard_break, "<code>></code>) will automatically be translated into HTML entities. This makes",
             hard_break, "it easy to use Markdown to write about HTML example code:"),

        verb(
             "I strongly recommend against using any `<blink>` tags.\n",
             "\n",
             "I wish SmartyPants used named entities like `&mdash;`\n",
             "instead of decimal-encoded entities like `&#8212;`.\n"),

        para("Output:"),

        verb("<p>I strongly recommend against using any\n",
             "<code>&lt;blink&gt;</code> tags.</p>\n",
             "\n",
             "<p>I wish SmartyPants used named entities like\n",
             "<code>&amp;mdash;</code> instead of decimal-encoded\n",
             "entities like <code>&amp;#8212;</code>.</p>\n"),

        para("To specify an entire block of pre-formatted code, indent every line of",
             hard_break, "the block by 4 spaces or 1 tab. Just like with code spans, <code>&</code>, <code><</code>,",
             hard_break, "and <code>></code> characters will be escaped automatically."),

        para("Markdown:"),

        verb("If you want your page to validate under XHTML 1.0 Strict,\n",
             "you've got to put paragraph tags in your blockquotes:\n",
             "\n",
             "    <blockquote>\n",
             "        <p>For example.</p>\n",
             "    </blockquote>\n"),

        para("Output:"),

        verb("<p>If you want your page to validate under XHTML 1.0 Strict,\n",
             "you've got to put paragraph tags in your blockquotes:</p>\n",
             "\n",
             "<pre><code>&lt;blockquote&gt;\n",
             "    &lt;p&gt;For example.&lt;/p&gt;\n",
             "&lt;/blockquote&gt;\n",
             "</code></pre>\n"))

    assert_equal expected, doc
  end

  def test_markdown_documentation_syntax
    input = File.read "#{MARKDOWN_TEST_PATH}/Markdown Documentation - Syntax.text"

    doc = @parser.parse input

    expected =
      doc(
        head(1, "Markdown: Syntax"),

        raw(<<-RAW.chomp),
<ul id="ProjectSubmenu">
    <li><a href="/projects/markdown/" title="Markdown Project Page">Main</a></li>
    <li><a href="/projects/markdown/basics" title="Markdown Basics">Basics</a></li>
    <li><a class="selected" title="Markdown Syntax Documentation">Syntax</a></li>
    <li><a href="/projects/markdown/license" title="Pricing and License Information">License</a></li>
    <li><a href="/projects/markdown/dingus" title="Online Markdown Web Form">Dingus</a></li>
</ul>
        RAW

        list(:BULLET,
          item(nil,
            para("{Overview}[#overview]"),
            list(:BULLET,
              item(nil,
                para("{Philosophy}[#philosophy]")),
              item(nil,
                para("{Inline HTML}[#html]")),
              item(nil,
                para("{Automatic Escaping for Special Characters}[#autoescape]")))),
          item(nil,
            para("{Block Elements}[#block]"),
            list(:BULLET,
              item(nil,
                para("{Paragraphs and Line Breaks}[#p]")),
              item(nil,
                para("{Headers}[#header]")),
              item(nil,
                para("{Blockquotes}[#blockquote]")),
              item(nil,
                para("{Lists}[#list]")),
              item(nil,
                para("{Code Blocks}[#precode]")),
              item(nil,
                para("{Horizontal Rules}[#hr]")))),
          item(nil,
            para("{Span Elements}[#span]"),
            list(:BULLET,
              item(nil,
                para("{Links}[#link]")),
              item(nil,
                para("{Emphasis}[#em]")),
              item(nil,
                para("{Code}[#code]")),
              item(nil,
                para("{Images}[#img]")))),
          item(nil,
            para("{Miscellaneous}[#misc]"),
            list(:BULLET,
              item(nil,
                para("{Backslash Escapes}[#backslash]")),
              item(nil,
                para("{Automatic Links}[#autolink]"))))),

        para("<b>Note:</b> This document is itself written using Markdown; you",
             hard_break, "can {see the source for it by adding '.text' to the URL}[/projects/markdown/syntax.text]."),

        rule(1),

        raw("<h2 id=\"overview\">Overview</h2>"),

        raw("<h3 id=\"philosophy\">Philosophy</h3>"),

        para("Markdown is intended to be as easy-to-read and easy-to-write as is feasible."),

        para("Readability, however, is emphasized above all else. A Markdown-formatted",
             hard_break, "document should be publishable as-is, as plain text, without looking",
             hard_break, "like it's been marked up with tags or formatting instructions. While",
             hard_break, "Markdown's syntax has been influenced by several existing text-to-HTML",
             hard_break, "filters -- including {Setext}[http://docutils.sourceforge.net/mirror/setext.html], {atx}[http://www.aaronsw.com/2002/atx/], {Textile}[http://textism.com/tools/textile/], {reStructuredText}[http://docutils.sourceforge.net/rst.html],",
             hard_break, "{Grutatext}[http://www.triptico.com/software/grutatxt.html], and {EtText}[http://ettext.taint.org/doc/] -- the single biggest source of",
             hard_break, "inspiration for Markdown's syntax is the format of plain text email."),

        para("To this end, Markdown's syntax is comprised entirely of punctuation",
             hard_break, "characters, which punctuation characters have been carefully chosen so",
             hard_break, "as to look like what they mean. E.g., asterisks around a word actually",
             hard_break, "look like \\*emphasis\\*. Markdown lists look like, well, lists. Even",
             hard_break, "blockquotes look like quoted passages of text, assuming you've ever",
             hard_break, "used email."),

        raw("<h3 id=\"html\">Inline HTML</h3>"),

        para("Markdown's syntax is intended for one purpose: to be used as a",
             hard_break, "format for _writing_ for the web."),

        para("Markdown is not a replacement for HTML, or even close to it. Its",
             hard_break, "syntax is very small, corresponding only to a very small subset of",
             hard_break, "HTML tags. The idea is _not_ to create a syntax that makes it easier",
             hard_break, "to insert HTML tags. In my opinion, HTML tags are already easy to",
             hard_break, "insert. The idea for Markdown is to make it easy to read, write, and",
             hard_break, "edit prose. HTML is a _publishing_ format; Markdown is a _writing_",
             hard_break, "format. Thus, Markdown's formatting syntax only addresses issues that",
             hard_break, "can be conveyed in plain text."),

        para("For any markup that is not covered by Markdown's syntax, you simply",
             hard_break, "use HTML itself. There's no need to preface it or delimit it to",
             hard_break, "indicate that you're switching from Markdown to HTML; you just use",
             hard_break, "the tags."),

        para("The only restrictions are that block-level HTML elements -- e.g. <code><div></code>,",
             hard_break, "<code><table></code>, <code><pre></code>, <code><p></code>, etc. -- must be separated from surrounding",
             hard_break, "content by blank lines, and the start and end tags of the block should",
             hard_break, "not be indented with tabs or spaces. Markdown is smart enough not",
             hard_break, "to add extra (unwanted) <code><p></code> tags around HTML block-level tags."),

        para("For example, to add an HTML table to a Markdown article:"),

        verb("This is a regular paragraph.\n",
             "\n",
             "<table>\n",
             "    <tr>\n",
             "        <td>Foo</td>\n",
             "    </tr>\n",
             "</table>\n",
             "\n",
             "This is another regular paragraph.\n"),

        para("Note that Markdown formatting syntax is not processed within block-level",
             hard_break, "HTML tags. E.g., you can't use Markdown-style <code>*emphasis*</code> inside an",
             hard_break, "HTML block."),

        para("Span-level HTML tags -- e.g. <code><span></code>, <code><cite></code>, or <code><del></code> -- can be",
             hard_break, "used anywhere in a Markdown paragraph, list item, or header. If you",
             hard_break, "want, you can even use HTML tags instead of Markdown formatting; e.g. if",
             hard_break, "you'd prefer to use HTML <code><a></code> or <code><img></code> tags instead of Markdown's",
             hard_break, "link or image syntax, go right ahead."),

        para("Unlike block-level HTML tags, Markdown syntax _is_ processed within",
             hard_break, "span-level tags."),

        raw("<h3 id=\"autoescape\">Automatic Escaping for Special Characters</h3>"),

        para("In HTML, there are two characters that demand special treatment: <code><</code>",
             hard_break, "and <code>&</code>. Left angle brackets are used to start tags; ampersands are",
             hard_break, "used to denote HTML entities. If you want to use them as literal",
             hard_break, "characters, you must escape them as entities, e.g. <code>&lt;</code>, and",
             hard_break, "<code>&amp;</code>."),

        para("Ampersands in particular are bedeviling for web writers. If you want to",
             hard_break, "write about 'AT&T', you need to write '<code>AT&amp;T</code>'. You even need to",
             hard_break, "escape ampersands within URLs. Thus, if you want to link to:"),

        verb("http://images.google.com/images?num=30&q=larry+bird\n"),

        para("you need to encode the URL as:"),

        verb("http://images.google.com/images?num=30&amp;q=larry+bird\n"),

        para("in your anchor tag <code>href</code> attribute. Needless to say, this is easy to",
             hard_break, "forget, and is probably the single most common source of HTML validation",
             hard_break, "errors in otherwise well-marked-up web sites."),

        para("Markdown allows you to use these characters naturally, taking care of",
             hard_break, "all the necessary escaping for you. If you use an ampersand as part of",
             hard_break, "an HTML entity, it remains unchanged; otherwise it will be translated",
             hard_break, "into <code>&amp;</code>."),

        para("So, if you want to include a copyright symbol in your article, you can write:"),

        verb("&copy;\n"),

        para("and Markdown will leave it alone. But if you write:"),

        verb("AT&T\n"),

        para("Markdown will translate it to:"),

        verb("AT&amp;T\n"),

        para("Similarly, because Markdown supports {inline HTML}[#html], if you use",
             hard_break, "angle brackets as delimiters for HTML tags, Markdown will treat them as",
             hard_break, "such. But if you write:"),

        verb("4 < 5\n"),

        para("Markdown will translate it to:"),

        verb("4 &lt; 5\n"),

        para("However, inside Markdown code spans and blocks, angle brackets and",
             hard_break, "ampersands are _always_ encoded automatically. This makes it easy to use",
             hard_break, "Markdown to write about HTML code. (As opposed to raw HTML, which is a",
             hard_break, "terrible format for writing about HTML syntax, because every single <code><</code>",
             hard_break, "and <code>&</code> in your example code needs to be escaped.)"),

        rule(1),

        raw("<h2 id=\"block\">Block Elements</h2>"),

        raw("<h3 id=\"p\">Paragraphs and Line Breaks</h3>"),

        para("A paragraph is simply one or more consecutive lines of text, separated",
             hard_break, "by one or more blank lines. (A blank line is any line that looks like a",
             hard_break, "blank line -- a line containing nothing but spaces or tabs is considered",
             hard_break, "blank.) Normal paragraphs should not be intended with spaces or tabs."),

        para("The implication of the \"one or more consecutive lines of text\" rule is",
             hard_break, "that Markdown supports \"hard-wrapped\" text paragraphs. This differs",
             hard_break, "significantly from most other text-to-HTML formatters (including Movable",
             hard_break, "Type's \"Convert Line Breaks\" option) which translate every line break",
             hard_break, "character in a paragraph into a <code><br /></code> tag."),

        para("When you _do_ want to insert a <code><br /></code> break tag using Markdown, you",
             hard_break, "end a line with two or more spaces, then type return."),

        para("Yes, this takes a tad more effort to create a <code><br /></code>, but a simplistic",
             hard_break, "\"every line break is a <code><br /></code>\" rule wouldn't work for Markdown.",
             hard_break, "Markdown's email-style {blockquoting}[#blockquote] and multi-paragraph {list items}[#list]",
             hard_break, "work best -- and look better -- when you format them with hard breaks."),

        raw("<h3 id=\"header\">Headers</h3>"),

        para("Markdown supports two styles of headers, {Setext}[http://docutils.sourceforge.net/mirror/setext.html] and {atx}[http://www.aaronsw.com/2002/atx/]."),

        para("Setext-style headers are \"underlined\" using equal signs (for first-level",
             hard_break, "headers) and dashes (for second-level headers). For example:"),

        verb("This is an H1\n",
             "=============\n",
             "\n",
             "This is an H2\n",
             "-------------\n"),

        para("Any number of underlining <code>=</code>'s or <code>-</code>'s will work."),

        para("Atx-style headers use 1-6 hash characters at the start of the line,",
             hard_break, "corresponding to header levels 1-6. For example:"),

        verb("# This is an H1\n",
             "\n",
             "## This is an H2\n",
             "\n",
             "###### This is an H6\n"),

        para("Optionally, you may \"close\" atx-style headers. This is purely",
             hard_break, "cosmetic -- you can use this if you think it looks better. The",
             hard_break, "closing hashes don't even need to match the number of hashes",
             hard_break, "used to open the header. (The number of opening hashes",
             hard_break, "determines the header level.) :"),

        verb("# This is an H1 #\n",
             "\n",
             "## This is an H2 ##\n",
             "\n",
             "### This is an H3 ######\n"),

        raw("<h3 id=\"blockquote\">Blockquotes</h3>"),

        para(
             "Markdown uses email-style <code>></code> characters for blockquoting. If you're",
             hard_break, "familiar with quoting passages of text in an email message, then you",
             hard_break, "know how to create a blockquote in Markdown. It looks best if you hard",
             hard_break, "wrap the text and put a <code>></code> before every line:"),

        verb("> This is a blockquote with two paragraphs. Lorem ipsum dolor sit amet,\n",
             "> consectetuer adipiscing elit. Aliquam hendrerit mi posuere lectus.\n",
             "> Vestibulum enim wisi, viverra nec, fringilla in, laoreet vitae, risus.\n",
             "> \n",
             "> Donec sit amet nisl. Aliquam semper ipsum sit amet velit. Suspendisse\n",
             "> id sem consectetuer libero luctus adipiscing.\n"),

        para("Markdown allows you to be lazy and only put the <code>></code> before the first",
             hard_break, "line of a hard-wrapped paragraph:"),

        verb("> This is a blockquote with two paragraphs. Lorem ipsum dolor sit amet,\n",
             "consectetuer adipiscing elit. Aliquam hendrerit mi posuere lectus.\n",
             "Vestibulum enim wisi, viverra nec, fringilla in, laoreet vitae, risus.\n",
             "\n",
             "> Donec sit amet nisl. Aliquam semper ipsum sit amet velit. Suspendisse\n",
             "id sem consectetuer libero luctus adipiscing.\n"),

        para("Blockquotes can be nested (i.e. a blockquote-in-a-blockquote) by",
             hard_break, "adding additional levels of <code>></code>:"),

        verb("> This is the first level of quoting.\n",
             ">\n",
             "> > This is nested blockquote.\n",
             ">\n",
             "> Back to the first level.\n"),

        para("Blockquotes can contain other Markdown elements, including headers, lists,",
             hard_break, "and code blocks:"),

        verb("> ## This is a header.\n",
             "> \n",
             "> 1.   This is the first list item.\n",
             "> 2.   This is the second list item.\n",
             "> \n",
             "> Here's some example code:\n",
             "> \n",
             ">     return shell_exec(\"echo $input | $markdown_script\");\n"),

        para("Any decent text editor should make email-style quoting easy. For",
             hard_break, "example, with BBEdit, you can make a selection and choose Increase",
             hard_break, "Quote Level from the Text menu."),

        raw("<h3 id=\"list\">Lists</h3>"),

        para("Markdown supports ordered (numbered) and unordered (bulleted) lists."),

        para("Unordered lists use asterisks, pluses, and hyphens -- interchangeably",
             hard_break, "-- as list markers:"),

        verb("*   Red\n",
             "*   Green\n",
             "*   Blue\n"),

        para("is equivalent to:"),

        verb("+   Red\n",
             "+   Green\n",
             "+   Blue\n"),

        para("and:"),

        verb("-   Red\n",
             "-   Green\n",
             "-   Blue\n"),

        para("Ordered lists use numbers followed by periods:"),

        verb("1.  Bird\n",
             "2.  McHale\n",
             "3.  Parish\n"),

        para("It's important to note that the actual numbers you use to mark the",
             hard_break, "list have no effect on the HTML output Markdown produces. The HTML",
             hard_break, "Markdown produces from the above list is:"),

        verb("<ol>\n",
             "<li>Bird</li>\n",
             "<li>McHale</li>\n",
             "<li>Parish</li>\n",
             "</ol>\n"),

        para("If you instead wrote the list in Markdown like this:"),

        verb("1.  Bird\n",
             "1.  McHale\n",
             "1.  Parish\n"),

        para("or even:"),

        verb("3. Bird\n",
             "1. McHale\n",
             "8. Parish\n"),

        para("you'd get the exact same HTML output. The point is, if you want to,",
             hard_break, "you can use ordinal numbers in your ordered Markdown lists, so that",
             hard_break, "the numbers in your source match the numbers in your published HTML.",
             hard_break, "But if you want to be lazy, you don't have to."),

        para("If you do use lazy list numbering, however, you should still start the",
             hard_break, "list with the number 1. At some point in the future, Markdown may support",
             hard_break, "starting ordered lists at an arbitrary number."),

        para("List markers typically start at the left margin, but may be indented by",
             hard_break, "up to three spaces. List markers must be followed by one or more spaces",
             hard_break, "or a tab."),

        para("To make lists look nice, you can wrap items with hanging indents:"),

        verb("*   Lorem ipsum dolor sit amet, consectetuer adipiscing elit.\n",
             "    Aliquam hendrerit mi posuere lectus. Vestibulum enim wisi,\n",
             "    viverra nec, fringilla in, laoreet vitae, risus.\n",
             "*   Donec sit amet nisl. Aliquam semper ipsum sit amet velit.\n",
             "    Suspendisse id sem consectetuer libero luctus adipiscing.\n"),

        para("But if you want to be lazy, you don't have to:"),

        verb("*   Lorem ipsum dolor sit amet, consectetuer adipiscing elit.\n",
             "Aliquam hendrerit mi posuere lectus. Vestibulum enim wisi,\n",
             "viverra nec, fringilla in, laoreet vitae, risus.\n",
             "*   Donec sit amet nisl. Aliquam semper ipsum sit amet velit.\n",
             "Suspendisse id sem consectetuer libero luctus adipiscing.\n"),

        para("If list items are separated by blank lines, Markdown will wrap the",
             hard_break, "items in <code><p></code> tags in the HTML output. For example, this input:"),

        verb("*   Bird\n",
             "*   Magic\n"),

        para("will turn into:"),

        verb("<ul>\n",
             "<li>Bird</li>\n",
             "<li>Magic</li>\n",
             "</ul>\n"),

        para("But this:"),

        verb("*   Bird\n",
             "\n",
             "*   Magic\n"),

        para("will turn into:"),

        verb("<ul>\n",
             "<li><p>Bird</p></li>\n",
             "<li><p>Magic</p></li>\n",
             "</ul>\n"),

        para("List items may consist of multiple paragraphs. Each subsequent",
             hard_break, "paragraph in a list item must be intended by either 4 spaces",
             hard_break, "or one tab:"),

        verb("1.  This is a list item with two paragraphs. Lorem ipsum dolor\n",
             "    sit amet, consectetuer adipiscing elit. Aliquam hendrerit\n",
             "    mi posuere lectus.\n",
             "\n",
             "    Vestibulum enim wisi, viverra nec, fringilla in, laoreet\n",
             "    vitae, risus. Donec sit amet nisl. Aliquam semper ipsum\n",
             "    sit amet velit.\n",
             "\n",
             "2.  Suspendisse id sem consectetuer libero luctus adipiscing.\n"),

        para("It looks nice if you indent every line of the subsequent",
             hard_break, "paragraphs, but here again, Markdown will allow you to be",
             hard_break, "lazy:"),

        verb("*   This is a list item with two paragraphs.\n",
             "\n",
             "    This is the second paragraph in the list item. You're\n",
             "only required to indent the first line. Lorem ipsum dolor\n",
             "sit amet, consectetuer adipiscing elit.\n",
             "\n",
             "*   Another item in the same list.\n"),

        para("To put a blockquote within a list item, the blockquote's <code>></code>",
             hard_break, "delimiters need to be indented:"),

        verb("*   A list item with a blockquote:\n",
             "\n",
             "    > This is a blockquote\n",
             "    > inside a list item.\n"),

        para(
             "To put a code block within a list item, the code block needs",
             hard_break, "to be indented _twice_ -- 8 spaces or two tabs:"),

        verb("*   A list item with a code block:\n",
             "\n",
             "        <code goes here>\n"),

        para("It's worth noting that it's possible to trigger an ordered list by",
             hard_break, "accident, by writing something like this:"),

        verb("1986. What a great season.\n"),

        para("In other words, a <em>number-period-space</em> sequence at the beginning of a",
             hard_break, "line. To avoid this, you can backslash-escape the period:"),

        verb("1986\\. What a great season.\n"),

        raw("<h3 id=\"precode\">Code Blocks</h3>"),

        para("Pre-formatted code blocks are used for writing about programming or",
             hard_break, "markup source code. Rather than forming normal paragraphs, the lines",
             hard_break, "of a code block are interpreted literally. Markdown wraps a code block",
             hard_break, "in both <code><pre></code> and <code><code></code> tags."),

        para("To produce a code block in Markdown, simply indent every line of the",
             hard_break, "block by at least 4 spaces or 1 tab. For example, given this input:"),

        verb("This is a normal paragraph:\n",
             "\n",
             "    This is a code block.\n"),

        para("Markdown will generate:"),

        verb("<p>This is a normal paragraph:</p>\n",
             "\n",
             "<pre><code>This is a code block.\n",
             "</code></pre>\n"),

        para("One level of indentation -- 4 spaces or 1 tab -- is removed from each",
             hard_break, "line of the code block. For example, this:"),

        verb("Here is an example of AppleScript:\n",
             "\n",
             "    tell application \"Foo\"\n",
             "        beep\n",
             "    end tell\n"),

        para("will turn into:"),

        verb("<p>Here is an example of AppleScript:</p>\n",
             "\n",
             "<pre><code>tell application \"Foo\"\n",
             "    beep\n",
             "end tell\n",
             "</code></pre>\n"),

        para("A code block continues until it reaches a line that is not indented",
             hard_break, "(or the end of the article)."),

        para("Within a code block, ampersands (<code>&</code>) and angle brackets (<code><</code> and <code>></code>)",
             hard_break, "are automatically converted into HTML entities. This makes it very",
             hard_break, "easy to include example HTML source code using Markdown -- just paste",
             hard_break, "it and indent it, and Markdown will handle the hassle of encoding the",
             hard_break, "ampersands and angle brackets. For example, this:"),

        verb("    <div class=\"footer\">\n",
             "        &copy; 2004 Foo Corporation\n",
             "    </div>\n"),

        para("will turn into:"),

        verb("<pre><code>&lt;div class=\"footer\"&gt;\n",
             "    &amp;copy; 2004 Foo Corporation\n",
             "&lt;/div&gt;\n",
             "</code></pre>\n"),

        para("Regular Markdown syntax is not processed within code blocks. E.g.,",
             hard_break, "asterisks are just literal asterisks within a code block. This means",
             hard_break, "it's also easy to use Markdown to write about Markdown's own syntax."),

        raw("<h3 id=\"hr\">Horizontal Rules</h3>"),

        para("You can produce a horizontal rule tag (<code><hr /></code>) by placing three or",
             hard_break, "more hyphens, asterisks, or underscores on a line by themselves. If you",
             hard_break, "wish, you may use spaces between the hyphens or asterisks. Each of the",
             hard_break, "following lines will produce a horizontal rule:"),

        verb("* * *\n",
             "\n",
             "***\n",
             "\n",
             "*****\n",
             "\n",
             "- - -\n",
             "\n",
             "---------------------------------------\n",
             "\n",
             "_ _ _\n"),

        rule(1),

        raw("<h2 id=\"span\">Span Elements</h2>"),

        raw("<h3 id=\"link\">Links</h3>"),

        para("Markdown supports two style of links: _inline_ and _reference_."),

        para("In both styles, the link text is delimited by [square brackets]."),

        para("To create an inline link, use a set of regular parentheses immediately",
             hard_break, "after the link text's closing square bracket. Inside the parentheses,",
             hard_break, "put the URL where you want the link to point, along with an _optional_",
             hard_break, "title for the link, surrounded in quotes. For example:"),

        verb("This is [an example](http://example.com/ \"Title\") inline link.\n",
             "\n",
             "[This link](http://example.net/) has no title attribute.\n"),

        para("Will produce:"),

        verb("<p>This is <a href=\"http://example.com/\" title=\"Title\">\n",
             "an example</a> inline link.</p>\n",
             "\n",
             "<p><a href=\"http://example.net/\">This link</a> has no\n",
             "title attribute.</p>\n"),

        para("If you're referring to a local resource on the same server, you can",
             hard_break, "use relative paths:"),

        verb("See my [About](/about/) page for details.\n"),

        para("Reference-style links use a second set of square brackets, inside",
             hard_break, "which you place a label of your choosing to identify the link:"),

        verb("This is [an example][id] reference-style link.\n"),

        para("You can optionally use a space to separate the sets of brackets:"),

        verb("This is [an example] [id] reference-style link.\n"),

        para("Then, anywhere in the document, you define your link label like this,",
             hard_break, "on a line by itself:"),

        verb("[id]: http://example.com/  \"Optional Title Here\"\n"),

        para("That is:"),

        list(:BULLET,
          item(nil,
            para("Square brackets containing the link identifier (optionally",
                 hard_break, "indented from the left margin using up to three spaces);")),
          item(nil,
            para("followed by a colon;")),
          item(nil,
            para("followed by one or more spaces (or tabs);")),
          item(nil,
            para("followed by the URL for the link;")),
          item(nil,
            para("optionally followed by a title attribute for the link, enclosed",
                 hard_break, "in double or single quotes."))),

        para("The link URL may, optionally, be surrounded by angle brackets:"),

        verb("[id]: <http://example.com/>  \"Optional Title Here\"\n"),

        para("You can put the title attribute on the next line and use extra spaces",
             hard_break, "or tabs for padding, which tends to look better with longer URLs:"),

        verb("[id]: http://example.com/longish/path/to/resource/here\n",
             "    \"Optional Title Here\"\n"),

        para("Link definitions are only used for creating links during Markdown",
             hard_break, "processing, and are stripped from your document in the HTML output."),

        para("Link definition names may consist of letters, numbers, spaces, and punctuation -- but they are _not_ case sensitive. E.g. these two links:"),

        verb("[link text][a]\n",
             "[link text][A]\n"),

        para("are equivalent."),

        para("The <em>implicit link name</em> shortcut allows you to omit the name of the",
             hard_break, "link, in which case the link text itself is used as the name.",
             hard_break, "Just use an empty set of square brackets -- e.g., to link the word",
             hard_break, "\"Google\" to the google.com web site, you could simply write:"),

        verb("[Google][]\n"),

        para("And then define the link:"),

        verb("[Google]: http://google.com/\n"),

        para("Because link names may contain spaces, this shortcut even works for",
            hard_break, "multiple words in the link text:"),


        verb("Visit [Daring Fireball][] for more information.\n"),

        para("And then define the link:"),

        verb("[Daring Fireball]: http://daringfireball.net/\n"),

        para("Link definitions can be placed anywhere in your Markdown document. I",
             hard_break, "tend to put them immediately after each paragraph in which they're",
             hard_break, "used, but if you want, you can put them all at the end of your",
             hard_break, "document, sort of like footnotes."),

        para("Here's an example of reference links in action:"),

        verb("I get 10 times more traffic from [Google] [1] than from\n",
             "[Yahoo] [2] or [MSN] [3].\n",
             "\n",
             "  [1]: http://google.com/        \"Google\"\n",
             "  [2]: http://search.yahoo.com/  \"Yahoo Search\"\n",
             "  [3]: http://search.msn.com/    \"MSN Search\"\n"),

        para("Using the implicit link name shortcut, you could instead write:"),

        verb("I get 10 times more traffic from [Google][] than from\n",
             "[Yahoo][] or [MSN][].\n",
             "\n",
             "  [google]: http://google.com/        \"Google\"\n",
             "  [yahoo]:  http://search.yahoo.com/  \"Yahoo Search\"\n",
             "  [msn]:    http://search.msn.com/    \"MSN Search\"\n"),

        para("Both of the above examples will produce the following HTML output:"),

        verb("<p>I get 10 times more traffic from <a href=\"http://google.com/\"\n",
             "title=\"Google\">Google</a> than from\n",
             "<a href=\"http://search.yahoo.com/\" title=\"Yahoo Search\">Yahoo</a>\n",
             "or <a href=\"http://search.msn.com/\" title=\"MSN Search\">MSN</a>.</p>\n"),

        para("For comparison, here is the same paragraph written using",
             hard_break, "Markdown's inline link style:"),

        verb("I get 10 times more traffic from [Google](http://google.com/ \"Google\")\n",
             "than from [Yahoo](http://search.yahoo.com/ \"Yahoo Search\") or\n",
             "[MSN](http://search.msn.com/ \"MSN Search\").\n"),

        para("The point of reference-style links is not that they're easier to",
             hard_break, "write. The point is that with reference-style links, your document",
             hard_break, "source is vastly more readable. Compare the above examples: using",
             hard_break, "reference-style links, the paragraph itself is only 81 characters",
             hard_break, "long; with inline-style links, it's 176 characters; and as raw HTML,",
             hard_break, "it's 234 characters. In the raw HTML, there's more markup than there",
             hard_break, "is text."),

        para("With Markdown's reference-style links, a source document much more",
             hard_break, "closely resembles the final output, as rendered in a browser. By",
             hard_break, "allowing you to move the markup-related metadata out of the paragraph,",
             hard_break, "you can add links without interrupting the narrative flow of your",
             hard_break, "prose."),

        raw("<h3 id=\"em\">Emphasis</h3>"),

        para("Markdown treats asterisks (<code>*</code>) and underscores (<code>_</code>) as indicators of",
             hard_break, "emphasis. Text wrapped with one <code>*</code> or <code>_</code> will be wrapped with an",
             hard_break, "HTML <code><em></code> tag; double <code>*</code>'s or <code>_</code>'s will be wrapped with an HTML",
             hard_break, "<code><strong></code> tag. E.g., this input:"),

        verb("*single asterisks*\n",
             "\n",
             "_single underscores_\n",
             "\n",
             "**double asterisks**\n",
             "\n",
             "__double underscores__\n"),

        para("will produce:"),

        verb("<em>single asterisks</em>\n",
             "\n",
             "<em>single underscores</em>\n",
             "\n",
             "<strong>double asterisks</strong>\n",
             "\n",
             "<strong>double underscores</strong>\n"),

        para("You can use whichever style you prefer; the lone restriction is that",
             hard_break, "the same character must be used to open and close an emphasis span."),

        para("Emphasis can be used in the middle of a word:"),

        verb("un*fucking*believable\n"),

        para("But if you surround an <code>*</code> or <code>_</code> with spaces, it'll be treated as a",
             hard_break, "literal asterisk or underscore."),

        para("To produce a literal asterisk or underscore at a position where it",
             hard_break, "would otherwise be used as an emphasis delimiter, you can backslash",
             hard_break, "escape it:"),

        verb("\\*this text is surrounded by literal asterisks\\*\n"),

        raw("<h3 id=\"code\">Code</h3>"),

        para("To indicate a span of code, wrap it with backtick quotes (<code>`</code>).",
             hard_break, "Unlike a pre-formatted code block, a code span indicates code within a",
             hard_break, "normal paragraph. For example:"),

        verb("Use the `printf()` function.\n"),

        para("will produce:"),

        verb("<p>Use the <code>printf()</code> function.</p>\n"),

        para("To include a literal backtick character within a code span, you can use",
             hard_break, "multiple backticks as the opening and closing delimiters:"),

        verb("``There is a literal backtick (`) here.``\n"),

        para("which will produce this:"),

        verb("<p><code>There is a literal backtick (`) here.</code></p>\n"),

        para("The backtick delimiters surrounding a code span may include spaces --",
             hard_break, "one after the opening, one before the closing. This allows you to place",
             hard_break, "literal backtick characters at the beginning or end of a code span:"),

        verb("A single backtick in a code span: `` ` ``\n",
             "\n",
             "A backtick-delimited string in a code span: `` `foo` ``\n"),

        para("will produce:"),

        verb("<p>A single backtick in a code span: <code>`</code></p>\n",
             "\n",
             "<p>A backtick-delimited string in a code span: <code>`foo`</code></p>\n"),

        para("With a code span, ampersands and angle brackets are encoded as HTML",
             hard_break, "entities automatically, which makes it easy to include example HTML",
             hard_break, "tags. Markdown will turn this:"),

        verb("Please don't use any `<blink>` tags.\n"),

        para("into:"),

        verb("<p>Please don't use any <code>&lt;blink&gt;</code> tags.</p>\n"),

        para("You can write this:"),

        verb("`&#8212;` is the decimal-encoded equivalent of `&mdash;`.\n"),

        para("to produce:"),

        verb( "<p><code>&amp;#8212;</code> is the decimal-encoded\n",
             "equivalent of <code>&amp;mdash;</code>.</p>\n"),

        raw("<h3 id=\"img\">Images</h3>"),

        para("Admittedly, it's fairly difficult to devise a \"natural\" syntax for",
             hard_break, "placing images into a plain text document format."),

        para("Markdown uses an image syntax that is intended to resemble the syntax",
             hard_break, "for links, allowing for two styles: _inline_ and _reference_."),

        para("Inline image syntax looks like this:"),

        verb("![Alt text](/path/to/img.jpg)\n",
             "\n",
             "![Alt text](/path/to/img.jpg \"Optional title\")\n"),

        para("That is:"),

        list(:BULLET,
          item(nil,
            para("An exclamation mark: <code>!</code>;")),
          item(nil,
            para("followed by a set of square brackets, containing the <code>alt</code>",
                 hard_break, "attribute text for the image;")),
          item(nil,
            para("followed by a set of parentheses, containing the URL or path to",
                 hard_break, "the image, and an optional <code>title</code> attribute enclosed in double",
                 hard_break, "or single quotes."))),

        para("Reference-style image syntax looks like this:"),

        verb("![Alt text][id]\n"),

        para("Where \"id\" is the name of a defined image reference. Image references",
             hard_break, "are defined using syntax identical to link references:"),

        verb("[id]: url/to/image  \"Optional title attribute\"\n"),

        para("As of this writing, Markdown has no syntax for specifying the",
             hard_break, "dimensions of an image; if this is important to you, you can simply",
             hard_break, "use regular HTML <code><img></code> tags."),

        rule(1),

        raw("<h2 id=\"misc\">Miscellaneous</h2>"),

        raw("<h3 id=\"autolink\">Automatic Links</h3>"),

        para("Markdown supports a shortcut style for creating \"automatic\" links for URLs and email addresses: simply surround the URL or email address with angle brackets. What this means is that if you want to show the actual text of a URL or email address, and also have it be a clickable link, you can do this:"),

        verb("<http://example.com/>\n"),

        para("Markdown will turn this into:"),

        verb("<a href=\"http://example.com/\">http://example.com/</a>\n"),

        para("Automatic links for email addresses work similarly, except that",
             hard_break, "Markdown will also perform a bit of randomized decimal and hex",
             hard_break, "entity-encoding to help obscure your address from address-harvesting",
             hard_break, "spambots. For example, Markdown will turn this:"),

        verb("<address@example.com>\n"),

        para("into something like this:"),

        verb("<a href=\"&#x6D;&#x61;i&#x6C;&#x74;&#x6F;:&#x61;&#x64;&#x64;&#x72;&#x65;\n",
             "&#115;&#115;&#64;&#101;&#120;&#x61;&#109;&#x70;&#x6C;e&#x2E;&#99;&#111;\n",
             "&#109;\">&#x61;&#x64;&#x64;&#x72;&#x65;&#115;&#115;&#64;&#101;&#120;&#x61;\n",
             "&#109;&#x70;&#x6C;e&#x2E;&#99;&#111;&#109;</a>\n"),

        para("which will render in a browser as a clickable link to \"address@example.com\"."),

        para("(This sort of entity-encoding trick will indeed fool many, if not",
               hard_break, "most, address-harvesting bots, but it definitely won't fool all of",
               hard_break, "them. It's better than nothing, but an address published in this way",
               hard_break, "will probably eventually start receiving spam.)"),

        raw("<h3 id=\"backslash\">Backslash Escapes</h3>"),

        para("Markdown allows you to use backslash escapes to generate literal",
             hard_break, "characters which would otherwise have special meaning in Markdown's",
             hard_break, "formatting syntax. For example, if you wanted to surround a word with",
             hard_break, "literal asterisks (instead of an HTML <code><em></code> tag), you can backslashes",
             hard_break, "before the asterisks, like this:"),

        verb("\\*literal asterisks\\*\n"),

        para("Markdown provides backslash escapes for the following characters:"),

        verb("\\   backslash\n",
             "`   backtick\n",
             "*   asterisk\n",
             "_   underscore\n",
             "{}  curly braces\n",
             "[]  square brackets\n",
             "()  parentheses\n",
             "#   hash mark\n",
             "+	plus sign\n",
             "-	minus sign (hyphen)\n",
             ".   dot\n",
             "!   exclamation mark\n"))

    assert_equal expected, doc
  end

  def test_nested_blockquotes
    input = File.read "#{MARKDOWN_TEST_PATH}/Nested blockquotes.text"

    doc = @parser.parse input

    expected =
      doc(
        block(
          para("foo"),
          block(
            para("bar")),
          para("foo")))

    assert_equal expected, doc
  end

  def test_ordered_and_unordered_lists
    input = File.read "#{MARKDOWN_TEST_PATH}/Ordered and unordered lists.text"

    doc = @parser.parse input

    expected =
      doc(
        head(2, 'Unordered'),

        para('Asterisks tight:'),
        list(:BULLET,
          item(nil, para("asterisk 1")),
          item(nil, para("asterisk 2")),
          item(nil, para("asterisk 3"))),
        para('Asterisks loose:'),
        list(:BULLET,
          item(nil, para("asterisk 1")),
          item(nil, para("asterisk 2")),
          item(nil, para("asterisk 3"))),

        rule(1),

        para("Pluses tight:"),
        list(:BULLET,
          item(nil, para("Plus 1")),
          item(nil, para("Plus 2")),
          item(nil, para("Plus 3"))),
        para("Pluses loose:"),
        list(:BULLET,
          item(nil, para("Plus 1")),
          item(nil, para("Plus 2")),
          item(nil, para("Plus 3"))),

        rule(1),

        para("Minuses tight:"),
        list(:BULLET,
          item(nil, para("Minus 1")),
          item(nil, para("Minus 2")),
          item(nil, para("Minus 3"))),
        para("Minuses loose:"),
        list(:BULLET,
          item(nil, para("Minus 1")),
          item(nil, para("Minus 2")),
          item(nil, para("Minus 3"))),

        head(2, "Ordered"),

        para("Tight:"),
        list(:NUMBER,
          item(nil, para("First")),
          item(nil, para("Second")),
          item(nil, para("Third"))),
        para("and:"),
        list(:NUMBER,
          item(nil, para("One")),
          item(nil, para("Two")),
          item(nil, para("Three"))),

        para("Loose using tabs:"),
        list(:NUMBER,
          item(nil, para("First")),
          item(nil, para("Second")),
          item(nil, para("Third"))),
        para("and using spaces:"),
        list(:NUMBER,
          item(nil, para("One")),
          item(nil, para("Two")),
          item(nil, para("Three"))),

        para("Multiple paragraphs:"),
        list(:NUMBER,
          item(nil,
            para("Item 1, graf one."),
            para("Item 2. graf two. The quick brown fox " +
                 "jumped over the lazy dog's", hard_break,
                 "back.")),
          item(nil, para("Item 2.")),
          item(nil, para("Item 3."))),

        head(2, "Nested"),
        list(:BULLET,
          item(nil,
            para("Tab"),
            list(:BULLET,
              item(nil,
                para("Tab"),
                list(:BULLET,
                  item(nil,
                    para("Tab"))))))),

        para("Here's another:"),
        list(:NUMBER,
          item(nil, para("First")),
          item(nil, para("Second:"),
            list(:BULLET,
              item(nil, para("Fee")),
              item(nil, para("Fie")),
              item(nil, para("Foe")))),
          item(nil, para("Third"))),

        para("Same thing but with paragraphs:"),
        list(:NUMBER,
          item(nil, para("First")),
          item(nil, para("Second:"),
            list(:BULLET,
              item(nil, para("Fee")),
              item(nil, para("Fie")),
              item(nil, para("Foe")))),
          item(nil, para("Third"))),

        para("This was an error in Markdown 1.0.1:"),
        list(:BULLET,
          item(nil,
            para("this"),
            list(:BULLET,
              item(nil, para("sub"))),
            para("that"))))

    assert_equal expected, doc
  end

  def test_strong_and_em_together
    input = File.read "#{MARKDOWN_TEST_PATH}/Strong and em together.text"

    doc = @parser.parse input

    expected =
      doc(
        para("<b><em>This is strong and em.</em></b>"),
        para("So is <b>_this_</b> word."),
        para("<b><em>This is strong and em.</em></b>"),
        para("So is <b>_this_</b> word."))

    assert_equal expected, doc
  end

  def test_tabs
    input = File.read "#{MARKDOWN_TEST_PATH}/Tabs.text"

    doc = @parser.parse input

    expected =
      doc(
        list(:BULLET,
          item(nil,
            para("this is a list item", hard_break, "indented with tabs")),
          item(nil,
            para("this is a list item", hard_break, "indented with spaces"))),

        para("Code:"),

        verb("this code block is indented by one tab\n"),

        para("And:"),

        verb("\tthis code block is indented by two tabs\n"),

        para("And:"),

        verb(
          "+\tthis is an example list item\n",
          "\tindented with tabs\n",
          "\n",
          "+   this is an example list item\n",
          "    indented with spaces\n"))

    assert_equal expected, doc
  end

  def test_tidiness
    input = File.read "#{MARKDOWN_TEST_PATH}/Tidiness.text"

    doc = @parser.parse input

    expected =
      doc(
        block(
          para("A list within a blockquote:"),
          list(:BULLET,
            item(nil, para("asterisk 1")),
            item(nil, para("asterisk 2")),
            item(nil, para("asterisk 3")))))

    assert_equal expected, doc
  end

end
