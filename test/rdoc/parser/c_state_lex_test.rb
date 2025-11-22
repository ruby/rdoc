# frozen_string_literal: true
require_relative '../helper'
require 'rdoc/parser/c_state_lex'

class RDocParserCStateLexTest < RDoc::TestCase

  def test_parse_keywords
    code = "int void return"
    tokens = RDoc::Parser::CStateLex.parse(code)

    kw_tokens = tokens.select { |t| t[:kind] == :on_kw }
    assert_equal 3, kw_tokens.length
    assert_equal 'int', kw_tokens[0][:text]
    assert_equal 'void', kw_tokens[1][:text]
    assert_equal 'return', kw_tokens[2][:text]
  end

  def test_parse_identifiers
    code = "my_variable foo_bar"
    tokens = RDoc::Parser::CStateLex.parse(code)

    assert_equal 3, tokens.length
    assert_equal :on_ident, tokens[0][:kind]
    assert_equal 'my_variable', tokens[0][:text]
    assert_equal :on_ident, tokens[2][:kind]
    assert_equal 'foo_bar', tokens[2][:text]
  end

  def test_parse_numbers
    code = "42 3.14 0xFF 0777"
    tokens = RDoc::Parser::CStateLex.parse(code)

    int_tokens = tokens.select { |t| t[:kind] == :on_int }
    float_tokens = tokens.select { |t| t[:kind] == :on_float }

    assert_equal 3, int_tokens.length
    assert_equal 1, float_tokens.length
    assert_equal '42', int_tokens[0][:text]
    assert_equal '3.14', float_tokens[0][:text]
  end

  def test_parse_strings
    code = '"hello world" \'c\''
    tokens = RDoc::Parser::CStateLex.parse(code)

    string_tokens = tokens.select { |t| t[:kind] == :on_tstring }
    char_tokens = tokens.select { |t| t[:kind] == :on_char }

    assert_equal 1, string_tokens.length
    assert_equal 1, char_tokens.length
    assert_equal '"hello world"', string_tokens[0][:text]
    assert_equal "'c'", char_tokens[0][:text]
  end

  def test_parse_comments
    code = "// single line comment\n/* multi line\ncomment */"
    tokens = RDoc::Parser::CStateLex.parse(code)

    comment_tokens = tokens.select { |t| t[:kind] == :on_comment }

    assert_equal 2, comment_tokens.length
    assert_equal '// single line comment', comment_tokens[0][:text]
    assert comment_tokens[1][:text].include?('multi line')
  end

  def test_parse_preprocessor
    code = "#include <stdio.h>\n#define MAX 100"
    tokens = RDoc::Parser::CStateLex.parse(code)

    pp_tokens = tokens.select { |t| t[:kind] == :on_preprocessor }

    assert_equal 2, pp_tokens.length
    assert pp_tokens[0][:text].start_with?('#include')
    assert pp_tokens[1][:text].start_with?('#define')
  end

  def test_parse_operators
    code = "+ - * / == != && ||"
    tokens = RDoc::Parser::CStateLex.parse(code)

    op_tokens = tokens.select { |t| t[:kind] == :on_op }

    assert_equal 8, op_tokens.length
    assert_equal '+', op_tokens[0][:text]
    assert_equal '==', op_tokens[4][:text]
  end

  def test_parse_complex_code
    code = <<~C
      #include <stdio.h>

      int main() {
          int x = 42;
          printf("Hello, %d\\n", x);
          return 0;
      }
    C

    tokens = RDoc::Parser::CStateLex.parse(code)

    refute_empty tokens

    preprocessor_tokens = tokens.select { |t| t[:kind] == :on_preprocessor }
    assert_equal 1, preprocessor_tokens.length
    assert preprocessor_tokens[0][:text].start_with?('#include')

    keyword_tokens = tokens.select { |t| t[:kind] == :on_kw }
    assert_equal 3, keyword_tokens.length
    assert_equal 'int', keyword_tokens[0][:text]
    assert_equal 'int', keyword_tokens[1][:text]
    assert_equal 'return', keyword_tokens[2][:text]

    identifier_tokens = tokens.select { |t| t[:kind] == :on_ident }
    assert identifier_tokens.length >= 4
    assert identifier_tokens.any? { |t| t[:text] == 'main' }
    assert identifier_tokens.any? { |t| t[:text] == 'printf' }
    assert_equal 2, identifier_tokens.count { |t| t[:text] == 'x' }

    int_tokens = tokens.select { |t| t[:kind] == :on_int }
    assert_equal 2, int_tokens.length
    assert_equal '42', int_tokens[0][:text]
    assert_equal '0', int_tokens[1][:text]

    string_tokens = tokens.select { |t| t[:kind] == :on_tstring }
    assert_equal 1, string_tokens.length
    assert string_tokens[0][:text].include?('Hello')
  end

end
