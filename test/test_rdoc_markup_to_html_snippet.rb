require 'rdoc/test_case'

class TestRDocMarkupToHtmlSnippet < RDoc::Markup::FormatterTestCase

  add_visitor_tests

  def setup
    super

    @to = RDoc::Markup::ToHtmlSnippet.new
  end

  def accept_blank_line
    assert_empty @to.res.join
  end

  def accept_document
    assert_equal "<p>hello\n", @to.res.join
    assert_equal 5, @to.chars
  end

  def accept_heading
    assert_equal "<p>Hello\n", @to.res.join
    assert_equal 5, @to.chars
  end

  def accept_heading_1
    assert_equal "<p>Hello\n", @to.res.join
    assert_equal 5, @to.chars
  end

  def accept_heading_2
    assert_equal "<p>Hello\n", @to.res.join
    assert_equal 5, @to.chars
  end

  def accept_heading_3
    assert_equal "<p>Hello\n", @to.res.join
    assert_equal 5, @to.chars
  end

  def accept_heading_4
    assert_equal "<p>Hello\n", @to.res.join
    assert_equal 5, @to.chars
  end

  def accept_heading_b
    assert_equal "<p><strong>Hello</strong>\n",
                 @to.res.join
    assert_equal 5, @to.chars
  end

  def accept_heading_suppressed_crossref
    assert_equal "<p>Hello\n", @to.res.join
    assert_equal 5, @to.chars
  end

  def accept_list_end_bullet
    assert_equal [], @to.list
    assert_equal [], @to.in_list_entry

    assert_equal "\n", @to.res.join
    assert_equal 0, @to.chars
  end

  def accept_list_end_label
    assert_equal [], @to.list
    assert_equal [], @to.in_list_entry

    assert_equal "\n", @to.res.join
    assert_equal 0, @to.chars
  end

  def accept_list_end_lalpha
    assert_equal [], @to.list
    assert_equal [], @to.in_list_entry

    assert_equal "\n", @to.res.join
    assert_equal 0, @to.chars
  end

  def accept_list_end_number
    assert_equal [], @to.list
    assert_equal [], @to.in_list_entry

    assert_equal "\n", @to.res.join
    assert_equal 0, @to.chars
  end

  def accept_list_end_note
    assert_equal [], @to.list
    assert_equal [], @to.in_list_entry

    assert_equal "\n", @to.res.join
    assert_equal 0, @to.chars
  end

  def accept_list_end_ualpha
    assert_equal [], @to.list
    assert_equal [], @to.in_list_entry

    assert_equal "\n", @to.res.join
    assert_equal 0, @to.chars
  end

  def accept_list_item_end_bullet
    assert_equal [''], @to.in_list_entry
    assert_equal 0, @to.chars
  end

  def accept_list_item_end_label
    assert_equal [''], @to.in_list_entry
    assert_equal 4, @to.chars
  end

  def accept_list_item_end_lalpha
    assert_equal [''], @to.in_list_entry
    assert_equal 0, @to.chars
  end

  def accept_list_item_end_note
    assert_equal [''], @to.in_list_entry
    assert_equal 4, @to.chars
  end

  def accept_list_item_end_number
    assert_equal [''], @to.in_list_entry
    assert_equal 0, @to.chars
  end

  def accept_list_item_end_ualpha
    assert_equal [''], @to.in_list_entry
    assert_equal 0, @to.chars
  end

  def accept_list_item_start_bullet
    assert_equal "<p>", @to.res.join
    assert_equal 0, @to.chars
  end

  def accept_list_item_start_label
    assert_equal "<p>cat &mdash; ", @to.res.join
    assert_equal 4, @to.chars
  end

  def accept_list_item_start_lalpha
    assert_equal "<p>", @to.res.join
    assert_equal 0, @to.chars
  end

  def accept_list_item_start_note
    assert_equal "<p>cat &mdash; ",
                 @to.res.join
    assert_equal 4, @to.chars
  end

  def accept_list_item_start_note_2
    expected = <<-EXPECTED
