require 'rubygems'
require 'minitest/unit'
require 'test/xref_test_case'

class TestRDocContext < XrefTestCase

  def setup
    super

    @c1    = RDoc::TopLevel.classes_hash['C1']
    @c2    = RDoc::TopLevel.classes_hash['C2']
    @c2_c3 = @c2.classes_hash['C3']
    @c3    = RDoc::TopLevel.classes_hash['C3']
  end

  def test_classes
    assert_equal %w[C2::C3], @c2.classes.map { |k| k.full_name }
    assert_equal %w[C3::H1 C3::H2], @c3.classes.map { |k| k.full_name }
  end

  def test_equals2
    assert_equal @c3,    @c3
    refute_equal @c2,    @c3
    refute_equal @c2_c3, @c3
  end

  def test_find_attribute_named
    assert_equal nil,  @c1.find_attribute_named('none')
    assert_equal 'R',  @c1.find_attribute_named('attr').rw
    assert_equal 'R',  @c1.find_attribute_named('attr_reader').rw
    assert_equal 'W',  @c1.find_attribute_named('attr_writer').rw
    assert_equal 'RW', @c1.find_attribute_named('attr_accessor').rw
  end

  def test_find_constant_named
    assert_equal nil,      @c1.find_constant_named('NONE')
    assert_equal ':const', @c1.find_constant_named('CONST').value
  end

  def test_find_enclosing_module_named
    assert_equal nil, @c2_c3.find_enclosing_module_named('NONE')
    assert_equal @c1, @c2_c3.find_enclosing_module_named('C1')
    assert_equal @c2, @c2_c3.find_enclosing_module_named('C2')
  end

  def test_find_file_named
    assert_equal nil,        @c1.find_file_named('nonexistent.rb')
    assert_equal @top_level, @c1.find_file_named(@file_name)
  end

  def test_find_instance_method_named
    assert_equal nil, @c1.find_instance_method_named('none')

    m = @c1.find_instance_method_named('m')
    assert_instance_of RDoc::AnyMethod, m
    assert_equal false, m.singleton
  end

  def test_find_local_symbol
    assert_equal true,       @c1.find_local_symbol('m').singleton
    assert_equal ':const',   @c1.find_local_symbol('CONST').value
    assert_equal 'R',        @c1.find_local_symbol('attr').rw
    assert_equal @top_level, @c1.find_local_symbol(@file_name)
    assert_equal @c2_c3,     @c2.find_local_symbol('C3')
  end

  def test_find_method_named
    assert_equal true, @c1.find_method_named('m').singleton
  end

  def test_find_module_named
    assert_equal @c2_c3, @c2.find_module_named('C3')
    assert_equal @c2,    @c2.find_module_named('C2')
    assert_equal @c1,    @c2.find_module_named('C1')

    assert_equal 'C2::C3', @c2.find_module_named('C3').full_name
  end

  def test_find_symbol
    c3 = @top_level.find_module_named('C3')
    assert_equal c3,     @top_level.find_symbol('C3')
    assert_equal c3,     @c2.find_symbol('::C3')
    assert_equal @c2_c3, @c2.find_symbol('C3')
  end

  def test_spaceship
    assert_equal(-1, @c2.<=>(@c3))
    assert_equal 0,  @c2.<=>(@c2)
    assert_equal 1,  @c3.<=>(@c2)

    assert_equal 1,  @c2_c3.<=>(@c2)
    assert_equal(-1, @c2_c3.<=>(@c3))
  end

end

MiniTest::Unit.autorun

