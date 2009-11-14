require 'rubygems'
require 'rdoc/markup/formatter_test_case'
require 'rdoc/markup/to_ansi'
require 'minitest/autorun'

class TestRDocMarkupToAnsi < RDoc::Markup::FormatterTestCase

  add_visitor_tests

  def setup
    super
    
    @to = RDoc::Markup::ToAnsi.new
  end

  def accept_blank_line
    assert_equal "\n", @to.res.join
  end

  def accept_heading
    assert_equal "Hello\n", @to.res.join
  end

  def accept_list_end_bullet
    assert_empty @to.list_index
    assert_empty @to.list_type
    assert_empty @to.list_width
  end

  def accept_list_end_label
    assert_empty @to.list_index
    assert_empty @to.list_type
    assert_empty @to.list_width
  end

  def accept_list_end_lalpha
    assert_empty @to.list_index
    assert_empty @to.list_type
    assert_empty @to.list_width
  end

  def accept_list_end_note
    assert_empty @to.list_index
    assert_empty @to.list_type
    assert_empty @to.list_width
  end

  def accept_list_end_number
    assert_empty @to.list_index
    assert_empty @to.list_type
    assert_empty @to.list_width
  end

  def accept_list_end_ualpha
    assert_empty @to.list_index
    assert_empty @to.list_type
    assert_empty @to.list_width
  end

  def accept_list_item_end_bullet
    assert_equal 0, @to.indent, 'indent'
  end

  def accept_list_item_end_label
    assert_equal 0, @to.indent, 'indent'
  end

  def accept_list_item_end_lalpha
    assert_equal 0, @to.indent, 'indent'
    assert_equal 'b', @to.list_index.last
  end

  def accept_list_item_end_note
    assert_equal 0, @to.indent, 'indent'
  end

  def accept_list_item_end_number
    assert_equal 0, @to.indent, 'indent'
    assert_equal 2, @to.list_index.last
  end

  def accept_list_item_end_ualpha
    assert_equal 0, @to.indent, 'indent'
    assert_equal 'B', @to.list_index.last
  end

  def accept_list_item_start_bullet
    assert_empty @to.res
    assert_equal '* ', @to.prefix
  end

  def accept_list_item_start_label
    assert_empty @to.res
    assert_equal 'cat: ', @to.prefix

    assert_equal 5, @to.indent
  end

  def accept_list_item_start_lalpha
    assert_empty @to.res
    assert_equal 'a. ', @to.prefix

    assert_equal 'a', @to.list_index.last
    assert_equal 3, @to.indent
  end

  def accept_list_item_start_note
    assert_empty @to.res
    assert_equal 'cat: ', @to.prefix

    assert_equal 5, @to.indent
  end

  def accept_list_item_start_number
    assert_empty @to.res
    assert_equal '1. ', @to.prefix

    assert_equal 1, @to.list_index.last
    assert_equal 3, @to.indent
  end

  def accept_list_item_start_ualpha
    assert_empty @to.res
    assert_equal 'A. ', @to.prefix

    assert_equal 'A', @to.list_index.last
    assert_equal 3, @to.indent
  end

  def accept_list_start_bullet
    assert_equal '', @to.res.join
    assert_equal [nil],     @to.list_index
    assert_equal [:BULLET], @to.list_type
    assert_equal [1],       @to.list_width
  end

  def accept_list_start_label
    assert_equal '', @to.res.join
    assert_equal [nil],    @to.list_index
    assert_equal [:LABEL], @to.list_type
    assert_equal [4],      @to.list_width
  end

  def accept_list_start_lalpha
    assert_equal '', @to.res.join
    assert_equal ['a'],     @to.list_index
    assert_equal [:LALPHA], @to.list_type
    assert_equal [1],       @to.list_width
  end

  def accept_list_start_note
    assert_equal '', @to.res.join
    assert_equal [nil],   @to.list_index
    assert_equal [:NOTE], @to.list_type
    assert_equal [4],     @to.list_width
  end

  def accept_list_start_number
    assert_equal '', @to.res.join
    assert_equal [1],       @to.list_index
    assert_equal [:NUMBER], @to.list_type
    assert_equal [1],       @to.list_width
  end

  def accept_list_start_ualpha
    assert_equal '', @to.res.join
    assert_equal ['A'],     @to.list_index
    assert_equal [:UALPHA], @to.list_type
    assert_equal [1],       @to.list_width
  end

  def accept_paragraph
    assert_equal "hi\n", @to.res.join
  end

  def accept_rule
    assert_equal '-' * 78, @to.res.join
  end

  def accept_verbatim
    assert_equal "  hi\n  world\n", @to.res.join
  end

  def end_accepting
    assert_equal 'hi', @to.end_accepting
  end

  def start_accepting
    assert_equal 0, @to.indent
    assert_empty @to.res
    assert_empty @to.list_index
    assert_empty @to.list_type
    assert_empty @to.list_width
  end

  def test_accept_heading_1
    @to.start_accepting
    @to.accept_heading @am, @RMP::Heading.new(1, 'Hello')

    assert_equal "\033[1;32mHello\033[m\n", @to.end_accepting
  end

  def test_accept_heading_2
    @to.start_accepting
    @to.accept_heading @am, @RMP::Heading.new(2, 'Hello')

    assert_equal "\033[4;32mHello\033[m\n", @to.end_accepting
  end

  def test_accept_heading_3
    @to.start_accepting
    @to.accept_heading @am, @RMP::Heading.new(3, 'Hello')

    assert_equal "\033[32mHello\033[m\n", @to.end_accepting
  end

  def test_accept_heading_4
    @to.start_accepting
    @to.accept_heading @am, @RMP::Heading.new(4, 'Hello')

    assert_equal "Hello\n", @to.end_accepting
  end

  def test_accept_heading_indent
    @to.start_accepting
    @to.indent = 3
    @to.accept_heading @am, @RMP::Heading.new(1, 'Hello')

    assert_equal "   \033[1;32mHello\033[m\n", @to.end_accepting
  end

  def test_accept_paragraph_indent
    @to.start_accepting
    @to.indent = 3
    @to.accept_paragraph @am, @RMP::Paragraph.new('words ' * 30)

    expected = <<-EXPECTED
   words words words words words words words words words words words words
   words words words words words words words words words words words words
   words words words words words words 
    EXPECTED

    assert_equal expected, @to.end_accepting
  end

  def test_accept_paragraph_wrap
    @to.start_accepting
    @to.accept_paragraph @am, @RMP::Paragraph.new('words ' * 30)

    expected = <<-EXPECTED
