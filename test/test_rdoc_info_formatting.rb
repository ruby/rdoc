require 'test/unit'

# From chapter 18 of the Pickaxe 3rd ed. and the TexInfo manual.
class TestRDocFormatting < Test::Unit::TestCase

#   def test_descriptions_are_not_html
#     assert_no_match /\<.*\>/, OUTPUT, "We had some HTML; icky!"
#   end

  def test_bold
    # *bold* and <b>bold me</b>
    # @strong{bold}
  end

  def test_italics
    # _italicize_ <em>italicize me</em>
    # @emph{italicize}
  end

  def test_tt
    # +typewriter+ and <tt>typewriter</tt>
    # @code{typewriter}
  end

  def test_literal_code
    # anything indented is verbatim
    # @verb{|foo bar baz|}
  end

  def test_internal_hyperlinks
    # be sure to test multi-word hyperlinks as well.
  end

  def test_hyperlink_targets
  end

  def test_web_links
    # An example of the two-argument form: The official
    # @uref{ftp://ftp.gnu.org/gnu, GNU ftp site} holds programs and texts.

    # produces:
    #      The official GNU ftp site (ftp://ftp.gnu.org/gnu)
    #      holds programs and texts.
    # and the HTML output is this:
    #      The official <a href="ftp://ftp.gnu.org/gnu">GNU ftp site</a>
    #      holds programs and texts.
  end

  def test_bullet_lists
    # test both - and *
  end

  def test_numbered_lists
  end

  def test_alpha_lists
  end

  def test_labelled_lists
  end

  def test_headings
    # levels 1 - 6?
  end

  def test_horizontal_rule
    # three or more hyphens
  end
end
