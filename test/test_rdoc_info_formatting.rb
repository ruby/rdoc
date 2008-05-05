$LOAD_PATH << File.dirname(__FILE__) + '/../lib/'
require 'fileutils'
require 'test/unit'
require 'rdoc/generator/texinfo'
require 'yaml'

# From chapter 18 of the Pickaxe 3rd ed. and the TexInfo manual.
class TestRDocFormatting < Test::Unit::TestCase
  OUTPUT_DIR = "/tmp/rdoc-#{$$}"

  def setup
    # supress stdout
    $stdout = File.new('/dev/null','w')
    $stderr = File.new('/dev/null','w')

    RDoc::RDoc.new.document(['--fmt=texinfo',
                             File.expand_path(__FILE__),
                             "--op=#{OUTPUT_DIR}"])
    @text = File.read(OUTPUT_DIR + '/rdoc.texinfo')
  end

  def teardown
    $stdout = STDOUT
    $stderr = STDERR
    FileUtils.rm_rf OUTPUT_DIR
  end

  # Make sure tags like *this* do not make HTML
  def test_descriptions_are_not_html
    assert_no_match Regexp.new("\<b\>this\<\/b\>"), @text, "We had some HTML; icky!"
  end

  # This tests that *bold* and <b>bold me</b> become @strong{bold}
  def test_bold
    #
  end

  # Test that _italicize_ <em>italicize me</em> becomes @emph{italicize}
  def test_italics
    #
  end

  # And that +typewriter+ and <tt>typewriter</tt> becomes @code{typewriter}
  def test_tt
    #
  end

  # Check that
  #   anything indented is
  #   verbatim @verb{|foo bar baz|}
  def test_literal_code
    #
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
