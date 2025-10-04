# frozen_string_literal: true
require_relative '../lib/integration_test_case'

class TextMarkupTest < IntegrationTestCase

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
    run_rdoc(markup) do |html_lines|
      italic_word_lines = select_lines(html_lines, '<em>italic_word</em>')
      # Check count of italic words.
      # (Five, not four, b/c the heading generates two.)
      assert_equal(5, italic_word_lines.size)
      italic_phrase_lines = select_lines(html_lines, '<em>italic phrase</em>')
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

Paragraph containing <b>bold phrase</b>.

>>>
  Block quote containing <b>bold phrase</b>.

- List item containing <b>bold phrase</b>.

= Heading containing <b>bold phrase</b>.

MARKUP
    run_rdoc(markup) do |html_lines|
      # Check count of bold words.
      bold_word_lines = select_lines(html_lines, '<strong>bold_word</strong>')
      # (Five, not four, b/c the heading generates two.)
      assert_equal(5, bold_word_lines.size)
      # Check count of bold phrases.
      bold_phrase_lines = select_lines(html_lines, '<strong>bold phrase</strong>')
      # (Five, not four, b/c the heading generates two.)
      assert_equal(5, bold_phrase_lines.size)
    end
  end

  def test_monofont
    markup = <<MARKUP

Paragraph containing +monofont_word+.

>>>
  Block quote containing +monofont_word+.

- List item containing +monofont_word+.

= Heading containing +monofont_word+.

Paragraph containing <tt>monofont phrase</tt>.

>>>
  Block quote containing <tt>monofont phrase</tt>.

- List item containing <tt>monofont phrase</tt>.

= Heading containing <tt>monofont phrase</tt>.

Paragraph containing <code>monofont phrase</code>.

>>>
  Block quote containing <code>monofont phrase</code>.

- List item containing <code>monofont phrase</code>.

= Heading containing <code>monofont phrase</code>.

MARKUP
    run_rdoc(markup) do |html_lines|
      monofont_word_lines = select_lines(html_lines, '<code>monofont_word</code>')
      # Check count of monofont words.
      # (Five, not four, b/c the heading generates two.)
      assert_equal(5, monofont_word_lines.size)
      monofont_phrase_lines = select_lines(html_lines, '<code>monofont phrase</code>')
      # Check count of monofont phrases.
      # (Ten, not eight, b/c each heading generates two.)
      assert_equal(10, monofont_phrase_lines.size)
    end
  end

  def test_character_conversions
    convertible_characters = %w[(c) (r) ... -- --- 'foo' "bar"].join(' ')

    markup = <<MARKUP

Paragraph containing #{convertible_characters}.

>>>
  Block quote containing #{convertible_characters}.

- List item containing #{convertible_characters}.

= Heading containing #{convertible_characters}.

MARKUP
    run_rdoc(markup) do |html_lines|
      converted_character_lines = select_lines(html_lines, '© ® … – — ‘foo’ “bar”')
      # Check count of converted character lines.
      # (The generated heading line contains escapes, and so does not match.)
      assert_equal(4, converted_character_lines.size)
    end
  end

end
