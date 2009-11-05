require 'rubygems'
require 'rdoc/markup/formatter_test_case'
require 'rdoc/markup/to_flow'
require 'minitest/autorun'

class TestRDocMarkupToFlow < RDoc::Markup::FormatterTestCase

  add_visitor_tests

  def setup
    super

    @to = RDoc::Markup::ToFlow.new
    @F = RDoc::Markup::Flow
  end

  def accept_blank_line
    assert_empty @to.res
  end

  def accept_heading
    expected = [
      @F::H.new(5, 'Hello')
    ]

    assert_equal expected, @to.res
  end

  def accept_list_end_bullet
    assert_nil @to.res
  end

  def accept_list_end_label
    assert_nil @to.res
  end

  def accept_list_end_lalpha
    assert_nil @to.res
  end

  def accept_list_end_number
    assert_nil @to.res
  end

  def accept_list_end_note
    assert_nil @to.res
  end

  def accept_list_end_ualpha
    assert_nil @to.res
  end

  def accept_list_item_end_bullet
    expected = [
      @F::LIST.new('*')
    ]

    assert_equal expected, @to.res
  end

  def accept_list_item_end_label
    expected = [
      @F::LIST.new('label')
    ]

    assert_equal expected, @to.res
  end

  def accept_list_item_end_lalpha
    expected = [
      @F::LIST.new('a')
    ]

    assert_equal expected, @to.res
  end

  def accept_list_item_end_note
    expected = [
      @F::LIST.new('note')
    ]

    assert_equal expected, @to.res
  end

  def accept_list_item_end_number
    expected = [
      @F::LIST.new('1')
    ]

    assert_equal expected, @to.res
  end

  def accept_list_item_end_ualpha
    expected = [
      @F::LIST.new('A')
    ]

    assert_equal expected, @to.res
  end

  def accept_list_item_start_bullet
    expected = [
      [@F::LIST.new('*', *[
         @F::LI.new(nil)])],
      @F::LIST.new('*', *[
        @F::LI.new(nil)])
    ]

    assert_equal expected, @to.list_stack

    assert_equal @F::LI.new(nil), @to.res
  end

  def accept_list_item_start_label
    expected = [
      [@F::LIST.new('label', *[
         @F::LI.new('cat')])],
      @F::LIST.new('label', *[
        @F::LI.new('cat')])
    ]

    assert_equal expected, @to.list_stack

    assert_equal @F::LI.new('cat'), @to.res
  end

  def accept_list_item_start_lalpha
    expected = [
      [@F::LIST.new('a', *[
         @F::LI.new(nil)])],
      @F::LIST.new('a', *[
        @F::LI.new(nil)])
    ]

    assert_equal expected, @to.list_stack

    assert_equal @F::LI.new(nil), @to.res
  end

  def accept_list_item_start_note
    expected = [
      [@F::LIST.new('note', *[
         @F::LI.new('cat')])],
      @F::LIST.new('note', *[
        @F::LI.new('cat')])
    ]

    assert_equal expected, @to.list_stack

    assert_equal @F::LI.new('cat'), @to.res
  end

  def accept_list_item_start_number
    expected = [
      [@F::LIST.new('1', *[
         @F::LI.new(nil)])],
      @F::LIST.new('1', *[
        @F::LI.new(nil)])
    ]

    assert_equal expected, @to.list_stack

    assert_equal @F::LI.new(nil), @to.res
  end

  def accept_list_item_start_ualpha
    expected = [
      [@F::LIST.new('A', *[
         @F::LI.new(nil)])],
      @F::LIST.new('A', *[
        @F::LI.new(nil)])
    ]

    assert_equal expected, @to.list_stack

    assert_equal @F::LI.new(nil), @to.res
  end

  def accept_list_start_bullet
    expected = [
      [@F::LIST.new('*')]
    ]

    assert_equal expected, @to.list_stack

    assert_equal @F::LIST.new('*'), @to.res
  end

  def accept_list_start_label
    expected = [
      [@F::LIST.new('label')]
    ]

    assert_equal expected, @to.list_stack

    assert_equal @F::LIST.new('label'), @to.res
  end

  def accept_list_start_lalpha
    expected = [
      [@F::LIST.new('a')]
    ]

    assert_equal expected, @to.list_stack

    assert_equal @F::LIST.new('a'), @to.res
  end

  def accept_list_start_note
    expected = [
      [@F::LIST.new('note')]
    ]

    assert_equal expected, @to.list_stack

    assert_equal @F::LIST.new('note'), @to.res
  end

  def accept_list_start_number
    expected = [
      [@F::LIST.new('1')]
    ]

    assert_equal expected, @to.list_stack

    assert_equal @F::LIST.new('1'), @to.res
  end

  def accept_list_start_ualpha
    expected = [
      [@F::LIST.new('A')]
    ]

    assert_equal expected, @to.list_stack

    assert_equal @F::LIST.new('A'), @to.res
  end

  def accept_paragraph
    expected = [
      @F::P.new('hi')
    ]

    assert_equal expected, @to.res
  end

  def accept_rule
    expected = [
      @F::RULE.new(4)
    ]

    assert_equal expected, @to.res
  end

  def accept_verbatim
    expected = [
      @F::VERB.new("  hi\n  world\n")
    ]

    assert_equal expected, @to.res
  end

  def end_accepting
    assert_equal %w[hi], @to.end_accepting
  end

  def start_accepting
    assert_equal [], @to.res
    assert_equal [], @to.list_stack
  end

end

