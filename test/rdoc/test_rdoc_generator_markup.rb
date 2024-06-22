# frozen_string_literal: true
require_relative 'helper'

class TestRDocGeneratorMarkup < RDoc::TestCase

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

  def test_description
    @comment = '= Hello'

    links = '<span><a href="#label-Hello">&para;</a> ' +
            '<a href="#top">&uarr;</a></span>'

    assert_equal "\n<h1 id=\"label-Hello\">Hello#{links}</h1>\n", description
  end

  def test_formatter
    assert_kind_of RDoc::Markup::ToHtmlCrossref, formatter
    refute formatter.show_hash
    assert_same self, formatter.context
  end

  attr_reader :path

  def find_symbol name
    @symbols[name]
  end

end