<p><code>teletype</code> &mdash; teletype description

    EXPECTED

    assert_equal expected, @to.res.join
    assert_equal 29, @to.chars
  end

  def accept_list_item_start_number
    assert_equal "<p>", @to.res.join
    assert_equal 0, @to.chars
  end

  def accept_list_item_start_ualpha
    assert_equal "<p>", @to.res.join
    assert_equal 0, @to.chars
  end

  def accept_list_start_bullet
    assert_equal [:BULLET], @to.list
    assert_equal [''], @to.in_list_entry

    assert_equal '', @to.res.join
    assert_equal 0, @to.chars
  end

  def accept_list_start_label
    assert_equal [:LABEL], @to.list
    assert_equal [''], @to.in_list_entry

    assert_equal '', @to.res.join
    assert_equal 0, @to.chars
  end

  def accept_list_start_lalpha
    assert_equal [:LALPHA], @to.list
    assert_equal [''], @to.in_list_entry

    assert_equal '', @to.res.join
    assert_equal 0, @to.chars
  end

  def accept_list_start_note
    assert_equal [:NOTE], @to.list
    assert_equal [''], @to.in_list_entry

    assert_equal '', @to.res.join
    assert_equal 0, @to.chars
  end

  def accept_list_start_number
    assert_equal [:NUMBER], @to.list
    assert_equal [''], @to.in_list_entry

    assert_equal '', @to.res.join
    assert_equal 0, @to.chars
  end

  def accept_list_start_ualpha
    assert_equal [:UALPHA], @to.list
    assert_equal [''], @to.in_list_entry

    assert_equal '', @to.res.join
    assert_equal 0, @to.chars
  end

  def accept_paragraph
    assert_equal "<p>hi\n", @to.res.join

    assert_equal 2, @to.chars
  end

  def accept_paragraph_b
    assert_equal "<p>reg <strong>bold words</strong> reg\n", @to.res.join

    assert_equal 18, @to.chars
  end

  def accept_paragraph_i
    assert_equal "<p>reg <em>italic words</em> reg\n", @to.res.join

    assert_equal 20, @to.chars
  end

  def accept_paragraph_plus
    assert_equal "<p>reg <code>teletype</code> reg\n", @to.res.join

    assert_equal 16, @to.chars
  end

  def accept_paragraph_star
    assert_equal "<p>reg <strong>bold</strong> reg\n", @to.res.join

    assert_equal 12, @to.chars
  end

  def accept_paragraph_underscore
    assert_equal "<p>reg <em>italic</em> reg\n", @to.res.join

    assert_equal 14, @to.chars
  end

  def accept_raw
    raw = <<-RAW.rstrip
<table>
<tr><th>Name<th>Count
<tr><td>a<td>1
<tr><td>b<td>2
</table>
    RAW

    assert_equal '', @to.res.join
    assert_equal 0, @to.chars
  end

  def accept_rule
    assert_empty @to.res
    assert_equal 0, @to.chars
  end

  def accept_verbatim
    assert_equal "\n<pre>hi\n  world</pre>\n", @to.res.join
    assert_equal 10, @to.chars
  end

  def end_accepting
    assert_equal 'hi', @to.res.join
  end

  def start_accepting
    assert_equal [], @to.res
    assert_equal [], @to.in_list_entry
    assert_equal [], @to.list
    assert_equal 0,  @to.chars
  end

  def list_nested
    expected = <<-EXPECTED
<p>l1
<p>l1.1

<p>l2

    EXPECTED

    assert_equal expected, @to.res.join
    assert_equal 8, @to.chars
  end

  def list_verbatim
    expected = <<-EXPECTED
<p>list stuff

<pre>* list
  with

  second

  1. indented
  2. numbered

  third

* second</pre>

    EXPECTED

    assert_equal expected, @to.end_accepting
    assert_equal 81, @to.chars
  end

  def test_accept_heading_7
    @to.start_accepting

    @to.accept_heading @RM::Heading.new(7, 'Hello')

    assert_equal "<p>Hello\n", @to.res.join
    assert_equal 5, @to.chars
  end

  def test_accept_heading_aref_class
    @to.code_object = RDoc::NormalClass.new 'Foo'
    @to.start_accepting

    @to.accept_heading @RM::Heading.new(1, 'Hello')

    assert_equal "<p>Hello\n",
                 @to.res.join
    assert_equal 5, @to.chars
  end

  def test_accept_heading_aref_method
    @to.code_object = RDoc::AnyMethod.new nil, 'foo'
    @to.start_accepting

    @to.accept_heading @RM::Heading.new(1, 'Hello')

    assert_equal "<p>Hello\n",
                 @to.res.join
    assert_equal 5, @to.chars
  end

  def test_accept_verbatim_ruby
    options = RDoc::Options.new
    rdoc = RDoc::RDoc.new
    rdoc.options = options
    RDoc::RDoc.current = rdoc

    verb = @RM::Verbatim.new("class C\n", "end\n")

    @to.start_accepting
    @to.accept_verbatim verb

    expected = <<-EXPECTED

<pre class="ruby"><span class="ruby-keyword">class</span> <span class="ruby-constant">C</span>
<span class="ruby-keyword">end</span>
</pre>
    EXPECTED

    assert_equal expected, @to.res.join
    assert_equal 11, @to.chars
  end

  def test_accept_verbatim_ruby_error
    options = RDoc::Options.new
    rdoc = RDoc::RDoc.new
    rdoc.options = options
    RDoc::RDoc.current = rdoc

    verb = @RM::Verbatim.new("a %z'foo' # => blah\n")

    @to.start_accepting
    @to.accept_verbatim verb

    expected = <<-EXPECTED

