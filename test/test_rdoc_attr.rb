require 'rubygems'
require 'minitest/autorun'
require 'rdoc/rdoc'

class TestRDocAttr < MiniTest::Unit::TestCase

  def test_type
    attr = RDoc::Attr.new nil, 'attr', 'RW', ''

    assert_equal 'attr_accessor', attr.type

    attr.rw = 'R'

    assert_equal 'attr_reader', attr.type

    attr.rw = 'W'

    assert_equal 'attr_writer', attr.type
  end

end