words words words words words words words words words words words words words
words words words words words words words words words words words words words
words words words words 
    EXPECTED

    assert_equal expected, @to.end_accepting
  end

  def test_accept_rule_indent
    @to.start_accepting
    @to.indent = 3

    @to.accept_rule @am, @RMP::Rule.new(1)

    assert_equal '   ' + '-' * 75, @to.end_accepting
  end

  def test_accept_verbatim_indent
    @to.start_accepting

    @to.indent = 3

    @to.accept_verbatim @am, @RMP::Verbatim.new('    ', 'hi', "\n",
                                                '    ', 'world', "\n")

    assert_equal "     hi\n     world\n", @to.end_accepting
  end

  def test_accept_verbatim_big_indent
    @to.start_accepting

    @to.accept_verbatim @am, @RMP::Verbatim.new('    ', 'hi', "\n",
                                                '    ', 'world', "\n")

    assert_equal "  hi\n  world\n", @to.end_accepting
  end

  def test_list_nested
    doc = @RMP::Document.new(
            @RMP::List.new(:BULLET,
              @RMP::ListItem.new(nil,
                @RMP::Paragraph.new('l1'),
                @RMP::List.new(:BULLET,
                  @RMP::ListItem.new(nil,
                    @RMP::Paragraph.new('l1.1')))),
              @RMP::ListItem.new(nil,
                @RMP::Paragraph.new('l2'))))

    output = doc.accept @am, @to

    expected = <<-EXPECTED
* l1
  * l1.1
* l2
    EXPECTED

    assert_equal expected, output
  end

end

