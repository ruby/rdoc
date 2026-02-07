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

  def test_decode_legacy_label_apostrophe
    assert_equal "What's Here", RDoc::Text.decode_legacy_label("What-27s+Here")
  end

  def test_decode_legacy_label_colon
    assert_equal "Foo::Bar", RDoc::Text.decode_legacy_label("Foo-3A-3ABar")
  end

  def test_decode_legacy_label_new_format_passthrough
    assert_equal "Whats-Here", RDoc::Text.decode_legacy_label("Whats-Here")
  end

  def test_decode_legacy_label_alphanumeric_hex_unchanged
    # -4F decodes to 'O' (alphanumeric), so leave as literal
    assert_equal "class-4Fther", RDoc::Text.decode_legacy_label("class-4Fther")
  end

  def test_decode_legacy_label_plus_to_space
    assert_equal "foo bar", RDoc::Text.decode_legacy_label("foo+bar")
  end

  def test_decode_legacy_label_encoded_plus
    # -2B is '+' which is not alphanumeric, so it decodes
    assert_equal "a+b", RDoc::Text.decode_legacy_label("a-2Bb")
  end

  def test_decode_legacy_label_percent
    # -25 is '%' which is not alphanumeric
    assert_equal "%w and %W", RDoc::Text.decode_legacy_label("-25w+and+-25W")
  end

  def test_decode_legacy_label_lowercase_hex_passthrough
    # New-format anchors use lowercase; CGI.escape only produces uppercase hex.
    # Lowercase hex-like patterns must not be decoded.
    assert_equal "a-3a-test", RDoc::Text.decode_legacy_label("a-3a-test")
  end

end
