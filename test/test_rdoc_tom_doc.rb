require 'rdoc/test_case'

class TestRDocTomDoc < RDoc::TestCase

  def setup
    super

    @TD = RDoc::TomDoc
    @td = @TD.new
  end

  def mu_pp obj
    s = ''
    s = PP.pp obj, s
    s = s.force_encoding Encoding.default_external if defined? Encoding
    s.chomp
  end

  def test_parse_paragraph
    c = comment "Public: Do some stuff\n"

    expected =
      @RM::Document.new(
        @RM::Paragraph.new('Do some stuff'))

    assert_equal expected, @TD.parse(c)
  end

  def test_parse_arguments
    c = comment <<-TEXT
Do some stuff

foo - A comment goes here
    TEXT

    expected =
      @RM::Document.new(
        @RM::Paragraph.new('Do some stuff'),
        @RM::BlankLine.new,
        @RM::List.new(
          :NOTE,
          @RM::ListItem.new(
            'foo',
            @RM::Paragraph.new('A comment goes here'))))

    assert_equal expected, @TD.parse(c)
  end

  def test_parse_arguments_multiline
    c = comment <<-TEXT
Do some stuff

foo - A comment goes here
  and is more than one line
    TEXT

    expected =
      @RM::Document.new(
        @RM::Paragraph.new('Do some stuff'),
        @RM::BlankLine.new,
        @RM::List.new(
          :NOTE,
          @RM::ListItem.new(
            'foo',
            @RM::Paragraph.new(
              'A comment goes here', 'and is more than one line'))))

    assert_equal expected, @TD.parse(c)
  end

  def test_parse_examples
    c = comment <<-TEXT
Do some stuff

Examples

  1 + 1
    TEXT

    expected =
      @RM::Document.new(
        @RM::Paragraph.new('Do some stuff'),
        @RM::BlankLine.new,
        @RM::Heading.new(3, 'Examples'),
        @RM::BlankLine.new,
        @RM::Verbatim.new("1 + 1\n"))

    assert_equal expected, @TD.parse(c)
  end

  def test_parse_returns
    c = comment <<-TEXT
Do some stuff

Returns a thing
    TEXT

    expected =
      @RM::Document.new(
        @RM::Paragraph.new('Do some stuff'),
        @RM::BlankLine.new,
        @RM::Paragraph.new('Returns a thing'))

    assert_equal expected, @TD.parse(c)
  end

  def test_parse_returns_multiline
    c = comment <<-TEXT
Do some stuff

Returns a thing
  that is multiline
    TEXT

    expected =
      @RM::Document.new(
        @RM::Paragraph.new('Do some stuff'),
        @RM::BlankLine.new,
        @RM::Paragraph.new('Returns a thing', 'that is multiline'))

    assert_equal expected, @TD.parse(c)
  end

  def test_tokenize_paragraph
    @td.tokenize "Public: Do some stuff\n"

    expected = [
      [:TEXT,    "Do some stuff",  0, 0],
      [:NEWLINE, "\n",            13, 0],
    ]

    assert_equal expected, @td.tokens
  end

  def test_tokenize_arguments
    @td.tokenize <<-TEXT
Do some stuff

foo - A comment goes here
    TEXT

    expected = [
      [:TEXT,    "Do some stuff",        0, 0],
      [:NEWLINE, "\n",                  13, 0],
      [:NEWLINE, "\n",                   0, 1],
      [:NOTE,    "foo",                  0, 2],
      [:TEXT,    "A comment goes here",  6, 2],
      [:NEWLINE, "\n",                  25, 2],
    ]

    assert_equal expected, @td.tokens
  end

  def test_tokenize_arguments_multiline
    @td.tokenize <<-TEXT
Do some stuff

foo - A comment goes here
  and is more than one line
    TEXT

    expected = [
      [:TEXT,    "Do some stuff",              0, 0],
      [:NEWLINE, "\n",                        13, 0],
      [:NEWLINE, "\n",                         0, 1],
      [:NOTE,    "foo",                        0, 2],
      [:TEXT,    "A comment goes here",        6, 2],
      [:NEWLINE, "\n",                        25, 2],
      [:TEXT,    "and is more than one line",  2, 3],
      [:NEWLINE, "\n",                        27, 3],
    ]

    assert_equal expected, @td.tokens
  end

  def test_tokenize_examples
    @td.tokenize <<-TEXT
Do some stuff

Examples

  1 + 1
    TEXT

    expected = [
      [:TEXT,    "Do some stuff",  0, 0],
      [:NEWLINE, "\n",            13, 0],
      [:NEWLINE, "\n",             0, 1],
      [:HEADER,  3,                0, 2],
      [:TEXT,    "Examples",       0, 2],
      [:NEWLINE, "\n",             8, 2],
      [:NEWLINE, "\n",             0, 3],
      [:TEXT,    "1 + 1",          2, 4],
      [:NEWLINE, "\n",             7, 4],
    ]

    assert_equal expected, @td.tokens
  end

  def test_tokenize_returns
    @td.tokenize <<-TEXT
Do some stuff

Returns a thing
    TEXT

    expected = [
      [:TEXT,    "Do some stuff",    0, 0],
      [:NEWLINE, "\n",              13, 0],
      [:NEWLINE, "\n",               0, 1],
      [:TEXT,    "Returns a thing",  0, 2],
      [:NEWLINE, "\n",              15, 2],
    ]

    assert_equal expected, @td.tokens
  end

  def test_tokenize_returns_multiline
    @td.tokenize <<-TEXT
Do some stuff

Returns a thing
  that is multiline
    TEXT

    expected = [
      [:TEXT,    "Do some stuff",      0, 0],
      [:NEWLINE, "\n",                13, 0],
      [:NEWLINE, "\n",                 0, 1],
      [:TEXT,    "Returns a thing",    0, 2],
      [:NEWLINE, "\n",                15, 2],
      [:TEXT,    "that is multiline",  2, 3],
      [:NEWLINE, "\n",                19, 3],
    ]

    assert_equal expected, @td.tokens
  end

end

