require 'stringio'
require 'tempfile'
require 'test/unit'

require 'rdoc/options'
require 'rdoc/parsers/parse_rb'
require 'rdoc/stats'

class TestRdocRubyParser < Test::Unit::TestCase

  def setup
    @tempfile = Tempfile.new self.class.name
    filename = @tempfile.path

    RDoc::TopLevel.reset
    @top_level = RDoc::TopLevel.new filename
    @fn = filename
    @options = RDoc::Options.new Hash.new
    @stats = RDoc::Stats.new

    @progress = StringIO.new
  end

  def teardown
    @tempfile.unlink
  end

  def test_parse_meta_method
    klass = RDoc::NormalClass.new 'Foo'
    klass.parent = @top_level

    comment = "##\n# my method\n"

    util_parser "add_my_method :foo, :bar\nadd_my_method :baz"

    tk = @parser.get_tk

    @parser.parse_meta_method klass, RDoc::RubyParser::NORMAL, tk, comment

    foo = klass.method_list.first
    assert_equal 'foo', foo.name
    assert_equal comment, foo.comment

    stream = [
      tk(:COMMENT, 1, 1, nil, "# File #{@top_level.file_absolute_name}, line 1"),
      RDoc::RubyParser::NEWLINE_TOKEN,
      tk(:SPACE,      1, 1,  nil, ''),
      tk(:IDENTIFIER, 1, 0,  'add_my_method', 'add_my_method'),
      tk(:SPACE,      1, 13, nil, ' '),
      tk(:SYMBOL,     1, 14, nil, ':foo'),
      tk(:COMMA,      1, 18, nil, ','),
      tk(:SPACE,      1, 19, nil, ' '),
      tk(:SYMBOL,     1, 20, nil, ':bar'),
      tk(:NL,         1, 24, nil, "\n"),
    ]

    assert_equal stream, foo.token_stream
  end

  def test_parse_meta_method_name
    klass = RDoc::NormalClass.new 'Foo'
    klass.parent = @top_level

    comment = "##\n# :method: woo_hoo!\n# my method\n"

    util_parser "add_my_method :foo, :bar\nadd_my_method :baz"

    tk = @parser.get_tk

    @parser.parse_meta_method klass, RDoc::RubyParser::NORMAL, tk, comment

    foo = klass.method_list.first
    assert_equal 'woo_hoo!', foo.name
    assert_equal "##\n# my method\n", foo.comment
  end

  def test_parse_meta_method_singleton
    klass = RDoc::NormalClass.new 'Foo'
    klass.parent = @top_level

    comment = "##\n# :singleton-method:\n# my method\n"

    util_parser "add_my_method :foo, :bar\nadd_my_method :baz"

    tk = @parser.get_tk

    @parser.parse_meta_method klass, RDoc::RubyParser::NORMAL, tk, comment

    foo = klass.method_list.first
    assert_equal 'foo', foo.name
    assert_equal true, foo.singleton, 'singleton method'
    assert_equal "##\n# my method\n", foo.comment
  end

  def test_parse_meta_method_singleton_name
    klass = RDoc::NormalClass.new 'Foo'
    klass.parent = @top_level

    comment = "##\n# :singleton-method: woo_hoo!\n# my method\n"

    util_parser "add_my_method :foo, :bar\nadd_my_method :baz"

    tk = @parser.get_tk

    @parser.parse_meta_method klass, RDoc::RubyParser::NORMAL, tk, comment

    foo = klass.method_list.first
    assert_equal 'woo_hoo!', foo.name
    assert_equal true, foo.singleton, 'singleton method'
    assert_equal "##\n# my method\n", foo.comment
  end

  def test_parse_meta_method_string_name
    klass = RDoc::NormalClass.new 'Foo'
    comment = "##\n# my method\n"

    util_parser "add_my_method 'foo'"

    tk = @parser.get_tk

    @parser.parse_meta_method klass, RDoc::RubyParser::NORMAL, tk, comment

    foo = klass.method_list.first
    assert_equal 'foo', foo.name
    assert_equal comment, foo.comment
  end

  def test_parse_statements_identifier_meta_method
    content = <<-EOF