<pre>a %z'foo' # =&gt; blah
</pre>
    EXPECTED

    assert_equal expected, @to.res.join
    assert_equal 19, @to.chars
  end

  def test_convert_limit
    rdoc = <<-RDOC
= Hello

This is some text, it *will* be cut off

* After 100 characters
* And an elipsis must follow

So there you have it
    RDOC

    expected = <<-EXPECTED
<p>Hello
<p>This is some text, it <strong>will</strong> be cut off
<p>After 100 characters
<p>And an elipsis must follow

<p>So there you...
    EXPECTED

    actual = @to.convert rdoc

    assert_equal 108, @to.chars
    assert_equal expected, actual
  end

  def test_convert_limit_2
    rdoc = <<-RDOC
Outputs formatted RI data for the class or method +name+.

Returns true if +name+ was found, false if it was not an alternative could
be guessed, raises an error if +name+ couldn't be guessed.
    RDOC

    expected = <<-EXPECTED
<p>Outputs formatted RI data for the class or method <code>name</code>.
<p>Returns true if <code>name</code> was found, false if it was...
    EXPECTED

    actual = @to.convert rdoc

    assert_equal expected, actual
    assert_equal 159, @to.chars
  end

  def test_convert_limit_in_tag
    rdoc = "* ab *c*\n" * 30

    expected = "<p>ab <strong>c</strong>\n" * 25
    expected.chomp!
    expected << "...\n"

    actual = @to.convert rdoc

    assert_equal 100, @to.chars
    assert_equal expected, actual
  end

  def test_convert_limit_verbatim
    rdoc = <<-RDOC
= Hello

This is some text, it *will* be cut off

* After 100 characters
And an elipsis must follow

  So there you have it
    RDOC

    expected = <<-EXPECTED.chomp
<p>Hello
<p>This is some text, it <strong>will</strong> be cut off
<p>After 100 characters

<p>And an elipsis must follow

<pre>So there you</pre>
...
    EXPECTED

    actual = @to.convert rdoc

    assert_equal 108, @to.chars
    assert_equal expected, actual
  end

  def test_convert_limit_over
    rdoc = "* text\n" * 30

    expected = "<p>text\n" * 25
    expected.chomp!
    expected << "...\n"

    actual = @to.convert rdoc

    assert_equal 100, @to.chars
    assert_equal expected, actual
  end

  def test_convert_string
    assert_equal '&lt;&gt;', @to.convert_string('<>')
  end

  def test_convert_RDOCLINK_label_label
    result = @to.convert 'rdoc-label:label-One'

    assert_equal "<p>One\n", result
    assert_equal 3, @to.chars
  end

  def test_convert_RDOCLINK_label_foottext
    result = @to.convert 'rdoc-label:foottext-1'

    assert_equal "<p>*1\n", result
    assert_equal 2, @to.chars
  end

  def test_convert_RDOCLINK_label_footmark
    result = @to.convert 'rdoc-label:footmark-1'

    assert_equal "<p>^1\n", result
    assert_equal 2, @to.chars
  end

  def test_convert_RDOCLINK_ref
    result = @to.convert 'rdoc-ref:C'

    assert_equal "<p>C\n", result
    assert_equal 1, @to.chars
  end

  def test_convert_TIDYLINK_rdoc_label
    result = @to.convert '{foo}[rdoc-label:foottext-1]'

    assert_equal "<p>foo\n", result
    assert_equal 3, @to.chars
  end

  def test_handle_special_HYPERLINK_link
    special = RDoc::Markup::Special.new 0, 'link:README.txt'

    link = @to.handle_special_HYPERLINK special

    assert_equal 'README.txt', link
  end

  def test_list_verbatim_2
    str = "* one\n    verb1\n    verb2\n* two\n"

    expected = <<-EXPECTED
<p>one

<pre>verb1
verb2</pre>
<p>two

    EXPECTED

    assert_equal expected, @m.convert(str, @to)
    assert_equal 17, @to.chars
  end

  def test_on_tags
    on = RDoc::Markup::AttrChanger.new 2, 0

    @to.on_tags [], on

    assert_equal 2, @to.mask
  end

  def test_off_tags
    on  = RDoc::Markup::AttrChanger.new 2, 0
    off = RDoc::Markup::AttrChanger.new 0, 2

    @to.on_tags  [], on
    @to.off_tags [], off

    assert_equal 0, @to.mask
  end

  def test_to_html
    assert_equal "<p><code>--</code>\n", util_format("<tt>--</tt>")
    assert_equal 2, @to.chars
  end

  def util_format text
    paragraph = RDoc::Markup::Paragraph.new text

    @to.start_accepting
    @to.accept_paragraph paragraph
    @to.end_accepting
  end

end

