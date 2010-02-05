require 'rubygems'
require 'minitest/autorun'
require 'rdoc/options'

class TestRDocOptions < MiniTest::Unit::TestCase

  def setup
    @options = RDoc::Options.new
  end

  def test_parse_bogus
    out, err = capture_io do
      assert_raises SystemExit do
        @options.parse %w[--bogus]
      end
    end

    assert_match %r%^Usage: %, err
    assert_match %r%^invalid option: --bogus%, err
  end

  def test_parse_ignore_invalid
    out, err = capture_io do
      @options.parse %w[--ignore-invalid --bogus]
    end

    refute_match %r%^Usage: %, err
    assert_match %r%^invalid option: --bogus%, err
  end

end

