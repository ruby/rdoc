require 'rubygems'
require 'minitest/autorun'
require 'rdoc/ri'
require 'tmpdir'
require 'fileutils'

class TestRDocRIStore < MiniTest::Unit::TestCase

  def setup
    @tmpdir = File.join Dir.tmpdir, "test_rdoc_ri_store_#{$$}"
    @s = RDoc::RI::Store.new @tmpdir

    @klass = RDoc::ClassModule.new 'Object'
    @meth = RDoc::AnyMethod.new nil, 'method'
    @meth_bang = RDoc::AnyMethod.new nil, 'method!'

    @klass.add_method @meth
    @klass.add_method @meth_bang
  end

  def teardown
    FileUtils.rm_rf @tmpdir
  end

  def assert_directory path
    assert File.directory?(path), "#{path} is not a directory"
  end

  def assert_file path
    assert File.file?(path), "#{path} is not a file"
  end

  def test_klass_file
    assert_equal File.join(@tmpdir, 'Object', 'cdesc-Object.ri'),
                 @s.klass_file('Object')
  end

  def test_klass_path
    assert_equal File.join(@tmpdir, 'Object'), @s.klass_path('Object')
  end

  def test_load_class
    @s.save_class @klass

    assert_equal @klass, @s.load_class('Object')
  end

  def test_load_method_bang
    @s.save_method @klass, @meth_bang

    meth = @s.load_method('Object', '#method!')
    assert_equal @meth_bang, meth
  end

  def test_method_file
    assert_equal File.join(@tmpdir, 'Object', 'method-i.ri'),
                 @s.method_file('Object', 'Object#method')

    assert_equal File.join(@tmpdir, 'Object', 'method%21-i.ri'),
                 @s.method_file('Object', 'Object#method!')
  end

  def test_save_class
    @s.save_class @klass

    assert_directory File.join(@tmpdir, 'Object')
    assert_file File.join(@tmpdir, 'Object', 'cdesc-Object.ri')

    assert_equal @klass, @s.load_class('Object')
  end

  def test_save_method
    @s.save_method @klass, @meth

    assert_directory File.join(@tmpdir, 'Object')
    assert_file File.join(@tmpdir, 'Object', 'method-i.ri')

    assert_equal @meth, @s.load_method('Object', '#method')
  end

end

