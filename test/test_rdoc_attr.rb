require 'rubygems'
require 'minitest/autorun'
require 'rdoc/rdoc'

class TestRDocAttr < MiniTest::Unit::TestCase

  def setup
    @a = RDoc::Attr.new nil, 'attr', 'RW', ''
  end

  def test_aref
    m = RDoc::Attr.new nil, 'attr', 'RW', nil

    assert_equal 'attribute-i-attr', m.aref
  end

  def test_arglists
    assert_nil @a.arglists
  end

  def test_block_params
    assert_nil @a.block_params
  end

  def test_call_seq
    assert_nil @a.call_seq
  end

  def test_definition
    assert_equal 'attr_accessor', @a.definition

    @a.rw = 'R'

    assert_equal 'attr_reader', @a.definition

    @a.rw = 'W'

    assert_equal 'attr_writer', @a.definition
  end

  def test_full_name
    assert_equal '(unknown)#attr', @a.full_name
  end

  def test_marshal_dump
    @a.comment = 'this is a comment'
    cm = RDoc::ClassModule.new 'Klass'
    cm.add_attribute @a

    loaded = Marshal.load Marshal.dump @a

    assert_equal @a, loaded

    comment = RDoc::Markup::Document.new(
                RDoc::Markup::Paragraph.new('this is a comment'))

    assert_equal comment,      loaded.comment
    assert_equal 'Klass#attr', loaded.full_name
    assert_equal 'attr',       loaded.name
    assert_equal 'RW',         loaded.rw
    assert_equal false,        loaded.singleton
    assert_equal :public,      loaded.visibility

    @a.rw = 'R'
    @a.singleton = true
    @a.visibility = :protected

    loaded = Marshal.load Marshal.dump @a

    assert_equal @a, loaded

    assert_equal comment,       loaded.comment
    assert_equal 'Klass::attr', loaded.full_name
    assert_equal 'attr',        loaded.name
    assert_equal 'R',           loaded.rw
    assert_equal true,          loaded.singleton
    assert_equal :protected,    loaded.visibility
  end

  def test_params
    assert_nil @a.params
  end

  def test_singleton
    refute @a.singleton
  end

  def test_type
    assert_equal 'instance', @a.type

    @a.singleton = true
    assert_equal 'class', @a.type
  end

end

