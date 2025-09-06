# frozen_string_literal: true
require_relative 'helper'

class TextMarkupTest < XrefTestCase

  def test_italic
    markup = <<MARKUP

Paragraph containing _italic_word_.

>>>
  Block quote containing _italic_word_.

- List item containing _italic_word_.

= Heading containing _italic_word_.

Paragraph containing <i>italic phrase</i>.

>>>
  Block quote containing <i>italic phrase</i>.

- List item containing <i>italic phrase</i>.

= Heading containing <i>italic phrase</i>.

Paragraph containing <em>italic phrase</em>.

>>>
  Block quote containing <em>italic phrase</em>.

- List item containing <em>italic phrase</em>.

= Heading containing <em>italic phrase</em>.

MARKUP
    Helper.run_rdoc(__method__, markup) do |html_lines|
      italic_word_lines = Helper.select_lines(html_lines, '<em>italic_word</em>')
      # Check count of italic words.
      # (Five, not four, b/c the heading generates two.)
      assert_equal(5, italic_word_lines.size)
      italic_phrase_lines = Helper.select_lines(html_lines, '<em>italic phrase</em>')
      # Check count of italic phrases.
      # (Ten, not eight, b/c each heading generates two.)
      assert_equal(10, italic_phrase_lines.size)
    end
  end

  def test_bold
    markup = <<MARKUP

Paragraph containing *bold_word*.

>>>
  Block quote containing *bold_word*.

- List item containing *bold_word*.

= Heading containing *bold_word*.

Paragraph containing <tt>bold phrase</tt>.

>>>
  Block quote containing <tt>bold phrase</tt>.

- List item containing <tt>bold phrase</tt>.

= Heading containing <tt>bold phrase</tt>.

MARKUP
    Helper.run_rdoc(__method__, markup) do |html_lines|
      # Check count of bold words.
      bold_word_lines = Helper.select_lines(html_lines, '<strong>bold_word</strong>')
      # (Five, not four, b/c the heading generates two.)
      assert_equal(5, bold_word_lines.size)
      # Check count of bold phrases.
      bold_phrase_lines = Helper.select_lines(html_lines, '<strong>bold phrase</strong>')
      # (Five, not four, b/c the heading generates two.)
      assert_equal(5, bold_word_lines.size)
    end
  end

end
