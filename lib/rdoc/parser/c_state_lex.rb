# frozen_string_literal: true

##
# A simple C lexer for syntax highlighting in RDoc documentation.
# This lexer tokenizes C code into tokens compatible with RDoc::TokenStream.

class RDoc::Parser::CStateLex # :nodoc:
  Token = Struct.new(:line_no, :char_no, :kind, :text, :state)

  # C keywords
  KEYWORDS = %w[
    auto break case char const continue default do double else enum extern
    float for goto if inline int long register restrict return short signed
    sizeof static struct switch typedef union unsigned void volatile while
    _Alignas _Alignof _Atomic _Bool _Complex _Generic _Imaginary _Noreturn
    _Static_assert _Thread_local
  ].freeze

  # C preprocessor directives
  PREPROCESSOR = /^[ \t]*#[ \t]*\w+/

  ##
  # Parse C code and return an array of tokens

  def self.parse(code)
    new.parse(code)
  end

  def initialize
    @tokens = []
    @line_no = 1
    @char_no = 0
  end

  def parse(code)
    @code = code
    @pos = 0
    @line_no = 1
    @char_no = 0

    while @pos < @code.length
      case
      when scan(/\/\/[^\n]*/)
        add_token(:on_comment, matched)
      when scan(/\/\*.*?\*\//m)
        add_token(:on_comment, matched)
      when scan(PREPROCESSOR)
        add_token(:on_preprocessor, matched)
      when scan(/"(?:[^"\\]|\\.)*"/)
        add_token(:on_tstring, matched)
      when scan(/'(?:[^'\\]|\\.)*'/)
        add_token(:on_char, matched)
      when scan(/\d+\.\d+([eE][+-]?\d+)?[fFlL]?/)
        add_token(:on_float, matched)
      when scan(/0[xX][0-9a-fA-F]+[uUlL]*/)
        add_token(:on_int, matched)
      when scan(/0[0-7]+[uUlL]*/)
        add_token(:on_int, matched)
      when scan(/\d+[uUlL]*/)
        add_token(:on_int, matched)
      when scan(/[a-zA-Z_][a-zA-Z0-9_]*/)
        word = matched
        if KEYWORDS.include?(word)
          add_token(:on_kw, word)
        else
          add_token(:on_ident, word)
        end
      when scan(/&&|\|\||<<|>>|\+\+|--|[+\-*\/%&|^~!<>=]=?/)
        add_token(:on_op, matched)
      when scan(/\n/)
        add_token(:on_nl, matched)
        @line_no += 1
        @char_no = 0
        next
      when scan(/[ \t]+/)
        add_token(:on_sp, matched)
      when scan(/[{}()\[\];,.]/)
        add_token(:on_punct, matched)
      else
        # Unknown character, consume it
        advance
      end
    end

    @tokens
  end

  private

  def scan(pattern)
    if @code[@pos..-1] =~ /\A#{pattern}/
      @match = $&
      advance(@match.length)
      true
    else
      false
    end
  end

  def matched
    @match
  end

  def advance(count = 1)
    @pos += count
    @char_no += count
  end

  def add_token(kind, text)
    @tokens << Token.new(@line_no, @char_no - text.length, kind, text, nil)
  end
end
