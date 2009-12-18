require 'rubygems'
require 'minitest/autorun'
require 'tmpdir'
require 'rdoc/ri/driver'

class TestRDocRIDriver < MiniTest::Unit::TestCase

  def setup
    @tmpdir = File.join Dir.tmpdir, "test_rdoc_ri_driver_#{$$}"
    @home_ri = File.join @tmpdir, 'dot_ri'

    FileUtils.mkdir_p @tmpdir
    FileUtils.mkdir_p @home_ri

    @orig_ri = ENV['RI']
    @orig_home = ENV['HOME']
    ENV['HOME'] = @tmpdir
    ENV.delete 'RI'

    options = RDoc::RI::Driver.process_args []
    options[:home] = @tmpdir
    @driver = RDoc::RI::Driver.new options
  end

  def teardown
    ENV['HOME'] = @orig_home
    ENV['RI'] = @orig_ri
    FileUtils.rm_rf @tmpdir
  end

  def test_ancestors_of
    util_ancestors_store

    assert_equal %w[Object Foo], @driver.ancestors_of('Foo::Bar')
  end

  def test_complete
    store = RDoc::RI::Store.new @home_ri
    store.cache[:ancestors] = {
      'Foo'      => %w[Object],
      'Foo::Bar' => %w[Object],
    }
    store.cache[:class_methods] = {
      'Foo' => %w[bar]
    }
    store.cache[:instance_methods] = {
      'Foo' => %w[Bar]
    }
    store.cache[:modules] = %w[
      Foo
      Foo::Bar
    ]

    @driver.stores = [store]

    assert_equal %w[Foo Foo::Bar], @driver.complete('F')
    assert_equal %w[    Foo::Bar], @driver.complete('Foo::B')

    assert_equal %w[Foo#Bar],           @driver.complete('Foo#'),  'Foo#'
    assert_equal %w[Foo#Bar  Foo::bar], @driver.complete('Foo.'),  'Foo.'
    assert_equal %w[Foo::Bar Foo::bar], @driver.complete('Foo::'), 'Foo::'
  end

  def test_complete_ancestor
    util_ancestors_store

    assert_equal %w[Foo::Bar#some_method], @driver.complete('Foo::Bar#')
  end

  def test_complete_classes
    store = RDoc::RI::Store.new @home_ri
    store.cache[:ancestors] = {
      'Foo'      => %w[Object],
      'Foo::Bar' => %w[Object],
      'Foo::Baz' => %w[Object],
    }
    store.cache[:class_methods] = {
      'Foo' => %w[]
    }
    store.cache[:instance_methods] = {
      'Foo' => %w[]
    }
    store.cache[:modules] = %w[
      Foo
      Foo::Bar
      Foo::Baz
    ]

    @driver.stores = [store]

    assert_equal %w[Foo   Foo::Bar Foo::Baz], @driver.complete('F')
    assert_equal %w[Foo:: Foo::Bar Foo::Baz], @driver.complete('Foo::')
    assert_equal %w[      Foo::Bar Foo::Baz], @driver.complete('Foo::B')
  end

  def test_complete_multistore
    store1 = RDoc::RI::Store.new @home_ri
    store1.cache[:ancestors]        = { 'Foo::Bar' => %w[Foo] }
    store1.cache[:class_methods]    = {}
    store1.cache[:instance_methods] = {}
    store1.cache[:modules]          = %w[Foo::Bar]

    store2 = RDoc::RI::Store.new @home_ri
    store2.cache[:ancestors]        = { 'Foo' => %w[Object] }
    store2.cache[:class_methods]    = {}
    store2.cache[:instance_methods] = {
      'Foo' => %w[baz]
    }
    store2.cache[:modules]          = %w[Foo]

    @driver.stores = [store1, store2]

    assert_equal %w[Foo   Foo::Bar], @driver.complete('F')
  end

  def test_parse_name_single_class
    klass, type, meth = @driver.parse_name 'Foo'

    assert_equal 'Foo', klass, 'Foo class'
    assert_equal nil,   type,  'Foo type'
    assert_equal nil,   meth,  'Foo method'

    klass, type, meth = @driver.parse_name 'Foo#'

    assert_equal 'Foo', klass, 'Foo# class'
    assert_equal '#',   type,  'Foo# type'
    assert_equal nil,   meth,  'Foo# method'

    klass, type, meth = @driver.parse_name 'Foo::'

    assert_equal 'Foo', klass, 'Foo:: class'
    assert_equal '::',  type,  'Foo:: type'
    assert_equal nil,   meth,  'Foo:: method'

    klass, type, meth = @driver.parse_name 'Foo.'

    assert_equal 'Foo', klass, 'Foo. class'
    assert_equal '.',   type,  'Foo. type'
    assert_equal nil,   meth,  'Foo. method'

    klass, type, meth = @driver.parse_name 'Foo#Bar'

    assert_equal 'Foo', klass, 'Foo#Bar class'
    assert_equal '#',   type,  'Foo#Bar type'
    assert_equal 'Bar', meth,  'Foo#Bar method'

    klass, type, meth = @driver.parse_name 'Foo.Bar'

    assert_equal 'Foo', klass, 'Foo.Bar class'
    assert_equal '.',   type,  'Foo.Bar type'
    assert_equal 'Bar', meth,  'Foo.Bar method'

    klass, type, meth = @driver.parse_name 'Foo::bar'

    assert_equal 'Foo', klass, 'Foo::bar class'
    assert_equal '::',  type,  'Foo::bar type'
    assert_equal 'bar', meth,  'Foo::bar method'
  end

  def test_parse_name_namespace
    klass, type, meth = @driver.parse_name 'Foo::Bar'

    assert_equal 'Foo::Bar', klass, 'Foo::Bar class'
    assert_equal nil,        type,  'Foo::Bar type'
    assert_equal nil,        meth,  'Foo::Bar method'

    klass, type, meth = @driver.parse_name 'Foo::Bar#'

    assert_equal 'Foo::Bar', klass, 'Foo::Bar# class'
    assert_equal '#',        type,  'Foo::Bar# type'
    assert_equal nil,        meth,  'Foo::Bar# method'

    klass, type, meth = @driver.parse_name 'Foo::Bar#baz'

    assert_equal 'Foo::Bar', klass, 'Foo::Bar#baz class'
    assert_equal '#',        type,  'Foo::Bar#baz type'
    assert_equal 'baz',      meth,  'Foo::Bar#baz method'
  end

  def util_ancestors_store
    store = RDoc::RI::Store.new @home_ri
    store.cache[:ancestors] = {
      'Foo'      => %w[Object],
      'Foo::Bar' => %w[Foo],
    }
    store.cache[:class_methods] = {
      'Foo' => %w[]
    }
    store.cache[:instance_methods] = {
      'Foo' => %w[some_method]
    }
    store.cache[:modules] = %w[
      Foo
      Foo::Bar
    ]

    @driver.stores = [store]
  end

end

