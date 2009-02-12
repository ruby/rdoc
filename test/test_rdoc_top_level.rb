require 'rubygems'
require 'minitest/unit'
require 'test/xref_test_case'

class TestRDocTopLevel < XrefTestCase

  def setup
    super

    @c1 = @top_level.classes_hash['C1']
    @c4 = @top_level.classes_hash['C4']
  end

  def test_find_class_or_module_named
    assert_equal @c1, @top_level.find_class_or_module_named('C1')
    assert_equal @c4, @top_level.find_class_or_module_named('C4')
  end

end

MiniTest::Unit.autorun

