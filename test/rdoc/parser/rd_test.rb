# frozen_string_literal: true
require_relative '../helper'

class RDocParserRdTest < RDoc::TestCase

  def setup
    super

    @RP = RDoc::Parser

    @tempfile = Tempfile.new self.class.name
    filename = @tempfile.path

    @file = @store.add_file filename
    @fn = filename
    @options = RDoc::Options.new
    @stats = RDoc::Stats.new @store, 0
  end

  def teardown
    super

    @tempfile.close!
  end

  def test_file
    assert_kind_of RDoc::Parser::Text, util_parser('')
  end

  def test_class_can_parse
    temp_dir do
      FileUtils.touch 'foo.rd'
      assert_equal @RP::RD, @RP.can_parse('foo.rd')

      FileUtils.touch 'foo.rd.ja'
      assert_equal @RP::RD, @RP.can_parse('foo.rd.ja')
    end
  end

  def test_scan
    parser = util_parser 'it ((*really*)) works'

    expected = doc(para('it <em>really</em> works'))
    expected.file = @file

    parser.scan

    assert_equal expected, @file.comment.parse
  end

  def util_parser(content)
    RDoc::Parser::RD.new @file, content, @options, @stats
  end

end
