require 'pp'
require 'rubygems'
require 'minitest/autorun'
require 'rdoc/markup'
require 'rdoc/markup/to_test'

class TestRDocMarkupParser < MiniTest::Unit::TestCase

  def setup
    @RMP = RDoc::Markup::Parser
  end

  def mu_pp(obj)
    s = ''
    s = PP.pp obj, s
    s = s.force_encoding(Encoding.default_external) if defined? Encoding
    s.chomp
  end

  def basic_conv(str)
    sm = RDoc::Markup.new
    mock = RDoc::Markup::ToTest.new
    sm.convert(str, mock)
    sm.content
  end

  def line_groups(str, expected)
    m = RDoc::Markup.new
    mock = RDoc::Markup::ToTest.new

    block = m.convert(str, mock)

    unless block == expected then
      rows = (0...([expected.size, block.size].max)).collect{|i|
        [expected[i]||"nil", block[i]||"nil"]
      }
      printf "\n\n%35s %35s\n", "Expected", "Got"
      rows.each { |e,g| printf "%35s %35s\n", e.dump, g.dump }
    end

    assert_equal(expected, block)
  end

  def line_types(str, expected)
    m = RDoc::Markup.new
    mock = RDoc::Markup::ToTest.new
    m.convert(str, mock)
    assert_equal(expected, m.get_line_types.map{|type| type.to_s[0,1]}.join(''))
  end

  def test_parse_bullet
    str = <<-STR
