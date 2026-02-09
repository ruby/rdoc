# frozen_string_literal: true
require_relative '../helper'

class RDocMarkupToLabelTest < RDoc::Markup::FormatterTestCase

  add_visitor_tests

  def setup
    super

    @to = RDoc::Markup::ToLabel.new
  end

  def empty
    assert_empty @to.res
  end

  def end_accepting
    assert_equal %w[hi], @to.res
  end

  alias accept_blank_line                             empty
  alias accept_block_quote                            empty
  alias accept_document                               empty
  alias accept_heading                                empty
  alias accept_heading_1                              empty
  alias accept_heading_2                              empty
  alias accept_heading_3                              empty
  alias accept_heading_4                              empty
  alias accept_heading_b                              empty
  alias accept_heading_suppressed_crossref            empty
  alias accept_list_end_bullet                        empty
  alias accept_list_end_label                         empty
  alias accept_list_end_lalpha                        empty
  alias accept_list_end_note                          empty
  alias accept_list_end_number                        empty
  alias accept_list_end_ualpha                        empty
  alias accept_list_item_end_bullet                   empty
  alias accept_list_item_end_label                    empty
  alias accept_list_item_end_lalpha                   empty
  alias accept_list_item_end_note                     empty
  alias accept_list_item_end_number                   empty
  alias accept_list_item_end_ualpha                   empty
  alias accept_list_item_start_bullet                 empty
  alias accept_list_item_start_label                  empty
  alias accept_list_item_start_lalpha                 empty
  alias accept_list_item_start_note                   empty
  alias accept_list_item_start_note_2                 empty
  alias accept_list_item_start_note_multi_description empty
  alias accept_list_item_start_note_multi_label       empty
  alias accept_list_item_start_number                 empty
  alias accept_list_item_start_ualpha                 empty
  alias accept_list_start_bullet                      empty
  alias accept_list_start_label                       empty
  alias accept_list_start_lalpha                      empty
  alias accept_list_start_note                        empty
  alias accept_list_start_number                      empty
  alias accept_list_start_ualpha                      empty
  alias accept_paragraph                              empty
  alias accept_paragraph_b                            empty
  alias accept_paragraph_br                           empty
  alias accept_paragraph_break                        empty
  alias accept_paragraph_i                            empty
  alias accept_paragraph_plus                         empty
  alias accept_paragraph_star                         empty
  alias accept_paragraph_underscore                   empty
  alias accept_raw                                    empty
  alias accept_rule                                   empty
  alias accept_verbatim                               empty
  alias list_nested                                   empty
  alias list_verbatim                                 empty
  alias start_accepting                               empty

  def test_convert_bold
    assert_equal 'bold', @to.convert('<b>bold</b>')
    assert_equal 'bold', @to.convert('*bold*')
  end

  def test_convert_crossref
    # GitHub-style: lowercase, remove non-alphanumeric except space/hyphen
    assert_equal 'someclass', @to.convert('SomeClass')
    assert_equal 'someclass', @to.convert('\\SomeClass')

    assert_equal 'somemethod', @to.convert('some_method')
    assert_equal 'somemethod', @to.convert('\\some_method')

    assert_equal 'somemethod', @to.convert('#some_method')
    assert_equal 'somemethod', @to.convert('\\#some_method')
  end

  def test_convert_em
    assert_equal 'em', @to.convert('<em>em</em>')
    assert_equal 'em', @to.convert('*em*')
  end

  def test_convert_em_dash # for HTML conversion
    assert_equal '--', @to.convert('--')
  end

  def test_convert_escape
    # GitHub-style: spaces become hyphens, special chars removed
    assert_equal 'a--b', @to.convert('a > b')
  end

  def test_convert_tidylink
    assert_equal 'text', @to.convert('{text}[stuff]')
    assert_equal 'text', @to.convert('text[stuff]')
  end

  def test_convert_tt
    assert_equal 'tt', @to.convert('<tt>tt</tt>')
  end

  def test_decode_legacy_label
    # [input, expected] pairs grouped by behavior:
    #
    # Legacy encoded characters are decoded
    [
      ["What-27s+Here",  "What's Here"],   # -27 = apostrophe
      ["Foo-3A-3ABar",   "Foo::Bar"],      # -3A = colon
      ["a-2Bb",          "a+b"],           # -2B = plus sign
      ["foo+-25W+bar",   "foo %W bar"],    # -25 = percent, + = space
      ["foo+bar",        "foo bar"],       # + = space
      ["Whats-Here",     "Whats-Here"],    # New-format labels pass through unchanged
      # -4F matches the regex (first digit 0-7) but decodes to 'O' (alphanumeric),
      # so the alphanumeric guard leaves it as literal
      ["class-4Fther",   "class-4Fther"],
      # Lowercase hex patterns are not decoded (CGI.escape only produces uppercase)
      ["a-3a-test",      "a-3a-test"],
      # -FE is outside ASCII range (0x00-0x7F), first digit must be 0-7
      ["x-FEy",          "x-FEy"],
    ].each do |input, expected|
      assert_equal expected, RDoc::Text.decode_legacy_label(input),
        "decode_legacy_label(#{input.inspect})"
    end
  end

  def test_decode_legacy_label_round_trip
    # Verify that legacy-encoded labels produce the same anchor as direct conversion
    ["What's Here", "Foo::Bar", "a + b", "Hello World"].each do |heading|
      legacy = CGI.escape(heading).gsub('%', '-').sub(/^-/, '')
      decoded = RDoc::Text.decode_legacy_label(legacy)
      assert_equal RDoc::Text.to_anchor(heading), RDoc::Text.to_anchor(decoded),
        "Round-trip failed for heading: #{heading.inspect}"
    end
  end
end
