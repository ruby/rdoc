require 'rubygems'
require 'minitest/autorun'
require 'rdoc/options'

class TestRDocOptions < MiniTest::Unit::TestCase

  def setup
    @options = RDoc::Options.new
  end

  def test_charset_default
    assert_equal 'UTF-8', @options.charset
  end

  def test_encoding_default
    skip "Encoding not implemented" unless Object.const_defined? :Encoding

    assert_equal Encoding.default_external, @options.encoding
  end

  def test_parse_encoding
    skip "Encoding not implemented" unless Object.const_defined? :Encoding

    @options.parse %w[--encoding Big5]

    assert_equal Encoding::Big5, @options.encoding
    assert_equal 'Big5',         @options.charset
  end

  def test_parse_encoding_invalid
    skip "Encoding not implemented" unless Object.const_defined? :Encoding

    out, err = capture_io do
      @options.parse %w[--encoding invalid]
    end

    assert_match %r%^invalid options: --encoding invalid%, err
  end

  def test_parse_ignore_invalid
    out, err = capture_io do
      @options.parse %w[--ignore-invalid --bogus]
    end

    refute_match %r%^Usage: %, err
    assert_match %r%^invalid options: --bogus%, err
  end

  def test_parse_ignore_invalid_default
    out, err = capture_io do
      @options.parse %w[--bogus --main BLAH]
    end

    refute_match %r%^Usage: %, err
    assert_match %r%^invalid options: --bogus%, err

    assert_equal 'BLAH', @options.main_page
  end

  def test_parse_ignore_invalid_no
    out, err = capture_io do
      assert_raises SystemExit do
        @options.parse %w[--no-ignore-invalid --bogus]
      end
    end

    assert_match %r%^Usage: %, err
    assert_match %r%^invalid option: --bogus%, err
  end

  def test_parse_main
    out, err = capture_io do
      @options.parse %w[--main MAIN]
    end

    assert_empty out
    assert_empty err

    assert_equal 'MAIN', @options.main_page
  end

  def test_parse_dash_p
    out, err = capture_io do
      @options.parse %w[-p]
    end

    assert @options.pipe
    refute_match %r%^Usage: %, err
    refute_match %r%^invalid options%, err
  end

  def test_parse_dash_p_files
    out, err = capture_io do
      @options.parse %w[-p README]
    end

    refute @options.pipe
    refute_match %r%^Usage: %, err
    assert_match %r%^invalid options: -p .with files.%, err
  end

end

