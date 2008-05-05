$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib/'
require 'fileutils'
require 'test/unit'
require 'rdoc/generator/texinfo'
require 'yaml'

# From chapter 18 of the Pickaxe 3rd ed. and the TexInfo manual.
class TestRdocInfoFormatting < Test::Unit::TestCase
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

  # Ensure we get a reasonable amount
  #
  # of space in between paragraphs.
  def test_paragraphs_are_spaced
  end
  
  # This tests that *bold* and <b>bold me</b> become @strong{bolded}
  def test_bold
    assert_match /@strong\{bold\}/, @text
    assert_match /@strong\{bold me\}/, @text
  end

  # Test that _italics_ <em>italicize me</em> becomes @emph{italicized}
  def test_italics
    assert_match /@emph\{italics\}/, @text
    assert_match /@emph\{italicize me\}/, @text
  end

  # And that typewriter +text+ and <tt>typewriter me</tt> becomes @code{typewriter}
  def test_tt
    assert_match /@code\{text\}/, @text
    assert_match /@code\{typewriter me\}/, @text
  end

  # Check that
  #   anything indented is
  #   verbatim @verb{|foo bar baz|}
  def test_literal_code
    assert_match "@verb{|  anything indented is
  verbatim \\@verb\\{|foo bar baz|\\}
|}", @text
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

  private

  # We don't want the whole string inspected if we pass our own
  # message in.
  def assert_match(regex, string, message = "Didn't find #{regex} in #{string}.")
    assert string.match(regex), message
  end
end
