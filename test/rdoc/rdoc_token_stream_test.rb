# frozen_string_literal: true
require_relative 'helper'

class RDocTokenStreamTest < RDoc::TestCase

  class DeferredStream
    attr_reader :materializations

    def initialize(tokens)
      @tokens = tokens
      @materializations = 0
    end

    def materialize
      @materializations += 1
      @tokens
    end
  end

  def token_collector
    Class.new do
      include RDoc::TokenStream
    end.new
  end

  def test_class_to_html
    tokens = [
      { kind: :constant, text: 'CONSTANT' },
      { kind: :keyword, text: 'KW' },
      { kind: :ivar, text: 'IVAR' },
      { kind: :operator, text: 'Op' },
      { kind: :identifier, text: 'Id' },
      { kind: :symbol, text: 'Symbol' },
      { kind: :x_string, text: 'XString' },
      { kind: :comment, text: 'COMMENT' },
      { kind: :regexp, text: 'REGEXP' },
      { kind: :string, text: 'STRING' },
      { kind: :value, text: 'Val' },
      { kind: :plain, text: '\\' }
    ]

    expected = [
      '<span class="ruby-constant">CONSTANT</span>',
      '<span class="ruby-keyword">KW</span>',
      '<span class="ruby-ivar">IVAR</span>',
      '<span class="ruby-operator">Op</span>',
      '<span class="ruby-identifier">Id</span>',
      '<span class="ruby-value">Symbol</span>',
      '<span class="ruby-string">XString</span>',
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

  def test_source_language_ruby
    foo = Class.new do
      include RDoc::TokenStream
    end.new

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

  def test_add_tokens
    foo = Class.new do
      include RDoc::TokenStream
    end.new
    foo.collect_tokens(:ruby)
    foo.add_tokens([:token])
    assert_equal [:token], foo.token_stream
  end

  def test_add_token
    foo = Class.new do
      include RDoc::TokenStream
    end.new
    foo.collect_tokens(:ruby)
    foo.add_token(:token)
    assert_equal [:token], foo.token_stream
  end

  def test_collect_tokens
    foo = token_collector
    foo.collect_tokens(:ruby)
    assert_equal [], foo.token_stream
  end

  def test_collect_deferred_tokens
    tokens = [{ kind: :identifier, text: 'foo' }]
    deferred = DeferredStream.new(tokens)
    foo = token_collector

    foo.collect_tokens(:ruby, deferred)

    assert_equal 0, deferred.materializations
    assert_same tokens, foo.token_stream
    assert_same tokens, foo.token_stream
    assert_equal 1, deferred.materializations
  end

  def test_collect_existing_token_array
    tokens = [{ kind: :identifier, text: 'foo' }]
    foo = token_collector

    foo.collect_tokens(:c, tokens)

    assert_same tokens, foo.token_stream
  end

  def test_mutating_deferred_tokens
    deferred = DeferredStream.new([:first])
    foo = token_collector
    foo.collect_tokens(:ruby, deferred)
    foo.add_token(:second)
    assert_equal [:first, :second], foo.token_stream
    assert_equal 1, deferred.materializations

    deferred = DeferredStream.new([:first])
    foo = token_collector
    foo.collect_tokens(:ruby, deferred)
    foo.add_tokens([:second, :third])
    assert_equal [:first, :second, :third], foo.token_stream
    assert_equal 1, deferred.materializations

    deferred = DeferredStream.new([:first])
    foo = token_collector
    foo.collect_tokens(:ruby, deferred)
    assert_equal :first, foo.pop_token
    assert_equal [], foo.token_stream
    assert_equal 1, deferred.materializations
  end

  def test_pop_token
    foo = Class.new do
      include RDoc::TokenStream
    end.new
    foo.collect_tokens(:ruby)
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

  def test_tokens_to_s_with_deferred_tokens
    foo = token_collector
    deferred = DeferredStream.new([{ kind: :identifier, text: 'foo' }])
    foo.collect_tokens(:ruby, deferred)

    assert_equal 'foo', foo.tokens_to_s
    assert_equal 1, deferred.materializations
  end
end
