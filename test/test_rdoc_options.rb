require 'rubygems'
require 'minitest/autorun'
require 'rdoc/options'

class TestRDocOptions < MiniTest::Unit::TestCase

  def setup
    @options = RDoc::Options.new
  end

  def test_dry_run_default
    refute @options.dry_run
  end

  def test_encoding_default
    skip "Encoding not implemented" unless Object.const_defined? :Encoding

    assert_equal Encoding.default_external, @options.encoding
  end

  def test_parse_dry_run
    @options.parse %w[--dry-run]

    assert @options.dry_run
  end

  def test_parse_default_darkfish
    @options.parse []

    assert_equal RDoc::Generator::Darkfish, @options.generator

    op = @options.option_parser

    assert_includes op.top.long.keys, 'charset'
    assert_includes op.top.long.keys, 'main'
    assert_includes op.top.long.keys, 'show-hash'
    assert_includes op.top.long.keys, 'tab-width'
    assert_includes op.top.long.keys, 'template'
    assert_includes op.top.long.keys, 'title'
    assert_includes op.top.long.keys, 'webcvs'
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

    assert_empty out
  end

  def test_parse_formatter
    e = assert_raises OptionParser::InvalidOption do
      @options.parse %w[--format darkfish --format ri]
    end

    assert_equal 'invalid option: --format generator already set to darkfish',
                 e.message
  end

  def test_parse_formatter_ri
    e = assert_raises OptionParser::InvalidOption do
      @options.parse %w[--format darkfish --ri]
    end

    assert_equal 'invalid option: --ri generator already set to darkfish',
                 e.message

    @options = RDoc::Options.new

    e = assert_raises OptionParser::InvalidOption do
      @options.parse %w[--format darkfish -r]
    end

    assert_equal 'invalid option: -r generator already set to darkfish',
                 e.message
  end

  def test_parse_formatter_ri_site
    e = assert_raises OptionParser::InvalidOption do
      @options.parse %w[--format darkfish --ri-site]
    end

    assert_equal 'invalid option: --ri-site generator already set to darkfish',
                 e.message

    @options = RDoc::Options.new

    e = assert_raises OptionParser::InvalidOption do
      @options.parse %w[--format darkfish -R]
    end

    assert_equal 'invalid option: -R generator already set to darkfish',
                 e.message
  end

  def test_parse_help
    out, err = capture_io do
      begin
        @options.parse %w[--help]
      rescue SystemExit
      end
    end

    assert_equal 1, out.scan(/Darkfish generator options:/).length
    assert_equal 1, out.scan(/ri generator options:/).      length
  end

  def test_parse_ignore_invalid
    out, err = capture_io do
      @options.parse %w[--ignore-invalid --bogus]
    end

    refute_match %r%^Usage: %, err
    assert_match %r%^invalid options: --bogus%, err

    assert_empty out
  end

  def test_parse_ignore_invalid_default
    out, err = capture_io do
      @options.parse %w[--bogus --main BLAH]
    end

    refute_match %r%^Usage: %, err
    assert_match %r%^invalid options: --bogus%, err

    assert_equal 'BLAH', @options.main_page

    assert_empty out
  end

  def test_parse_ignore_invalid_no
    out, err = capture_io do
      assert_raises SystemExit do
        @options.parse %w[--no-ignore-invalid --bogus=arg --bobogus --visibility=extended]
      end
    end

    assert_match %r%^Usage: %, err
    assert_match %r%^invalid options: --bogus=arg, --bobogus, --visibility=extended%, err

    assert_empty out
  end

  def test_parse_deprecated
    dep_hash = RDoc::Options::DEPRECATED
    options = dep_hash.keys.sort

    out, err = capture_io do
      @options.parse options
    end

    dep_hash.each_pair do |opt, message|
      assert_match %r%.*#{opt}.+#{message}%, err
    end

    assert_empty out
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

    assert_empty out
  end

  def test_parse_dash_p_files
    out, err = capture_io do
      @options.parse ['-p', File.expand_path(__FILE__)]
    end

    refute @options.pipe
    refute_match %r%^Usage: %, err
    assert_match %r%^invalid options: -p .with files.%, err

    assert_empty out
  end

end

