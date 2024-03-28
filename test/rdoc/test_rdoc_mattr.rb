# frozen_string_literal: true
require_relative 'helper'

class TestRDocMattr < RDoc::TestCase

  def setup
    super

    @a = RDoc::Mattr.new nil, 'mattr_accessor', 'RW', ''
  end

  def test_aref
    m = RDoc::Mattr.new nil, 'mattr_accessor', 'RW', nil

    assert_equal 'mattr-i-mattr_accessor', m.aref
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
    assert_equal 'mattr_accessor', @a.definition

    @a.rw = 'R'

    assert_equal 'mattr_reader', @a.definition

    @a.rw = 'W'

    assert_equal 'mattr_writer', @a.definition
  end

  def test_full_name
    assert_equal '(unknown)#mattr_accessor', @a.full_name
  end

  def test_marshal_dump
    tl = @store.add_file 'file.rb'

    @a.comment = 'this is a comment'
    @a.record_location tl

    cm = tl.add_class RDoc::NormalClass, 'Klass'
    cm.add_mattr @a

    section = cm.sections.first

    loaded = Marshal.load Marshal.dump @a
    loaded.store = @store

    assert_equal @a, loaded

    comment = RDoc::Markup::Document.new(
                RDoc::Markup::Paragraph.new('this is a comment'))

    assert_equal comment,          loaded.comment
    assert_equal 'file.rb',        loaded.file.relative_name
    assert_equal 'Klass#mattr_accessor',     loaded.full_name
    assert_equal 'mattr_accessor', loaded.name
    assert_equal 'RW',             loaded.rw
    assert_equal false,            loaded.singleton
    assert_equal :public,          loaded.visibility
    assert_equal tl,               loaded.file
    assert_equal cm,               loaded.parent
    assert_equal section,          loaded.section
  end

  def test_marshal_dump_singleton
    tl = @store.add_file 'file.rb'

    @a.comment = 'this is a comment'
    @a.record_location tl

    cm = tl.add_class RDoc::NormalClass, 'Klass'
    cm.add_mattr @a

    section = cm.sections.first

    @a.rw = 'R'
    @a.singleton = true
    @a.visibility = :protected

    loaded = Marshal.load Marshal.dump @a
    loaded.store = @store

    assert_equal @a, loaded

    comment = RDoc::Markup::Document.new(
                RDoc::Markup::Paragraph.new('this is a comment'))

    assert_equal comment,                 loaded.comment
    assert_equal 'Klass::mattr_accessor', loaded.full_name
    assert_equal 'mattr_accessor',        loaded.name
    assert_equal 'R',                     loaded.rw
    assert_equal true,                    loaded.singleton
    assert_equal :protected,              loaded.visibility
    assert_equal tl,                      loaded.file
    assert_equal cm,                      loaded.parent
    assert_equal section,                 loaded.section
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
