require 'rdoc/test_case'

class TestRDocRubyLex < RDoc::TestCase

  def mu_pp(obj)
    s = ''
    s = PP.pp obj, s
    s = s.force_encoding(Encoding.default_external) if defined? Encoding
    s.chomp
  end

  def test_class_tokenize
    tokens = RDoc::RubyLex.tokenize "def x() end", nil

    expected = [
      RDoc::RubyToken::TkDEF       .new( 0, 1,  0, "def"),
      RDoc::RubyToken::TkSPACE     .new( 3, 1,  3, " "),
      RDoc::RubyToken::TkIDENTIFIER.new( 4, 1,  4, "x"),
      RDoc::RubyToken::TkLPAREN    .new( 5, 1,  5, "("),
      RDoc::RubyToken::TkRPAREN    .new( 6, 1,  6, ")"),
      RDoc::RubyToken::TkSPACE     .new( 7, 1,  7, " "),
      RDoc::RubyToken::TkEND       .new( 8, 1,  8, "end"),
      RDoc::RubyToken::TkNL        .new(11, 1, 11, "\n"),
    ]

    assert_equal expected, tokens
  end

  def test_unary_minus
    ruby_lex = RDoc::RubyLex.new("-1", nil)
    assert_equal("-1", ruby_lex.token.value)

    ruby_lex = RDoc::RubyLex.new("a[-2]", nil)
    2.times { ruby_lex.token } # skip "a" and "["
    assert_equal("-2", ruby_lex.token.value)

    ruby_lex = RDoc::RubyLex.new("a[0..-12]", nil)
    4.times { ruby_lex.token } # skip "a", "[", "0", and ".."
    assert_equal("-12", ruby_lex.token.value)

    ruby_lex = RDoc::RubyLex.new("0+-0.1", nil)
    2.times { ruby_lex.token } # skip "0" and "+"
    assert_equal("-0.1", ruby_lex.token.value)
  end

end

