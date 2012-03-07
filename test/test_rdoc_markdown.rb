# coding: UTF-8

require 'rubygems'
require 'minitest/autorun'
require 'pp'

require 'rdoc'
require 'rdoc/markup/block_quote'
require 'rdoc/markdown'

class TestRDocMarkdown < RDoc::TestCase

  def setup
    @RM = RDoc::Markup

    @parser = RDoc::Markdown.new
  end

  def mu_pp obj
    s = ''
    s = PP.pp obj, s
    s.force_encoding Encoding.default_external if defined? Encoding
    s.chomp
  end

  def test_parse_auto_link_email
    doc = parse "Autolink: <nobody@example>"

    expected = doc(para("Autolink: mailto:nobody@example"))

    assert_equal expected, doc
  end

  def test_parse_auto_link_url
    doc = parse "Autolink: <http://example>"

    expected = doc(para("Autolink: http://example"))

    assert_equal expected, doc
  end

  def test_parse_block_quote
    doc = parse <<-BLOCK_QUOTE
> this is
> a block quote
    BLOCK_QUOTE

    expected = @RM::Document.new(
      @RM::BlockQuote.new("this is\n", "a block quote\n"))

    assert_equal expected, doc
  end

  def test_parse_block_quote_continue
    doc = parse <<-BLOCK_QUOTE
> this is
a block quote
    BLOCK_QUOTE

    expected = @RM::Document.new(
      @RM::BlockQuote.new("this is\n", "a block quote\n"))

    assert_equal expected, doc
  end

  def test_parse_block_quote_newline
    doc = parse <<-BLOCK_QUOTE
> this is
a block quote

    BLOCK_QUOTE

    expected = @RM::Document.new(
      @RM::BlockQuote.new("this is\n", "a block quote\n", "\n"))

    assert_equal expected, doc
  end

  def test_parse_block_quote_separate
    doc = parse <<-BLOCK_QUOTE
> this is
a block quote

> that continues
    BLOCK_QUOTE

    expected = @RM::Document.new(
      @RM::BlockQuote.new("this is\n", "a block quote\n",
                          "\n",
                          "that continues\n"))

    assert_equal expected, doc
  end

  def test_parse_code
    doc = parse "Code: `text`"

    expected = doc(para("Code: <code>text</code>"))

    assert_equal expected, doc
  end

  def test_parse_entity_dec
    doc = parse "Entity: &#65;"

    expected = doc(para("Entity: A"))

    assert_equal expected, doc
  end

  def test_parse_entity_hex
    doc = parse "Entity: &#x41;"

    expected = doc(para("Entity: A"))

    assert_equal expected, doc
  end

  def test_parse_entity_named
    doc = parse "Entity: &pi;"

    expected = doc(para("Entity: π"))

    assert_equal expected, doc
  end

  def test_parse_emphasis_star
    doc = parse "it *works*\n"

    expected = @RM::Document.new(
      @RM::Paragraph.new("it _works_"))

    assert_equal expected, doc
  end

  def test_parse_emphasis_underscore
    doc = parse "it _works_\n"

    expected = @RM::Document.new(
      @RM::Paragraph.new("it _works_"))

    assert_equal expected, doc
  end

  def test_parse_escape
    doc = parse "Backtick: \\`"

    expected = doc(para("Backtick: `"))

    assert_equal expected, doc
  end

  def test_parse_heading_atx
    doc = parse "# heading\n"

    expected = @RM::Document.new(
      @RM::Heading.new(1, "heading"))

    assert_equal expected, doc
  end

  def test_parse_heading_setext_dash
    doc = parse <<-MD
heading
---
    MD

    expected = @RM::Document.new(
      @RM::Heading.new(2, "heading"))

    assert_equal expected, doc
  end

  def test_parse_heading_setext_equals
    doc = parse <<-MD
heading
===
    MD

    expected = @RM::Document.new(
      @RM::Heading.new(1, "heading"))

    assert_equal expected, doc
  end

  def test_parse_html
    @parser.html = true

    doc = parse "<address>Links here</address>\n"

    expected = doc(
      @RM::Raw.new("<address>Links here</address>"))

    assert_equal expected, doc
  end

  def test_parse_html_no_html
    doc = parse "<address>Links here</address>\n"

    expected = doc()

    assert_equal expected, doc
  end

  def test_parse_image
    doc = parse "image ![alt text](path/to/image.jpg)"

    expected = doc(para("image path/to/image.jpg"))

    assert_equal expected, doc
  end

  def test_parse_line_break
    doc = parse "Some text  \nwith extra lines"

    expected = doc(
      para("Some text  \nwith extra lines"))

    assert_equal expected, doc
  end

  def test_parse_link_reference_id
    doc = parse <<-MD
