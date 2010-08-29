require 'minitest/autorun'
require 'rdoc/rdoc'
require 'tmpdir'
require 'fileutils'

class TestRDocGeneratorDarkfish < MiniTest::Unit::TestCase

  def setup
    @pwd = Dir.pwd
    RDoc::TopLevel.reset

    @tmpdir = File.join Dir.tmpdir, "test_rdoc_generator_darkfish_#{$$}"
    FileUtils.mkdir_p @tmpdir
    Dir.chdir @tmpdir
    @options = RDoc::Options.new
    @options.op_dir = @tmpdir
    @options.generator = RDoc::Generator::Darkfish

    rd = RDoc::RDoc.new
    rd.options = @options
    RDoc::RDoc.current = rd

    @g = @options.generator.new @options

    rd.generator = @g

    @top_level = RDoc::TopLevel.new 'file.rb'
    @klass = @top_level.add_class RDoc::NormalClass, 'Object'
    @meth = RDoc::AnyMethod.new nil, 'method'
    @meth_bang = RDoc::AnyMethod.new nil, 'method!'
    @attr = RDoc::Attr.new nil, 'attr', 'RW', ''

    @klass.add_method @meth
    @klass.add_method @meth_bang
    @klass.add_attribute @attr
  end

  def teardown
    Dir.chdir @pwd
    FileUtils.rm_rf @tmpdir
  end

  def assert_file path
    assert File.file?(path), "#{path} is not a file"
  end

  def refute_file path
    refute File.exist?(path), "#{path} exists"
  end

  def test_generate
    top_level = RDoc::TopLevel.new 'file.rb'
    top_level.add_class @klass.class, @klass.name

    @g.generate [top_level]

    assert_file 'index.html'
    assert_file 'Object.html'
    assert_file 'file_rb.html'

    encoding = if Object.const_defined? :Encoding then
                 Regexp.escape Encoding.default_external.name
               else
                 Regexp.escape 'UTF-8'
               end

    assert_match(/<meta content="text\/html; charset=#{encoding}"/,
                 File.read('index.html'))
    assert_match(/<meta content="text\/html; charset=#{encoding}"/,
                 File.read('Object.html'))
    assert_match(/<meta content="text\/html; charset=#{encoding}"/,
                 File.read('file_rb.html'))
  end

  def test_generate_dry_run
    @options.dry_run = true
    top_level = RDoc::TopLevel.new 'file.rb'
    top_level.add_class @klass.class, @klass.name

    @g.generate [top_level]

    refute_file 'index.html'
    refute_file 'Object.html'
    refute_file 'file_rb.html'
  end

end

