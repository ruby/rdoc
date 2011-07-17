# coding: utf-8

require 'tempfile'
require 'rubygems'
require 'minitest/autorun'
require 'rdoc/markup/pre_process'
require 'rdoc/code_objects'

class TestRDocMarkupPreProcess < MiniTest::Unit::TestCase

  def setup
    RDoc::Markup::PreProcess.registered.clear

    @tempfile = Tempfile.new 'test_rdoc_markup_pre_process'
    @file_name = File.basename @tempfile.path
    @dir  = File.dirname @tempfile.path

    @pp = RDoc::Markup::PreProcess.new __FILE__, [@dir]
  end

  def teardown
    @tempfile.close
  end

  def test_include_file
    @tempfile.write <<-INCLUDE
# -*- mode: rdoc; coding: utf-8; fill-column: 74; -*-

Regular expressions (<i>regexp</i>s) are patterns which describe the
contents of a string.
    INCLUDE

    @tempfile.flush
    @tempfile.rewind

    content = @pp.include_file @file_name, '', nil

    expected = <<-EXPECTED
Regular expressions (<i>regexp</i>s) are patterns which describe the
contents of a string.
    EXPECTED

    # FIXME 1.9 fix on windoze
    # preprocessor uses binread, so line endings are \r\n
    expected.gsub!("\n", "\r\n") if
      RUBY_VERSION < "1.9.3" && RUBY_PLATFORM =~ /mswin|mingw/

    assert_equal expected, content
  end

  def test_include_file_encoding_incompatible
    skip "Encoding not implemented" unless Object.const_defined? :Encoding

    @tempfile.write <<-INCLUDE
# -*- mode: rdoc; coding: utf-8; fill-column: 74; -*-

π
    INCLUDE

    @tempfile.flush
    @tempfile.rewind

    content = @pp.include_file @file_name, '', Encoding::US_ASCII

    expected = "?\n"

    # FIXME 1.9 fix on windoze
    # preprocessor uses binread, so line endings are \r\n
    expected.gsub!("\n", "\r\n") if
      RUBY_VERSION < "1.9.3" && RUBY_PLATFORM =~ /mswin|mingw/

    assert_equal expected, content
  end

  def test_handle
    text = "# :x: y\n"
    out = @pp.handle text

    assert_same out, text
    assert_equal "# :x: y\n", text
  end

  def test_handle_block
    text = "# :x: y\n"

    @pp.handle text do |directive, param|
      false
    end

    assert_equal "# :x: y\n", text

    @pp.handle text do |directive, param|
      ''
    end

    assert_equal "", text
  end

  def test_handle_category
    context = RDoc::Context.new
    original_section = context.current_section

    text = "# :category: other\n"

    @pp.handle text, context

    refute_equal original_section, context.current_section
  end

  def test_handle_code_object
    cd = RDoc::CodeObject.new
    text = "# :x: y\n"
    @pp.handle text, cd

    assert_equal "# :x: y\n", text
    assert_equal 'y', cd.metadata['x']

    cd.metadata.clear
    text = "# :x:\n"
    @pp.handle text, cd

    assert_equal "# :x: \n", text
    assert_includes cd.metadata, 'x'
  end

  def test_handle_code_object_block
    cd = RDoc::CodeObject.new
    text = "# :x: y\n"
    @pp.handle text, cd do
      false
    end

    assert_equal "# :x: y\n", text
    assert_empty cd.metadata

    @pp.handle text, cd do
      nil
    end

    assert_equal "# :x: y\n", text
    assert_equal 'y', cd.metadata['x']

    cd.metadata.clear

    @pp.handle text, cd do
      ''
    end

    assert_equal '', text
    assert_empty cd.metadata
  end

  def test_handle_doc
    code_object = RDoc::CodeObject.new
    code_object.document_self = false
    code_object.force_documentation = false

    text = "# :doc:\n"

    @pp.handle text, code_object

    assert code_object.document_self
    assert code_object.force_documentation
  end

  def test_handle_doc_no_context
    text = "# :doc:\n"

    assert_empty @pp.handle(text, nil)

    assert_empty text
  end

  def test_handle_nodoc
    code_object = RDoc::CodeObject.new
    code_object.document_self = true
    code_object.document_children = true

    text = "# :nodoc:\n"

    @pp.handle text, code_object

    refute code_object.document_self
    assert code_object.document_children
  end

  def test_handle_nodoc_all
    code_object = RDoc::CodeObject.new
    code_object.document_self = true
    code_object.document_children = true

    text = "# :nodoc: all\n"

    @pp.handle text, code_object

    refute code_object.document_self
    refute code_object.document_children
  end

  def test_handle_nodoc_no_context
    text = "# :nodoc:\n"

    assert_empty @pp.handle(text, nil)

    assert_empty text
  end

  def test_handle_registered
    RDoc::Markup::PreProcess.register 'x'
    text = "# :x: y\n"
    @pp.handle text

    assert_equal '', text

    text = "# :x: y\n"

    @pp.handle text do |directive, param|
      false
    end

    assert_equal "# :x: y\n", text

    text = "# :x: y\n"

    @pp.handle text do |directive, param|
      ''
    end

    assert_equal "", text
  end

  def test_handle_registered_block
    called = nil
    RDoc::Markup::PreProcess.register 'x' do |directive, param|
      called = [directive, param]
      'blah'
    end

    text = "# :x: y\n"
    @pp.handle text

    assert_equal 'blah', text
    assert_equal %w[x y], called
  end

  def test_handle_registered_code_object
    RDoc::Markup::PreProcess.register 'x'
    cd = RDoc::CodeObject.new

    text = "# :x: y\n"
    @pp.handle text, cd

    assert_equal '', text
    assert_equal 'y', cd.metadata['x']

    cd.metadata.clear
    text = "# :x: y\n"

    @pp.handle text do |directive, param|
      false
    end

    assert_equal "# :x: y\n", text
    assert_empty cd.metadata

    text = "# :x: y\n"

    @pp.handle text do |directive, param|
      ''
    end

    assert_equal "", text
    assert_empty cd.metadata
  end

  def test_handle_yield
    method = RDoc::AnyMethod.new nil, 'm'
    method.params = 'index, &block'

    text = "# :yield: item\n"

    @pp.handle text, method

    assert_equal 'item', method.block_params
    assert_equal 'index', method.params
  end

  def test_handle_yield_block_param
    method = RDoc::AnyMethod.new nil, 'm'
    method.params = '&block'

    text = "# :yield: item\n"

    @pp.handle text, method

    assert_equal 'item', method.block_params
    assert_empty method.params
  end

  def test_handle_yield_no_context
    text = "# :yield: item\n"

    assert_empty @pp.handle(text, nil)

    assert_empty text
  end

  def test_handle_yields
    method = RDoc::AnyMethod.new nil, 'm'

    text = "# :yields: item\n"

    @pp.handle text, method

    assert_equal 'item', method.block_params
  end

end

