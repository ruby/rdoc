# frozen_string_literal: true
require_relative '../../helper'

class RDocContextMethodListTest < RDoc::TestCase

  def setup
    super

    @instance = RDoc::AnyMethod.new('m')
    @singleton = RDoc::AnyMethod.new('m', singleton: true)
    @other = RDoc::AnyMethod.new('other', singleton: true)
    @list = RDoc::Context::MethodList.new([@other, @instance, @singleton])
  end

  def test_find_named
    assert_same @instance, @list.find_named('m')
    assert_nil @list.find_named('missing')
    refute_respond_to @list, :methods_named
  end

  def test_find_named_with_predicate
    seen = []
    result = @list.find_named('m') do |method|
      seen << method
      method.singleton
    end

    assert_same @singleton, result
    assert_equal [@instance, @singleton], seen
    assert_nil @list.find_named('m') { false }
    assert_nil @list.find_named('missing') { flunk 'predicate called for a missing name' }
  end

  def test_find_named_with_mutable_names
    assert_same @instance, @list.find_named('m')
    name = +'old'
    method = RDoc::AnyMethod.new(name)
    @list << method
    assert_same method, @list.find_named('old')

    name.replace('new')
    assert_nil @list.find_named('old')
    assert_same method, @list.find_named('new')

    method.name = +'assigned'
    assert_same method, @list.find_named('assigned')
    method.name.replace('renamed')
    assert_nil @list.find_named('assigned')
    assert_same method, @list.find_named('renamed')
  end

end
