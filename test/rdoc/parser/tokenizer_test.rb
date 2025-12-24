# frozen_string_literal: true
require_relative '../helper'
require 'rdoc/parser/tokenizer'

class RDocParserTokenizerTest < RDoc::TestCase
  def test_partial_tokenize
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
    tokens = RDoc::Parser::Tokenizer.partial_tokenize(code, def_node, prism_tokens, parse_result.comments)
    expected = ['def', ' ', 'm', "\n", '    ', '# comment', "\n", '    ', '42', "\n", '  ', 'end']
    assert_equal(expected, tokens.map(&:last))
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
    tokens = RDoc::Parser::Tokenizer.tokenize(code)
    assert_equal(code, tokens.map(&:last).join)
    assert_include(tokens, [:on_comment, '# comment1'])
    assert_include(tokens, [:on_comment, "=begin\ncomment2\n=end\n"])
    assert_include(tokens, [:on_comment, '# comment3'])
  end

  def test_squash_uminus
    code = <<~RUBY
      def m
        -42; -4.2; -42i; -42r
      end
    RUBY
    tokens = RDoc::Parser::Tokenizer.tokenize(code)
    assert_equal(code, tokens.map(&:last).join)
    assert_include(tokens, [:on_int, '-42'])
    assert_include(tokens, [:on_float, '-4.2'])
    assert_include(tokens, [:on_imaginary, '-42i'])
    assert_include(tokens, [:on_rational, '-42r'])
  end

  def test_squash_interpolated_node
    code = <<~'RUBY'
      def m
        "string#{interpolation}example"
        /regexp#{interpolation}example/
        :"symbol#{interpolation}example"
      end
    RUBY
    tokens = RDoc::Parser::Tokenizer.tokenize(code)
    assert_equal(code, tokens.map(&:last).join)
    assert_include(tokens, [:on_dstring, '"string#{interpolation}example"'])
    assert_include(tokens, [:on_regexp, '/regexp#{interpolation}example/'])
    assert_include(tokens, [:on_symbol, ':"symbol#{interpolation}example"'])
  end

  def test_squash_words
    code = <<~RUBY
      def m
        a = 1, 2 # array without opening. %w[] squashing should not fail with this input
        %w[one two three]
        %W[one \#{two} three]
        %i[one two three]
        %I[one \#{two} three]
      end
    RUBY
    tokens = RDoc::Parser::Tokenizer.tokenize(code)
    assert_equal(code, tokens.map(&:last).join)
    assert_include(tokens, [:on_dstring, '%w[one two three]'])
    assert_include(tokens, [:on_dstring, '%W[one #{two} three]'])
    assert_include(tokens, [:on_dstring, '%i[one two three]'])
    assert_include(tokens, [:on_dstring, '%I[one #{two} three]'])
  end

  def test_multibyte
    code = <<~RUBY
      def f(s = '💎')
        # comment 💎
        puts '💎' + s
      end
    RUBY
    tokens = RDoc::Parser::Tokenizer.tokenize(code)
    assert_equal(code, tokens.map(&:last).join)
  end

  def test_string_concat_node
    # concatenated string node has no opening
    code = <<~'RUBY'
      def f
        %[hello] 'HELLO'\
        "world"
      end
    RUBY
    tokens = RDoc::Parser::Tokenizer.tokenize(code)
    assert_equal(code, tokens.map(&:last).join)
  end

  def test_squash_heredoc
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
    tokens = RDoc::Parser::Tokenizer.tokenize(code)
    assert_equal(code, tokens.map(&:last).join)
    assert_include(tokens, [:on_heredoc_beg, '<<~AA'])
    assert_include(tokens, [:on_heredoc_beg, '<<~`BB`'])
    assert_include(tokens, [:on_heredoc_beg, '<<~CC'])
    assert_include(tokens, [:on_heredoc_end, "  AA\n"])
    assert_include(tokens, [:on_heredoc_end, "  BB\n"])
    assert_include(tokens, [:on_heredoc_end, "  CC\n"])
    assert_include(tokens, [:on_heredoc, "    single-line-heredoc\n"])
    assert_include(tokens, [:on_heredoc, "    x-string-heredoc\n"])
    assert_include(tokens, [:on_heredoc, "    multi-line\n    \#{embed}\n    heredoc\n"])
  end
end