This is [an example][id] reference-style link.

[id]: http://example.com "Optional Title Here"
    MD

    expected = doc(
      para("This is {an example}[http://example.com] reference-style link."))

    assert_equal expected, doc
  end

  def test_parse_link_reference_id_many
    doc = parse <<-MD
This is [an example][id] reference-style link.

And [another][id].

[id]: http://example.com "Optional Title Here"
    MD

    expected = doc(
      para("This is {an example}[http://example.com] reference-style link."),
      para("And {another}[http://example.com]."))

    assert_equal expected, doc
  end

  def test_parse_link_reference_implicit
    doc = parse <<-MD
This is [an example][] reference-style link.

[an example]: http://example.com "Optional Title Here"
    MD

    expected = doc(
      para("This is {an example}[http://example.com] reference-style link."))

    assert_equal expected, doc
  end

  def test_parse_list_bullet
    doc = parse <<-MD
* one
* two
    MD

    expected = @RM::Document.new(
      @RM::List.new(:BULLET, *[
        @RM::ListItem.new(nil, @RM::Paragraph.new("one\n")),
        @RM::ListItem.new(nil, @RM::Paragraph.new("two\n"))]))

    assert_equal expected, doc
  end

  def test_parse_list_bullet_continue
    doc = parse <<-MD
* one

* two
    MD

    expected = @RM::Document.new(
      @RM::List.new(:BULLET, *[
        @RM::ListItem.new(nil, @RM::Paragraph.new("one\n")),
        @RM::ListItem.new(nil, @RM::Paragraph.new("two\n"))]))

    assert_equal expected, doc
  end

  def test_parse_list_bullet_nest
    doc = parse <<-MD
* outer
    * inner
    MD

    expected = @RM::Document.new(
      @RM::List.new(:BULLET, *[
        @RM::ListItem.new(nil,
          @RM::Paragraph.new("outer\n"),
          @RM::List.new(:BULLET, *[
            @RM::ListItem.new(nil, @RM::Paragraph.new("inner\n"))]))]))

    assert_equal expected, doc
  end

  def test_parse_list_bullet_nest_loose
    doc = parse <<-MD
* outer

    * inner
    MD

    expected = @RM::Document.new(
      @RM::List.new(:BULLET, *[
        @RM::ListItem.new(nil,
          @RM::Paragraph.new("outer\n"),
          @RM::List.new(:BULLET, *[
            @RM::ListItem.new(nil, @RM::Paragraph.new("inner\n"))]))]))

    assert_equal expected, doc
  end

  def test_parse_list_bullet_nest_continue
    doc = parse <<-MD
* outer
    * inner
  continue
* outer 2
    MD

    expected = @RM::Document.new(
      @RM::List.new(:BULLET, *[
        @RM::ListItem.new(nil,
          @RM::Paragraph.new("outer\n"),
          @RM::List.new(:BULLET, *[
            @RM::ListItem.new(nil,
              @RM::Paragraph.new("inner\n   continue\n"))])),
        @RM::ListItem.new(nil,
          @RM::Paragraph.new("outer 2\n"))]))

    assert_equal expected, doc
  end

  def test_parse_list_number
    doc = parse <<-MD
1. one
1. two
    MD

    expected = @RM::Document.new(
      @RM::List.new(:NUMBER, *[
        @RM::ListItem.new(nil, @RM::Paragraph.new("one\n")),
        @RM::ListItem.new(nil, @RM::Paragraph.new("two\n"))]))

    assert_equal expected, doc
  end

  def test_parse_list_number_continue
    doc = parse <<-MD
1. one

1. two
    MD

    expected = @RM::Document.new(
      @RM::List.new(:NUMBER, *[
        @RM::ListItem.new(nil, @RM::Paragraph.new("one\n")),
        @RM::ListItem.new(nil, @RM::Paragraph.new("two\n"))]))

    assert_equal expected, doc
  end

  def test_parse_note
    @parser.notes = true

    doc = parse <<-MD
Some text.[^1]

[^1]: With a footnote
    MD

    expected = doc(
      para("Some text.{*1}[rdoc-label:foottext-1:footmark-1]"),
      @RM::Rule.new(1),
      para("{^1}[rdoc-label:footmark-1:foottext-1] With a footnote\n"))

    assert_equal expected, doc
  end

  def test_parse_note_indent
    @parser.notes = true

    doc = parse <<-MD
Some text.[^1]

