# frozen_string_literal: true
require_relative '../helper'
require 'prism'

class RDocParserRubyColorizerTest < RDoc::TestCase
  def token(kind, text)
    RDoc::Parser::RubyColorizer::ColoredToken.new(kind, text)
  end

  def test_deferred_token_stream
    code = <<~'RUBY'
      first(<<~ONE); second(<<~TWO) && sibling
        one
      ONE
        two
      TWO
    RUBY
    program_node, unordered_tokens = Prism.parse_lex(code).value
    node = program_node.statements.body.last.left
    prism_tokens = unordered_tokens.map(&:first).sort_by! { |token| token.location.start_offset }
    expected = RDoc::Parser::RubyColorizer.partial_colorize(code, node, prism_tokens)
    context = RDoc::Parser::RubyColorizer::DeferredContext.new(code)
    loader = context.token_stream_loader(node.node_id)

    assert_equal expected, loader.call
    assert_same loader.call, loader.call
  end

  def test_deferred_token_stream_materializes_registered_nodes_once
    code = "hidden\nfirst\nsecond\n"
    nodes = Prism.parse(code).value.statements.body
    context = RDoc::Parser::RubyColorizer::DeferredContext.new(code)
    loaders = nodes.drop(1).map { |node| context.token_stream_loader(node.node_id) }
    parse_lex_calls = partial_colorize_calls = 0
    parse_lex = Prism.method(:parse_lex)
    colorizer = RDoc::Parser::RubyColorizer
    partial_colorize = colorizer.method(:partial_colorize)

    Prism.define_singleton_method(:parse_lex) do |*arguments|
      parse_lex_calls += 1
      parse_lex.call(*arguments)
    end
    colorizer.define_singleton_method(:partial_colorize) do |*arguments|
      partial_colorize_calls += 1
      partial_colorize.call(*arguments)
    end

    begin
      assert_equal %w[first second], loaders.map { |loader| loader.call.map(&:text).join }
    ensure
      Prism.define_singleton_method(:parse_lex, parse_lex)
      colorizer.define_singleton_method(:partial_colorize, partial_colorize)
    end
    assert_equal 1, parse_lex_calls
    assert_equal 2, partial_colorize_calls
  end

  def test_deferred_token_stream_preserves_lexical_scope
    code = "x = 1\ny = 2\ni = 3\nx /y/i\n"
    program_node, unordered_tokens = Prism.parse_lex(code).value
    node = program_node.statements.body.last
    prism_tokens = unordered_tokens.map(&:first).sort_by! { |token| token.location.start_offset }
    expected = RDoc::Parser::RubyColorizer.partial_colorize(code, node, prism_tokens)

    context = RDoc::Parser::RubyColorizer::DeferredContext.new(code)
    loader = context.token_stream_loader(node.node_id)

    assert_equal expected, loader.call
  end

  def test_deferred_token_stream_retries_atomically
    code = "first\nsecond\n"
    nodes = Prism.parse(code).value.statements.body
    context = RDoc::Parser::RubyColorizer::DeferredContext.new(code)
    loaders = nodes.map { |node| context.token_stream_loader(node.node_id) }
    colorizer = RDoc::Parser::RubyColorizer
    partial_colorize = colorizer.method(:partial_colorize)
    calls = 0

    colorizer.define_singleton_method(:partial_colorize) do |*arguments|
      calls += 1
      raise 'colorization failed' if calls == 2

      partial_colorize.call(*arguments)
    end
    begin
      assert_raise(RuntimeError) { loaders.first.call }
    ensure
      colorizer.define_singleton_method(:partial_colorize, partial_colorize)
    end

    assert_equal %w[first second], loaders.map { |loader| loader.call.map(&:text).join }
  end

  def test_deferred_token_stream_rejects_unmatched_node_id
    code = "first\n"
    node = Prism.parse(code).value.statements.body.first
    context = RDoc::Parser::RubyColorizer::DeferredContext.new(code)
    loader = context.token_stream_loader(node.node_id)
    missing_loader = context.token_stream_loader(node.node_id + 1_000_000)

    assert_equal "first", loader.call.map(&:text).join
    2.times { assert_raise(KeyError) { missing_loader.call } }
  end

  def test_partial_colorize
    code = <<~RUBY
      class A
        def m
          # comment
          42
        end
      end
    RUBY
    parse_result = Prism.parse_lex(code)
    program_node, unordered_tokens = parse_result.value
    prism_tokens = unordered_tokens.map(&:first).sort_by! { |token| token.location.start_offset }
    def_node = program_node.statements.body[0].body.body[0]
    tokens = RDoc::Parser::RubyColorizer.partial_colorize(code, def_node, prism_tokens)
    expected = ['  ', 'def', ' ', 'm', "\n", '    ', "# comment", "\n", '    ', '42', "\n", '  ', 'end']

    if tokens[7].text != "\n" # Prism < 2.0.0
      expected.delete_at(7)
      expected[6] = "#{expected[6]}\n"
    end

    assert_equal(expected, tokens.map(&:text))
  end

  def test_comment
    code = <<~RUBY
      # comment1
      class A
      =begin
      comment2
      =end
        def m
          42 # comment3
        end
      end
    RUBY
    tokens = RDoc::Parser::RubyColorizer.colorize(code)
    assert_equal(code, tokens.map(&:text).join)

    newline = ""
    newline = "\n" if tokens[0].text.end_with?("\n") # Prism < 2.0.0

    assert_include(tokens, token(:comment, "# comment1#{newline}"))
    assert_include(tokens, token(:comment, "=begin\n"))
    assert_include(tokens, token(:comment, "comment2\n"))
    assert_include(tokens, token(:comment, "=end\n"))
    assert_include(tokens, token(:comment, "# comment3#{newline}"))
  end

  def test_interpolated_node
    code = <<~'RUBY'
      def m
        "string#{interpolation1}example#@embvar"
        /regexp#{interpolation2}example#$embvar/
        `xstring#{interpolation3}example#@embvar`
        :"symbol#{interpolation4}example#$embvar"
      end
    RUBY
    tokens = RDoc::Parser::RubyColorizer.colorize(code)
    assert_equal(code, tokens.map(&:text).join)

    assert_include(tokens, token(:string, '"'))
    assert_include(tokens, token(:string, 'string'))
    assert_include(tokens, token(:string, '#{'))
    assert_include(tokens, token(:identifier, 'interpolation1'))
    assert_include(tokens, token(:string, '}'))
    assert_include(tokens, token(:string, 'example'))
    assert_include(tokens, token(:string, '#'))

    assert_include(tokens, token(:regexp, '/'))
    assert_include(tokens, token(:regexp, 'regexp'))
    assert_include(tokens, token(:regexp, '#{'))
    assert_include(tokens, token(:identifier, 'interpolation2'))
    assert_include(tokens, token(:regexp, '}'))
    assert_include(tokens, token(:regexp, 'example'))
    assert_include(tokens, token(:regexp, '#'))

    assert_include(tokens, token(:x_string, '`'))
    assert_include(tokens, token(:x_string, 'xstring'))
    assert_include(tokens, token(:x_string, '#{'))
    assert_include(tokens, token(:identifier, 'interpolation3'))
    assert_include(tokens, token(:x_string, '}'))
    assert_include(tokens, token(:x_string, 'example'))
    assert_include(tokens, token(:x_string, '#'))

    assert_include(tokens, token(:symbol, ':"'))
    assert_include(tokens, token(:symbol, 'symbol'))
    assert_include(tokens, token(:symbol, '#{'))
    assert_include(tokens, token(:identifier, 'interpolation4'))
    assert_include(tokens, token(:symbol, '}'))
    assert_include(tokens, token(:symbol, 'example'))
    assert_include(tokens, token(:symbol, '#'))
    assert_include(tokens, token(:symbol, '"'))
  end

  def test_percent_literal_arrays
    code = <<~'RUBY'
      def m
        %w[1 2 3]
        %W[one #{two} three]
        %i[4 5 6]
        %I[four #{five} six]
      end
    RUBY
    tokens = RDoc::Parser::RubyColorizer.colorize(code)
    assert_equal(code, tokens.map(&:text).join)
    assert_include(tokens, token(:string, '%w['))
    assert_include(tokens, token(:string, '%W['))
    assert_include(tokens, token(:string, ']'))
    assert_include(tokens, token(:string, '1'))
    assert_include(tokens, token(:string, 'one'))
    assert_include(tokens, token(:string, '#{'))
    assert_include(tokens, token(:identifier, 'two'))
    assert_include(tokens, token(:string, '}'))
    assert_include(tokens, token(:symbol, '%i['))
    assert_include(tokens, token(:symbol, '%I['))
    assert_include(tokens, token(:symbol, ']'))
    assert_include(tokens, token(:symbol, '4'))
    assert_include(tokens, token(:symbol, 'four'))
    assert_include(tokens, token(:symbol, '#{'))
    assert_include(tokens, token(:identifier, 'five'))
    assert_include(tokens, token(:symbol, '}'))
  end

  def test_multibyte
    code = <<~RUBY
      def f(s = '💎')
        # comment 💎
        puts '💎' + s
      end
    RUBY
    tokens = RDoc::Parser::RubyColorizer.colorize(code)
    assert_equal(code, tokens.map(&:text).join)
  end

  def test_string
    code = <<~'RUBY'
      # string without closing
      ?S
      # interpolated string node may not have opening/closing
      # parts may have opening/closing
      %[s3] 's4'\
      "s5#{[?s]}s6"
    RUBY
    tokens = RDoc::Parser::RubyColorizer.colorize(code)
    assert_equal(code, tokens.map(&:text).join)
    string_token_texts = tokens.select { |t| t[:kind] == :string }.map(&:text)
    expected_string_token_texts = %w[? S %[ s3 ] ' s4 ' " s5  #{ ? s } s6 "]
    assert_equal(expected_string_token_texts, string_token_texts)
  end

  def test_symbol
    code = <<~'RUBY'
      # symbol without closing
      :sym1
      # symbol with opening/closing
      :"sym2"
      %s[sym3]
      # opening and content has gap
      <<~A; :\
      A
      sym4
    RUBY
    tokens = RDoc::Parser::RubyColorizer.colorize(code)
    assert_equal(code, tokens.map(&:text).join)
    symbol_token_texts = tokens.select { |t| t[:kind] == :symbol }.map(&:text)
    expected_symbol_token_texts = %w[: sym1 :" sym2 " %s[ sym3 ] : sym4]
    assert_equal(expected_symbol_token_texts, symbol_token_texts)
  end

  def test_heredoc
    code = <<~'RUBY'
      def f
        str1 = <<~AA
          single-line-heredoc
        AA
        str2 = <<~`BB` # comment
          x-string-heredoc
        BB
        str3 = <<~CC.itself
          multi-line
          #{embed}
          heredoc
        CC
      end
    RUBY
    tokens = RDoc::Parser::RubyColorizer.colorize(code)
    assert_equal(code, tokens.map(&:text).join)
    assert_include(tokens, token(:string, '<<~AA'))
    assert_include(tokens, token(:x_string, '<<~`BB`'))
    assert_include(tokens, token(:string, '<<~CC'))
    assert_include(tokens, token(:string, "  AA\n"))
    assert_include(tokens, token(:x_string, "  BB\n"))
    assert_include(tokens, token(:string, "  CC\n"))
    assert_include(tokens, token(:string, "    single-line-heredoc\n"))
    assert_include(tokens, token(:x_string, "    x-string-heredoc\n"))
    assert_include(tokens, token(:string, "    multi-line\n"))
    assert_include(tokens, token(:string, '#{'))
    assert_include(tokens, token(:identifier, 'embed'))
    assert_include(tokens, token(:string, '}'))
    assert_include(tokens, token(:string, "    heredoc\n"))
  end

  def test_rational_imaginary
    code = <<~RUBY
      2i
      2r
      2ri

      2.0i
      2.0r
      2.0ri
    RUBY
    tokens = RDoc::Parser::RubyColorizer.colorize(code)
    assert_equal(code, tokens.map(&:text).join)

    assert_include(tokens, token(:value, "2i"))
    assert_include(tokens, token(:value, "2r"))
    assert_include(tokens, token(:value, "2ri"))
    assert_include(tokens, token(:value, "2.0i"))
    assert_include(tokens, token(:value, "2.0r"))
    assert_include(tokens, token(:value, "2.0ri"))
  end
end
