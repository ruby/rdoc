# frozen_string_literal: true
require_relative '../helper'

class RDocMarkupTest < RDoc::TestCase

  def test_class_parse
    expected = @RM::Document.new(
      @RM::Paragraph.new('hello'))

    assert_equal expected, RDoc::Markup.parse('hello')
  end

  def test_convert
    str = <<-STR
now is
the time

  hello
  dave

1. l1
2. l2
    STR

    m = RDoc::Markup.new

    tt = RDoc::Markup::ToTest.new nil

    out = m.convert str, tt

    expected = [
      "now is the time",
      "\n",
      "  hello\n  dave\n",
      "1: ",
      "l1",
      "1: ",
      "l2",
    ]

    assert_equal expected, out
  end

  def test_convert_document
    doc = RDoc::Markup::Parser.parse <<-STR
now is
the time

  hello
  dave

1. l1
2. l2
    STR

    m = RDoc::Markup.new

    tt = RDoc::Markup::ToTest.new nil

    out = m.convert doc, tt

    expected = [
      "now is the time",
      "\n",
      "  hello\n  dave\n",
      "1: ",
      "l1",
      "1: ",
      "l2",
    ]

    assert_equal expected, out
  end

end