* l1
* l2
    STR

    expected = [
      @RMP::List.new('*', *[
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l1')),
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l2'))])]

    assert_equal expected, @RMP.parse(str)
  end

  def test_parse_bullet_indent
    str = <<-STR
* l1
  * l1.1
* l2
    STR

    expected = [
      @RMP::List.new('*', *[
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l1'),
          @RMP::List.new('*', *[
            @RMP::ListItem.new(nil,
              @RMP::Paragraph.new('l1.1'))])),
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l2'))])]

    assert_equal expected, @RMP.parse(str)
  end

  def test_parse_bullet_paragraph
    str = <<-STR
now is
* l1
* l2
the time
    STR

    expected = [
      @RMP::Paragraph.new('now is'),
      @RMP::List.new('*', *[
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l1')),
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l2')),
      ]),
      @RMP::Paragraph.new('the time'),
    ]

    assert_equal expected, @RMP.parse(str)
  end

  def test_parse_bullet_multiline
    str = <<-STR
* l1
  l1+
* l2
    STR

    expected = [
      @RMP::List.new('*', *[
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l1', 'l1+')),
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l2')),
      ]),
    ]

    assert_equal expected, @RMP.parse(str)
  end

  def test_parse_bullet_indent_verbatim
    str = <<-STR
* l1
  * l1.1
    text
      code
        code

    text
* l2
    STR

    expected = [
      @RMP::List.new('*', *[
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l1'),
          @RMP::List.new('*', *[
            @RMP::ListItem.new(nil,
              @RMP::Paragraph.new('l1.1', 'text'),
              @RMP::Verbatim.new('  ', 'code', "\n",
                                 '    ', 'code', "\n"),
              @RMP::BlankLine.new,
              @RMP::Paragraph.new('text'))])),
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l2'))])]

    assert_equal expected, @RMP.parse(str)
  end

  def test_parse_dash
    str = <<-STR
- one
- two
    STR

    expected = [
      @RMP::List.new('*', *[
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('one')),
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('two'))])]

    assert_equal expected, @RMP.parse(str)
  end

  def test_parse_heading
    str = '= heading one'

    expected = [
      @RMP::Heading.new(1, 'heading one')]

    assert_equal expected, @RMP.parse(str)
  end

  def test_parse_heading_three
    str = '=== heading three'

    expected = [
      @RMP::Heading.new(3, 'heading three')]

    assert_equal expected, @RMP.parse(str)
  end

  def test_parse_label
    str = <<-STR
[one] item one
[two] item two
    STR

    expected = [
      @RMP::List.new('label', *[
        @RMP::ListItem.new('one',
          @RMP::Paragraph.new('item one')),
        @RMP::ListItem.new('two',
          @RMP::Paragraph.new('item two'))])]

    assert_equal expected, @RMP.parse(str)

    line_groups(str,
                [ "L1: ListStart\n",
                  "L1: LABELED ListItem\none: item one",
                  "L1: LABELED ListItem\ntwo: item two",
                  "L1: ListEnd\n" ])
  end

  def test_parse_label_bullet
    str = <<-STR
[cat] l1
      * l1.1
[dog] l2
    STR

    expected = [
      @RMP::List.new('label', *[
        @RMP::ListItem.new('cat',
          @RMP::Paragraph.new('l1'),
          @RMP::List.new('*', *[
            @RMP::ListItem.new(nil,
              @RMP::Paragraph.new('l1.1'))])),
        @RMP::ListItem.new('dog',
          @RMP::Paragraph.new('l2'))])]

    assert_equal expected, @RMP.parse(str)
  end

  def test_parse_label_multiline
    str = <<-STR
[cat] l1
      continuation
[dog] l2
    STR

    expected = [
      @RMP::List.new('label', *[
        @RMP::ListItem.new('cat',
          @RMP::Paragraph.new('l1', 'continuation')),
        @RMP::ListItem.new('dog',
          @RMP::Paragraph.new('l2'))])]

    assert_equal expected, @RMP.parse(str)
  end

  def test_parse_label_newline
    str = <<-STR
[one]
  item one
[two]
  item two
    STR

    expected = [
      @RMP::List.new('label', *[
        @RMP::ListItem.new('one',
          @RMP::Paragraph.new('item one')),
        @RMP::ListItem.new('two',
          @RMP::Paragraph.new('item two')),
    ])]

    assert_equal expected, @RMP.parse(str)

    line_groups(str,
                [ "L1: ListStart\n",
                  "L1: LABELED ListItem\none: item one",
                  "L1: LABELED ListItem\ntwo: item two",
                  "L1: ListEnd\n" ])
  end

  def test_parse_lalpha
    str = <<-STR
a. l1
b. l2
    STR

    expected = [
      @RMP::List.new('a', *[
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l1')),
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l2'))])]

    assert_equal expected, @RMP.parse(str)
  end

  def test_parse_lalpha_ualpha
    str = <<-STR
a. l1
b. l2
A. l3
A. l4
    STR

    expected = [
      @RMP::List.new('a', *[
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l1')),
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l2'))]),
      @RMP::List.new('A', *[
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l3')),
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l4'))])]

    assert_equal expected, @RMP.parse(str)
  end

  def test_parse_list_verbatim
    str = <<-STR
* one
    verb1
    verb2
* two
    STR

    expected = [
      @RMP::List.new('*', *[
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('one'),
          @RMP::Verbatim.new('  ', 'verb1', "\n",
                             '  ', 'verb2', "\n")),
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('two'))])]

    assert_equal expected, @RMP.parse(str)

    line_groups(str,
                [ "L1: ListStart\n",
                  "L1: BULLET ListItem\none",
                  "L1: Verbatim\n  verb1\n  verb2\n",
                  "L1: BULLET ListItem\ntwo",
                  "L1: ListEnd\n" ])
  end

  def test_parse_lists
    str = <<-STR
now is
* l1
1. n1
2. n2
* l2
the time
    STR

    expected = [
      @RMP::Paragraph.new('now is'),
      @RMP::List.new('*', *[
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l1'))]),
      @RMP::List.new('1', *[
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('n1')),
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('n2'))]),
      @RMP::List.new('*', *[
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l2'))]),
      @RMP::Paragraph.new('the time')]

    assert_equal expected, @RMP.parse(str)
  end

  def test_parse_note
    str = <<-STR
one:: item one
two:: item two
    STR

    expected = [
      @RMP::List.new('note', *[
        @RMP::ListItem.new('one',
          @RMP::Paragraph.new('item one')),
        @RMP::ListItem.new('two',
          @RMP::Paragraph.new('item two'))])]

    assert_equal expected, @RMP.parse(str)
  end

  def test_parse_number_bullet
    str = <<-STR
1. l1
   * l1.1
2. l2
    STR

    expected = [
      @RMP::List.new('1', *[
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l1'),
          @RMP::List.new('*', *[
            @RMP::ListItem.new(nil,
              @RMP::Paragraph.new('l1.1'))])),
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l2'))])]

    assert_equal expected, @RMP.parse(str)
  end

  def test_parse_paragraph
    str = <<-STR
now is the time

for all good men
    STR

    expected = [
      @RMP::Paragraph.new('now is the time'),
      @RMP::BlankLine.new,
      @RMP::Paragraph.new('for all good men')]
    assert_equal expected, @RMP.parse(str)
  end

  def test_parse_paragraph_multiline
    str = "now is the time\nfor all good men"

    expected = @RMP::Paragraph.new 'now is the time for all good men'
    assert_equal [expected], @RMP.parse(str)
  end

  def test_parse_paragraph_verbatim
    str = <<-STR
now is the time
  code _line_ here
for all good men
    STR

    expected = [
      @RMP::Paragraph.new('now is the time'),
      @RMP::Verbatim.new('  ', 'code _line_ here', "\n"),
      @RMP::Paragraph.new('for all good men'),
    ]
    assert_equal expected, @RMP.parse(str)
  end

  def test_parse_ualpha
    str = <<-STR
A. l1
B. l2
    STR

    expected = [
      @RMP::List.new('A', *[
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l1')),
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l2'))])]

    assert_equal expected, @RMP.parse(str)
  end

  def test_parse_verbatim_heading
    str = <<-STR
text
   ===   heading three
    STR

    expected = [
      @RMP::Paragraph.new('text'),
      @RMP::Verbatim.new('   ', '===', '   ', 'heading three', "\n")]

    assert_equal expected, @RMP.parse(str)
  end

  def test_parse_verbatim_heading2
    str = "text\n   code\n=== heading three"

    expected = [
      @RMP::Paragraph.new('text'),
      @RMP::Verbatim.new('   ', 'code', "\n"),
      @RMP::Heading.new(3, 'heading three')]

    assert_equal expected, @RMP.parse(str)
  end

  def test_parse_verbatim_markup_example
    str = <<-STR
text
   code
   === heading three
    STR

    expected = [
      @RMP::Paragraph.new('text'),
      @RMP::Verbatim.new('   ', 'code', "\n",
                         '   ', '===', ' ', 'heading three', "\n")]

    assert_equal expected, @RMP.parse(str)
  end

  def test_parse_verbatim_multilevel
    str = <<-STR
now is the time
  code
 more code
for all good men
    STR

    expected = [
      @RMP::Paragraph.new('now is the time'),
      @RMP::Verbatim.new('  ', 'code', "\n",
                         ' ', 'more code', "\n"),
      @RMP::Paragraph.new('for all good men'),
    ]

    assert_equal expected, @RMP.parse(str)
  end

  def test_tokenize_bullet
    str = <<-STR
* l1
    STR

    expected = [
      [:BULLET,  '*',    0, 0],
      [:SPACE,   2,      0, 0],
      [:TEXT,    'l1',   2, 0],
      [:NEWLINE, "\n",   4, 0],
    ]

    assert_equal expected, @RMP.tokenize(str)
  end

  def test_tokenize_bullet_indent
    str = <<-STR
* l1
  * l1.1
    STR

    expected = [
      [:BULLET,  '*',    0, 0],
      [:SPACE,   2,      0, 0],
      [:TEXT,    'l1',   2, 0],
      [:NEWLINE, "\n",   4, 0],
      [:INDENT,  2,      0, 1],
      [:BULLET,  '*',    2, 1],
      [:SPACE,   2,      2, 1],
      [:TEXT,    'l1.1', 4, 1],
      [:NEWLINE, "\n",   8, 1],
    ]

    assert_equal expected, @RMP.tokenize(str)
  end

  def test_tokenize_label
    str = <<-STR
[cat] l1
[dog] l1.1
    STR

    expected = [
      [:LABEL,   'cat',   0, 0],
      [:SPACE,   6,       0, 0],
      [:TEXT,    'l1',    6, 0],
      [:NEWLINE, "\n",    8, 0],
      [:LABEL,   'dog',   0, 1],
      [:SPACE,   6,       0, 1],
      [:TEXT,    'l1.1',  6, 1],
      [:NEWLINE, "\n",   10, 1],
    ]

    assert_equal expected, @RMP.tokenize(str)
  end

  def test_tokenize_lalpha
    str = <<-STR
a. l1
b. l1.1
    STR

    expected = [
      [:LALPHA,  'a',    0, 0],
      [:SPACE,   3,      0, 0],
      [:TEXT,    'l1',   3, 0],
      [:NEWLINE, "\n",   5, 0],
      [:LALPHA,  'a',    0, 1],
      [:SPACE,   3,      0, 1],
      [:TEXT,    'l1.1', 3, 1],
      [:NEWLINE, "\n",   7, 1],
    ]

    assert_equal expected, @RMP.tokenize(str)
  end

  def test_tokenize_note
    str = <<-STR
cat:: l1
dog:: l1.1
    STR

    expected = [
      [:NOTE,    'cat',   0, 0],
      [:SPACE,   6,       0, 0],
      [:TEXT,    'l1',    6, 0],
      [:NEWLINE, "\n",    8, 0],
      [:NOTE,    'dog',   0, 1],
      [:SPACE,   6,       0, 1],
      [:TEXT,    'l1.1',  6, 1],
      [:NEWLINE, "\n",   10, 1],
    ]

    assert_equal expected, @RMP.tokenize(str)
  end

  def test_tokenize_number
    str = <<-STR
1. l1
2. l1.1
    STR

    expected = [
      [:NUMBER,  '1',    0, 0],
      [:SPACE,   3,      0, 0],
      [:TEXT,    'l1',   3, 0],
      [:NEWLINE, "\n",   5, 0],
      [:NUMBER,  '1',    0, 1],
      [:SPACE,   3,      0, 1],
      [:TEXT,    'l1.1', 3, 1],
      [:NEWLINE, "\n",   7, 1],
    ]

    assert_equal expected, @RMP.tokenize(str)
  end

  def test_tokenize_paragraphs
    str = <<-STR
now is
the time

for all
    STR

    expected = [
      [:TEXT,    'now is',   0, 0],
      [:NEWLINE, "\n",       6, 0],
      [:TEXT,    'the time', 0, 1],
      [:NEWLINE, "\n",       8, 1],
      [:NEWLINE, "\n",       0, 2],
      [:TEXT,    'for all',  0, 3],
      [:NEWLINE, "\n",       7, 3],
    ]

    assert_equal expected, @RMP.tokenize(str)
  end

  def test_tokenize_tabs
    str = "hello\n  dave"

    expected = [
      [:TEXT, 'hello', 0, 0],
      [:NEWLINE, "\n", 5, 0],
      [:INDENT, 2,     0, 1],
      [:TEXT, 'dave',  2, 1],
    ]

    assert_equal expected, @RMP.tokenize(str), 'spaces'

    str = "hello\n\tdave"

    expected = [
      [:TEXT, 'hello', 0, 0],
      [:NEWLINE, "\n", 5, 0],
      [:INDENT, 8,     0, 1],
      [:TEXT, 'dave',  8, 1],
    ]

    assert_equal expected, @RMP.tokenize(str), 'tab'

    str = "hello\n \tdave"

    expected = [
      [:TEXT, 'hello', 0, 0],
      [:NEWLINE, "\n", 5, 0],
      [:INDENT, 8,     0, 1],
      [:TEXT, 'dave',  8, 1],
    ]

    assert_equal expected, @RMP.tokenize(str), '1 space tab'

    str = "hello\n  \tdave"

    expected = [
      [:TEXT, 'hello', 0, 0],
      [:NEWLINE, "\n", 5, 0],
      [:INDENT, 8,     0, 1],
      [:TEXT, 'dave',  8, 1],
    ]

    assert_equal expected, @RMP.tokenize(str), '2 space tab'

    str = "hello\n   \tdave"

    expected = [
      [:TEXT, 'hello', 0, 0],
      [:NEWLINE, "\n", 5, 0],
      [:INDENT, 8,     0, 1],
      [:TEXT, 'dave',  8, 1],
    ]

    assert_equal expected, @RMP.tokenize(str), '3 space tab'

    str = "hello\n    \tdave"

    expected = [
      [:TEXT, 'hello', 0, 0],
      [:NEWLINE, "\n", 5, 0],
      [:INDENT, 8,     0, 1],
      [:TEXT, 'dave',  8, 1],
    ]

    assert_equal expected, @RMP.tokenize(str), '4 space tab'

    str = "hello\n     \tdave"

    expected = [
      [:TEXT, 'hello', 0, 0],
      [:NEWLINE, "\n", 5, 0],
      [:INDENT, 8,     0, 1],
      [:TEXT, 'dave',  8, 1],
    ]

    assert_equal expected, @RMP.tokenize(str), '5 space tab'

    str = "hello\n      \tdave"

    expected = [
      [:TEXT, 'hello', 0, 0],
      [:NEWLINE, "\n", 5, 0],
      [:INDENT, 8,     0, 1],
      [:TEXT, 'dave',  8, 1],
    ]

    assert_equal expected, @RMP.tokenize(str), '6 space tab'

    str = "hello\n       \tdave"

    expected = [
      [:TEXT, 'hello', 0, 0],
      [:NEWLINE, "\n", 5, 0],
      [:INDENT, 8,     0, 1],
      [:TEXT, 'dave',  8, 1],
    ]

    assert_equal expected, @RMP.tokenize(str), '7 space tab'

    str = "hello\n        \tdave"

    expected = [
      [:TEXT, 'hello',  0, 0],
      [:NEWLINE, "\n",  5, 0],
      [:INDENT, 16,     0, 1],
      [:TEXT, 'dave',  16, 1],
    ]

    assert_equal expected, @RMP.tokenize(str), '8 space tab'

    str = ".\t\t."

    expected = [
      [:TEXT, '.               .',      0, 0],
    ]

    assert_equal expected, @RMP.tokenize(str), 'dot tab tab dot'
  end

  def test_tokenize_ualpha
    str = <<-STR
A. l1
B. l1.1
    STR

    expected = [
      [:UALPHA,  'A',    0, 0],
      [:SPACE,   3,      0, 0],
      [:TEXT,    'l1',   3, 0],
      [:NEWLINE, "\n",   5, 0],
      [:UALPHA,  'A',    0, 1],
      [:SPACE,   3,      0, 1],
      [:TEXT,    'l1.1', 3, 1],
      [:NEWLINE, "\n",   7, 1],
    ]

    assert_equal expected, @RMP.tokenize(str)
  end

  def test_tokenize_verbatim_heading
    str = <<-STR
Example heading:

   === heading three
    STR

    expected = [
      [:TEXT,    'Example heading:',  0, 0],
      [:NEWLINE, "\n",               16, 0],
      [:NEWLINE, "\n",                0, 1],
      [:INDENT,  3,                   0, 2],
      [:HEADER,  3,                   3, 2],
      [:TEXT,    'heading three',     7, 2],
      [:NEWLINE, "\n",               20, 2],
    ]

    assert_equal expected, @RMP.tokenize(str)
  end

  def test_verbatim_merge
    str = %{\
       now is
          code
       the time}

    line_groups(str,
                [ "L0: Paragraph\nnow is",
                  "L0: Verbatim\n   code\n",
                  "L0: Paragraph\nthe time"
                ])


    str = %{\
       now is
          code
          code1
       the time}

    line_groups(str,
                [ "L0: Paragraph\nnow is",
                  "L0: Verbatim\n   code\n   code1\n",
                  "L0: Paragraph\nthe time"
                ])


    str = %{\
       now is
          code

          code1
       the time}

    line_groups(str,
                [ "L0: Paragraph\nnow is",
                  "L0: Verbatim\n   code\n\n   code1\n",
                  "L0: Paragraph\nthe time"
                ])


    str = %{\
       now is
          code

          code1

       the time}

    line_groups(str,
                [ "L0: Paragraph\nnow is",
                  "L0: Verbatim\n   code\n\n   code1\n",
                  "L0: Paragraph\nthe time"
                ])


    str = %{\
       now is
          code

          code1

          code2
       the time}

    line_groups(str,
                [ "L0: Paragraph\nnow is",
                  "L0: Verbatim\n   code\n\n   code1\n\n   code2\n",
                  "L0: Paragraph\nthe time"
                ])


    # Folds multiple blank lines
    str = %{\
       now is
          code


          code1

       the time}

    line_groups(str,
                [ "L0: Paragraph\nnow is",
                  "L0: Verbatim\n   code\n\n   code1\n",
                  "L0: Paragraph\nthe time"
                ])


  end

  def test_whitespace
    assert_equal("hello", basic_conv("hello"))
    assert_equal("hello", basic_conv(" hello "))
    assert_equal("hello", basic_conv(" \t \t hello\t\t"))

    assert_equal("1\n 2\n  3", basic_conv("1\n 2\n  3"))
    assert_equal("1\n 2\n  3", basic_conv("  1\n   2\n    3"))

    assert_equal("1\n 2\n  3\n1\n 2", basic_conv("1\n 2\n  3\n1\n 2"))
    assert_equal("1\n 2\n  3\n1\n 2", basic_conv("  1\n   2\n    3\n  1\n   2"))

    assert_equal("1\n 2\n\n  3", basic_conv("  1\n   2\n\n    3"))
  end

end

