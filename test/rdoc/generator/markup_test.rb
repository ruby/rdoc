# frozen_string_literal: true
require_relative '../helper'

class RDocGeneratorMarkupTest < RDoc::TestCase

  include RDoc::Text
  include RDoc::Generator::Markup

  attr_reader :store

  def setup
    super

    @options = RDoc::Options.new
    @rdoc.options = @options

    @parent = self
    @path = '/index.html'
    @symbols = {}
  end

  def test_aref_to
    assert_equal 'Foo/Bar.html', aref_to('Foo/Bar.html')
  end

  def test_as_href
    assert_equal '../index.html', as_href('Foo/Bar.html')
  end

  def test_cvs_url
    assert_equal 'http://example/this_page',
                 cvs_url('http://example/', 'this_page')

    assert_equal 'http://example/?page=this_page&foo=bar',
                 cvs_url('http://example/?page=%s&foo=bar', 'this_page')
  end

  def test_description
    @comment = '= Hello'

    # When there's no context (self returns nil for aref), there's no context prefix in the legacy label
    assert_equal "\n<span id=\"label-Hello\" class=\"legacy-anchor\"></span>\n<h1 id=\"hello\"><a href=\"#hello\">Hello</a></h1>\n", description
  end

  def test_formatter
    assert_kind_of RDoc::Markup::ToHtmlCrossref, formatter
    refute formatter.show_hash
    assert_same self, formatter.context
  end

  def test_superclass_method_link
    method = method_calling_super 'foo'

    expected = '<a href="Outer.html#method-i-foo"><code>Outer#foo</code></a>'
    assert_equal expected, method.superclass_method_link

    assert_nil RDoc::AnyMethod.new('bar').superclass_method_link
  end

  def test_superclass_method_link_escapes_name
    method = method_calling_super '<<'

    link = method.superclass_method_link

    expected = '<a href="Outer.html#method-i-3C-3C"><code>Outer#&lt;&lt;</code></a>'
    assert_equal expected, link
    refute_match %r{<code>Outer#<<</code>}, link
  end

  attr_reader :path

  def find_symbol(name)
    @symbols[name]
  end

  def method_calling_super(name)
    top_level = @store.add_file 'superclass_method_link.rb'
    parent_method = RDoc::AnyMethod.new name

    method = RDoc::AnyMethod.new name
    method.calls_super = true

    parent = top_level.add_class RDoc::NormalClass, 'Outer'
    parent.add_method parent_method

    child = top_level.add_class RDoc::NormalClass, 'Inner', parent.full_name
    child.add_method method

    method
  end

end