class Foo
  ##
  # this is my method
  add_my_method :foo
end
    EOF

    util_parser content

    @parser.parse_statements @top_level, RDoc::RubyParser::NORMAL, nil, ''

    foo = @top_level.classes.first.method_list.first
    assert_equal 'foo', foo.name
  end

  def test_parse_statements_identifier_alias_method
    content = "class Foo def foo() end; alias_method :foo2, :foo end"

    util_parser content

    @parser.parse_statements @top_level, RDoc::RubyParser::NORMAL, nil, ''

    foo2 = @top_level.classes.first.method_list.last
    assert_equal 'foo2', foo2.name
    assert_equal 'foo', foo2.is_alias_for.name
  end

  def test_parse_statements_identifier_attr
    content = "class Foo; attr :foo; end"

    util_parser content

    @parser.parse_statements @top_level, RDoc::RubyParser::NORMAL, nil, ''

    foo = @top_level.classes.first.attributes.first
    assert_equal 'foo', foo.name
    assert_equal 'R', foo.rw
  end

  def test_parse_statements_identifier_attr_accessor
    content = "class Foo; attr_accessor :foo; end"

    util_parser content

    @parser.parse_statements @top_level, RDoc::RubyParser::NORMAL, nil, ''

    foo = @top_level.classes.first.attributes.first
    assert_equal 'foo', foo.name
    assert_equal 'RW', foo.rw
  end

  def test_parse_statements_identifier_extra_accessors
    @options.extra_accessors = /^my_accessor$/

    content = "class Foo; my_accessor :foo; end"

    util_parser content

    @parser.parse_statements @top_level, RDoc::RubyParser::NORMAL, nil, ''

    foo = @top_level.classes.first.attributes.first
    assert_equal 'foo', foo.name
    assert_equal '?', foo.rw
  end

  def test_parse_statements_identifier_include
    content = "class Foo; include Bar; end"

    util_parser content

    @parser.parse_statements @top_level, RDoc::RubyParser::NORMAL, nil, ''

    foo = @top_level.classes.first
    assert_equal 'Foo', foo.name
    assert_equal 1, foo.includes.length
  end

  def test_parse_statements_identifier_module_function
    content = "module Foo def foo() end; module_function :foo; end"

    util_parser content

    @parser.parse_statements @top_level, RDoc::RubyParser::NORMAL, nil, ''

    foo, s_foo = @top_level.modules.first.method_list
    assert_equal 'foo', foo.name, 'instance method name'
    assert_equal :private, foo.visibility, 'instance method visibility'
    assert_equal false, foo.singleton, 'instance method singleton'

    assert_equal 'foo', s_foo.name, 'module function name'
    assert_equal :public, s_foo.visibility, 'module function visibility'
    assert_equal true, s_foo.singleton, 'module function singleton'
  end

  def test_parse_statements_identifier_private
    content = "class Foo private; def foo() end end"

    util_parser content

    @parser.parse_statements @top_level, RDoc::RubyParser::NORMAL, nil, ''

    foo = @top_level.classes.first.method_list.first
    assert_equal 'foo', foo.name
    assert_equal :private, foo.visibility
  end

  def test_parse_statements_identifier_require
    content = "require 'bar'"

    util_parser content

    @parser.parse_statements @top_level, RDoc::RubyParser::NORMAL, nil, ''

    assert_equal 1, @top_level.requires.length
  end

  def tk(klass, line, char, name, text)
    klass = RDoc::RubyToken.const_get "Tk#{klass.to_s.upcase}"

    token = if klass.instance_method(:initialize).arity == 2 then
              raise ArgumentError, "name not used for #{klass}" unless name.nil?
              klass.new line, char
            else
              klass.new line, char, name
            end

    token.set_text text

    token
  end

  def util_parser(content)
    @parser = RDoc::RubyParser.new @top_level, @fn, content, @options, @stats
    @parser.progress = @progress
    @parser
  end

end

