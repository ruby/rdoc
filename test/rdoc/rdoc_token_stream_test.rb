# frozen_string_literal: true
require_relative 'helper'

class RDocTokenStreamTest < RDoc::TestCase

  def test_class_to_html
    tokens = [
      { :line_no => 0, :char_no => 0, :kind => :on_const, :text => 'CONSTANT' },
      { :line_no => 0, :char_no => 0, :kind => :on_kw, :text => 'KW' },
      { :line_no => 0, :char_no => 0, :kind => :on_ivar, :text => 'IVAR' },
      { :line_no => 0, :char_no => 0, :kind => :on_op, :text => 'Op' },
      { :line_no => 0, :char_no => 0, :kind => :on_ident, :text => 'Id' },
      { :line_no => 0, :char_no => 0, :kind => :on_backref, :text => 'Node' },
      { :line_no => 0, :char_no => 0, :kind => :on_comment, :text => 'COMMENT' },
      { :line_no => 0, :char_no => 0, :kind => :on_regexp, :text => 'REGEXP' },
      { :line_no => 0, :char_no => 0, :kind => :on_tstring, :text => 'STRING' },
      { :line_no => 0, :char_no => 0, :kind => :on_int, :text => 'Val' },
      { :line_no => 0, :char_no => 0, :kind => :on_unknown, :text => '\\' }
    ]

    expected = [
      '<span class="ruby-constant">CONSTANT</span>',
      '<span class="ruby-keyword">KW</span>',
      '<span class="ruby-ivar">IVAR</span>',
      '<span class="ruby-operator">Op</span>',
      '<span class="ruby-identifier">Id</span>',
      '<span class="ruby-node">Node</span>',
      '<span class="ruby-comment">COMMENT</span>',
      '<span class="ruby-regexp">REGEXP</span>',
      '<span class="ruby-string">STRING</span>',
      '<span class="ruby-value">Val</span>',
      '\\'
    ].join

    assert_equal expected, RDoc::TokenStream.to_html(tokens)
  end

  def test_class_to_html_empty
    assert_equal '', RDoc::TokenStream.to_html([])
  end

  def test_class_to_html_c
    tokens = [
      { line_no: 0, char_no: 0, kind: :on_kw, text: 'int' },
      { line_no: 0, char_no: 0, kind: :on_ident, text: 'main' },
      { line_no: 0, char_no: 0, kind: :on_op, text: '+' },
      { line_no: 0, char_no: 0, kind: :on_int, text: '42' },
      { line_no: 0, char_no: 0, kind: :on_tstring, text: '"hello"' },
      { line_no: 0, char_no: 0, kind: :on_char, text: "'c'" },
      { line_no: 0, char_no: 0, kind: :on_comment, text: '// comment' },
      { line_no: 0, char_no: 0, kind: :on_preprocessor, text: '#include' },
      { line_no: 0, char_no: 0, kind: :on_unknown, text: '\\' }
    ]

    expected = [
      '<span class="c-keyword">int</span>',
      '<span class="c-identifier">main</span>',
      '<span class="c-operator">+</span>',
      '<span class="c-value">42</span>',
      '<span class="c-string">&quot;hello&quot;</span>',
      '<span class="c-value">&#39;c&#39;</span>',
      '<span class="c-comment">// comment</span>',
      '<span class="c-preprocessor">#include</span>',
      '\\'
    ].join

    assert_equal expected, RDoc::TokenStream.to_html_c(tokens)
  end

  def test_class_to_html_c_empty
    assert_equal '', RDoc::TokenStream.to_html_c([])
  end

  def test_source_language_ruby
    foo = Class.new do
      include RDoc::TokenStream
    end.new

    # Default is :ruby
    foo.collect_tokens
    assert_equal 'ruby', foo.source_language

    # Explicit :ruby
    foo.collect_tokens(:ruby)
    assert_equal 'ruby', foo.source_language
  end

  def test_source_language_c
    foo = Class.new do
      include RDoc::TokenStream
    end.new

    foo.collect_tokens(:c)
    assert_equal 'c', foo.source_language
  end

  def test_to_html_dispatches_based_on_language
    foo = Class.new do
      include RDoc::TokenStream
    end.new

    # Ruby tokens
    foo.collect_tokens(:ruby)
    ruby_tokens = [
      { line_no: 1, char_no: 0, kind: :on_kw, text: 'def', state: nil },
      { line_no: 1, char_no: 4, kind: :on_ident, text: 'foo', state: nil }
    ]
    foo.add_tokens(ruby_tokens)
    html = foo.to_html
    assert_includes html, 'ruby-keyword'

    # C tokens
    foo.collect_tokens(:c)
    c_tokens = [
      { line_no: 1, char_no: 0, kind: :on_kw, text: 'int', state: nil }
    ]
    foo.add_tokens(c_tokens)
    html = foo.to_html
    assert_includes html, 'c-keyword'
  end

  def test_add_tokens
    foo = Class.new do
      include RDoc::TokenStream
    end.new
    foo.collect_tokens
    foo.add_tokens([:token])
    assert_equal [:token], foo.token_stream
  end

  def test_add_token
    foo = Class.new do
      include RDoc::TokenStream
    end.new
    foo.collect_tokens
    foo.add_token(:token)
    assert_equal [:token], foo.token_stream
  end

  def test_collect_tokens
    foo = Class.new do
      include RDoc::TokenStream
    end.new
    foo.collect_tokens
    assert_equal [], foo.token_stream
  end

  def test_pop_token
    foo = Class.new do
      include RDoc::TokenStream
    end.new
    foo.collect_tokens
    foo.add_token(:token)
    foo.pop_token
    assert_equal [], foo.token_stream
  end

  def test_token_stream
    foo = Class.new do
      include RDoc::TokenStream
    end.new
    assert_equal nil, foo.token_stream
  end

  def test_tokens_to_s
    foo = Class.new do
      include RDoc::TokenStream

      def initialize
        @token_stream = [
          { line_no: 0, char_no: 0, kind: :on_ident,   text: "foo" },
          { line_no: 0, char_no: 0, kind: :on_sp,      text: " " },
          { line_no: 0, char_no: 0, kind: :on_tstring, text: "'bar'" },
        ]
      end
    end.new

    assert_equal "foo 'bar'", foo.tokens_to_s

    foo = Class.new do
      include RDoc::TokenStream

      def initialize
        @token_stream = nil
      end
    end.new
    assert_equal "", foo.tokens_to_s
  end
end
