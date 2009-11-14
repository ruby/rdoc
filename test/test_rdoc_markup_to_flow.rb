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
    assert_equal [@F::LIST.new(:BULLET)], @to.res

    assert_empty @to.list_stack
  end

  def accept_list_end_label
    assert_equal [@F::LIST.new(:LABEL)], @to.res

    assert_empty @to.list_stack
  end

  def accept_list_end_lalpha
    assert_equal [@F::LIST.new(:LALPHA)], @to.res

    assert_empty @to.list_stack
  end

  def accept_list_end_number
    assert_equal [@F::LIST.new(:NUMBER)], @to.res

    assert_empty @to.list_stack
  end

  def accept_list_end_note
    assert_equal [@F::LIST.new(:NOTE)], @to.res

    assert_empty @to.list_stack
  end

  def accept_list_end_ualpha
    assert_equal [@F::LIST.new(:UALPHA)], @to.res

    assert_empty @to.list_stack
  end

  def accept_list_item_end_bullet
    expected = @F::LIST.new(:BULLET, @F::LI.new(nil))

    assert_equal expected, @to.res
  end

  def accept_list_item_end_label
    expected = @F::LIST.new(:LABEL, @F::LI.new('cat'))

    assert_equal expected, @to.res
  end

  def accept_list_item_end_lalpha
    expected = @F::LIST.new(:LALPHA, @F::LI.new(nil))

    assert_equal expected, @to.res
  end

  def accept_list_item_end_note
    expected = @F::LIST.new(:NOTE, @F::LI.new('cat'))

    assert_equal expected, @to.res
  end

  def accept_list_item_end_number
    expected = @F::LIST.new(:NUMBER, @F::LI.new(nil))

    assert_equal expected, @to.res
  end

  def accept_list_item_end_ualpha
    expected = @F::LIST.new(:UALPHA, @F::LI.new(nil))

    assert_equal expected, @to.res
  end

  def accept_list_item_start_bullet
    expected = [
      [@F::LIST.new(:BULLET, *[
         @F::LI.new(nil)])],
      @F::LIST.new(:BULLET, *[
        @F::LI.new(nil)])
    ]

    assert_equal expected, @to.list_stack

    assert_equal @F::LI.new(nil), @to.res
  end

  def accept_list_item_start_label
    expected = [
      [@F::LIST.new(:LABEL, *[
         @F::LI.new('cat')])],
      @F::LIST.new(:LABEL, *[
        @F::LI.new('cat')])
    ]

    assert_equal expected, @to.list_stack

    assert_equal @F::LI.new('cat'), @to.res
  end

  def accept_list_item_start_lalpha
    expected = [
      [@F::LIST.new(:LALPHA, *[
         @F::LI.new(nil)])],
      @F::LIST.new(:LALPHA, *[
        @F::LI.new(nil)])
    ]

    assert_equal expected, @to.list_stack

    assert_equal @F::LI.new(nil), @to.res
  end

  def accept_list_item_start_note
    expected = [
      [@F::LIST.new(:NOTE, *[
         @F::LI.new('cat')])],
      @F::LIST.new(:NOTE, *[
        @F::LI.new('cat')])
    ]

    assert_equal expected, @to.list_stack

    assert_equal @F::LI.new('cat'), @to.res
  end

  def accept_list_item_start_number
    expected = [
      [@F::LIST.new(:NUMBER, *[
         @F::LI.new(nil)])],
      @F::LIST.new(:NUMBER, *[
        @F::LI.new(nil)])
    ]

    assert_equal expected, @to.list_stack

    assert_equal @F::LI.new(nil), @to.res
  end

  def accept_list_item_start_ualpha
    expected = [
      [@F::LIST.new(:UALPHA, *[
         @F::LI.new(nil)])],
      @F::LIST.new(:UALPHA, *[
        @F::LI.new(nil)])
    ]

    assert_equal expected, @to.list_stack

    assert_equal @F::LI.new(nil), @to.res
  end

  def accept_list_start_bullet
    expected = [
      [@F::LIST.new(:BULLET)]
    ]

    assert_equal expected, @to.list_stack

    assert_equal @F::LIST.new(:BULLET), @to.res
  end

  def accept_list_start_label
    expected = [
      [@F::LIST.new(:LABEL)]
    ]

    assert_equal expected, @to.list_stack

    assert_equal @F::LIST.new(:LABEL), @to.res
  end

  def accept_list_start_lalpha
    expected = [
      [@F::LIST.new(:LALPHA)]
    ]

    assert_equal expected, @to.list_stack

    assert_equal @F::LIST.new(:LALPHA), @to.res
  end

  def accept_list_start_note
    expected = [
      [@F::LIST.new(:NOTE)]
    ]

    assert_equal expected, @to.list_stack

    assert_equal @F::LIST.new(:NOTE), @to.res
  end

  def accept_list_start_number
    expected = [
      [@F::LIST.new(:NUMBER)]
    ]

    assert_equal expected, @to.list_stack

    assert_equal @F::LIST.new(:NUMBER), @to.res
  end

  def accept_list_start_ualpha
    expected = [
      [@F::LIST.new(:UALPHA)]
    ]

    assert_equal expected, @to.list_stack

    assert_equal @F::LIST.new(:UALPHA), @to.res
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

