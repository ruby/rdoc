require 'pp'
require 'rubygems'
require 'minitest/autorun'
require 'rdoc/markup'
require 'tmpdir'

class TestRDocMarkupInclude < MiniTest::Unit::TestCase

  def setup
    @RM = RDoc::Markup
    @include = @RM::Include.new 'file', [Dir.tmpdir]
  end

  def test_equals2
    assert_equal @include, @RM::Include.new('file', [Dir.tmpdir])
    refute_equal @include, @RM::Include.new('file', %w[.])
    refute_equal @include, @RM::Include.new('other', [Dir.tmpdir])
    refute_equal @include, Object.new
  end

end