[^1]: With a footnote

    more
    MD

    expected = doc(
      para("Some text.{*1}[rdoc-label:foottext-1:footmark-1]"),
      @RM::Rule.new(1),
      para("{^1}[rdoc-label:footmark-1:foottext-1] With a footnote\n\nmore\n"))

    assert_equal expected, doc
  end

  def test_parse_note_inline
    @parser.notes = true

    doc = parse <<-MD
Some text. ^[With a footnote]
    MD

    expected = doc(
      para("Some text. {*1}[rdoc-label:foottext-1:footmark-1]"),
      @RM::Rule.new(1),
      para("{^1}[rdoc-label:footmark-1:foottext-1] With a footnote"))

    assert_equal expected, doc
  end

  def test_parse_note_no_notes
    assert_raises RuntimeError do
      parse "Some text.[^1]"
    end
  end

  def test_parse_paragraph
    doc = parse "it worked\n"

    expected = @RM::Document.new(
      @RM::Paragraph.new("it worked"))

    assert_equal expected, doc
  end

  def test_parse_paragraph_stars
    doc = parse "it worked ****\n"

    expected = @RM::Document.new(
      @RM::Paragraph.new("it worked ****"))

    assert_equal expected, doc
  end

  def test_parse_paragraph_html
    @parser.html = true

    doc = parse "<address>Links here</address>"

    expected = @RM::Document.new(
      @RM::Paragraph.new("<address>Links here</address>"))

    assert_equal expected, doc
  end

  def test_parse_paragraph_html_no_html
    doc = parse "<address>Links here</address>"

    expected = @RM::Document.new(
      @RM::Paragraph.new("Links here"))

    assert_equal expected, doc
  end

  def test_parse_paragraph_indent_one
    doc = parse <<-MD
 text
    MD

    expected = @RM::Document.new(@RM::Paragraph.new(" text"))

    assert_equal expected, doc
  end

  def test_parse_paragraph_indent_two
    doc = parse <<-MD
  text
    MD

    expected = @RM::Document.new(@RM::Paragraph.new(" text"))

    assert_equal expected, doc
  end

  def test_parse_paragraph_indent_three
    doc = parse <<-MD
   text
    MD

    expected = @RM::Document.new(@RM::Paragraph.new(" text"))

    assert_equal expected, doc
  end

  def test_parse_paragraph_multiline
    doc = parse "one\ntwo"

    expected = doc(para("one\ntwo"))

    assert_equal expected, doc
  end

  def test_parse_paragraph_two
    doc = parse "one\n\ntwo"

    expected = @RM::Document.new(
      @RM::Paragraph.new("one"),
      @RM::Paragraph.new("two"))

    assert_equal expected, doc
  end

  def test_parse_plain
    doc = parse "it worked"

    expected = @RM::Document.new(
      @RM::Paragraph.new("it worked"))

    assert_equal expected, doc
  end

  def test_parse_rule_dash
    doc = parse "- - -\n\n"

    expected = @RM::Document.new(@RM::Rule.new(1))

    assert_equal expected, doc
  end

  def test_parse_rule_underscore
    doc = parse "_ _ _\n\n"

    expected = @RM::Document.new(@RM::Rule.new(1))

    assert_equal expected, doc
  end

  def test_parse_rule_star
    doc = parse "* * *\n\n"

    expected = @RM::Document.new(@RM::Rule.new(1))

    assert_equal expected, doc
  end

  def test_parse_strong_star
    doc = parse "it **works**\n"

    expected = @RM::Document.new(
      @RM::Paragraph.new("it *works*"))

    assert_equal expected, doc
  end

  def test_parse_strong_underscore
    doc = parse "it __works__\n"

    expected = @RM::Document.new(
      @RM::Paragraph.new("it *works*"))

    assert_equal expected, doc
  end

  def test_parse_style
    @parser.css = true

    doc = parse "<style>h1 { color: red }</style>\n"

    expected = doc(
      @RM::Raw.new("<style>h1 { color: red }</style>"))

    assert_equal expected, doc
  end

  def test_parse_style_disabled
    doc = parse "<style>h1 { color: red }</style>\n"

    expected = doc()

    assert_equal expected, doc
  end

  def test_parse_verbatim
    doc = parse <<-MD
    text
    MD

    expected = @RM::Document.new(@RM::Verbatim.new(["text\n"]))

    assert_equal expected, doc
  end

  def doc *a
    @RM::Document.new(*a)
  end

  def para *a
    @RM::Paragraph.new(*a)
  end

  def parse text
    @parser.parse text
  end

end

