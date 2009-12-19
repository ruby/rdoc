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

  def test_build_heading
    parser = @RMP.new

    parser.tokens.replace [
      [:TEXT,    'heading three',  4, 0],
      [:NEWLINE, "\n",            17, 0],
    ]

    assert_equal @RMP::Heading.new(3, 'heading three'), parser.build_heading(3)
  end

  def test_parse_bullet
    str = <<-STR
* l1
* l2
    STR

    expected = [
      @RMP::List.new(:BULLET, *[
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l1')),
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l2'))])]

    assert_equal expected, @RMP.parse(str).parts
  end

  def test_parse_bullet_heading
    str = <<-STR
* = l1
    STR

    expected = [
      @RMP::List.new(:BULLET, *[
        @RMP::ListItem.new(nil,
          @RMP::Heading.new(1, 'l1'))])]

    assert_equal expected, @RMP.parse(str).parts
  end

  def test_parse_bullet_indent
    str = <<-STR
* l1
  * l1.1
* l2
    STR

    expected = [
      @RMP::List.new(:BULLET, *[
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l1'),
          @RMP::List.new(:BULLET, *[
            @RMP::ListItem.new(nil,
              @RMP::Paragraph.new('l1.1'))])),
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l2'))])]

    assert_equal expected, @RMP.parse(str).parts
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
      @RMP::List.new(:BULLET, *[
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l1')),
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l2')),
      ]),
      @RMP::Paragraph.new('the time'),
    ]

    assert_equal expected, @RMP.parse(str).parts
  end

  def test_parse_bullet_multiline
    str = <<-STR
* l1
  l1+
* l2
    STR

    expected = [
      @RMP::List.new(:BULLET, *[
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l1', 'l1+')),
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l2')),
      ]),
    ]

    assert_equal expected, @RMP.parse(str).parts
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
      @RMP::List.new(:BULLET, *[
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l1'),
          @RMP::List.new(:BULLET, *[
            @RMP::ListItem.new(nil,
              @RMP::Paragraph.new('l1.1', 'text'),
              @RMP::Verbatim.new('  ', 'code', "\n",
                                 '    ', 'code', "\n"),
              @RMP::Paragraph.new('text'))])),
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l2'))])]

    assert_equal expected, @RMP.parse(str).parts
  end

  def test_parse_dash
    str = <<-STR
- one
- two
    STR

    expected = [
      @RMP::List.new(:BULLET, *[
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('one')),
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('two'))])]

    assert_equal expected, @RMP.parse(str).parts
  end

  def test_parse_heading
    str = '= heading one'

    expected = [
      @RMP::Heading.new(1, 'heading one')]

    assert_equal expected, @RMP.parse(str).parts
  end

  def test_parse_heading_three
    str = '=== heading three'

    expected = [
      @RMP::Heading.new(3, 'heading three')]

    assert_equal expected, @RMP.parse(str).parts
  end

  def test_parse_label
    str = <<-STR
[one] item one
[two] item two
    STR

    expected = [
      @RMP::List.new(:LABEL, *[
        @RMP::ListItem.new('one',
          @RMP::Paragraph.new('item one')),
        @RMP::ListItem.new('two',
          @RMP::Paragraph.new('item two'))])]

    assert_equal expected, @RMP.parse(str).parts
  end

  def test_parse_label_bullet
    str = <<-STR
[cat] l1
      * l1.1
[dog] l2
    STR

    expected = [
      @RMP::List.new(:LABEL, *[
        @RMP::ListItem.new('cat',
          @RMP::Paragraph.new('l1'),
          @RMP::List.new(:BULLET, *[
            @RMP::ListItem.new(nil,
              @RMP::Paragraph.new('l1.1'))])),
        @RMP::ListItem.new('dog',
          @RMP::Paragraph.new('l2'))])]

    assert_equal expected, @RMP.parse(str).parts
  end

  def test_parse_label_multiline
    str = <<-STR
[cat] l1
      continuation
[dog] l2
    STR

    expected = [
      @RMP::List.new(:LABEL, *[
        @RMP::ListItem.new('cat',
          @RMP::Paragraph.new('l1', 'continuation')),
        @RMP::ListItem.new('dog',
          @RMP::Paragraph.new('l2'))])]

    assert_equal expected, @RMP.parse(str).parts
  end

  def test_parse_label_newline
    str = <<-STR
[one]
  item one
[two]
  item two
    STR

    expected = [
      @RMP::List.new(:LABEL, *[
        @RMP::ListItem.new('one',
          @RMP::Paragraph.new('item one')),
        @RMP::ListItem.new('two',
          @RMP::Paragraph.new('item two')),
    ])]

    assert_equal expected, @RMP.parse(str).parts
  end

  def test_parse_lalpha
    str = <<-STR
a. l1
b. l2
    STR

    expected = [
      @RMP::List.new(:LALPHA, *[
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l1')),
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l2'))])]

    assert_equal expected, @RMP.parse(str).parts
  end

  def test_parse_lalpha_ualpha
    str = <<-STR
a. l1
b. l2
A. l3
A. l4
    STR

    expected = [
      @RMP::List.new(:LALPHA, *[
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l1')),
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l2'))]),
      @RMP::List.new(:UALPHA, *[
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l3')),
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l4'))])]

    assert_equal expected, @RMP.parse(str).parts
  end

  def test_parse_list_verbatim
    str = <<-STR
* one
    verb1
    verb2
* two
    STR

    expected = [
      @RMP::List.new(:BULLET, *[
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('one'),
          @RMP::Verbatim.new('  ', 'verb1', "\n",
                             '  ', 'verb2', "\n")),
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('two'))])]

    assert_equal expected, @RMP.parse(str).parts
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
      @RMP::List.new(:BULLET, *[
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l1'))]),
      @RMP::List.new(:NUMBER, *[
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('n1')),
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('n2'))]),
      @RMP::List.new(:BULLET, *[
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l2'))]),
      @RMP::Paragraph.new('the time')]

    assert_equal expected, @RMP.parse(str).parts
  end

  def test_parse_note
    str = <<-STR
one:: item one
two:: item two
    STR

    expected = [
      @RMP::List.new(:NOTE, *[
        @RMP::ListItem.new('one',
          @RMP::Paragraph.new('item one')),
        @RMP::ListItem.new('two',
          @RMP::Paragraph.new('item two'))])]

    assert_equal expected, @RMP.parse(str).parts
  end

  def test_parse_note_empty
    str = <<-STR
one::
two::
    STR

    expected = [
      @RMP::List.new(:NOTE, *[
        @RMP::ListItem.new('one',
          @RMP::BlankLine.new),
        @RMP::ListItem.new('two',
          @RMP::BlankLine.new)])]

    assert_equal expected, @RMP.parse(str).parts
  end

  def test_parse_number_bullet
    str = <<-STR
1. l1
   * l1.1
2. l2
    STR

    expected = [
      @RMP::List.new(:NUMBER, *[
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l1'),
          @RMP::List.new(:BULLET, *[
            @RMP::ListItem.new(nil,
              @RMP::Paragraph.new('l1.1'))])),
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l2'))])]

    assert_equal expected, @RMP.parse(str).parts
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
    assert_equal expected, @RMP.parse(str).parts
  end

  def test_parse_paragraph_multiline
    str = "now is the time\nfor all good men"

    expected = @RMP::Paragraph.new 'now is the time for all good men'
    assert_equal [expected], @RMP.parse(str).parts
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
    assert_equal expected, @RMP.parse(str).parts
  end

  def test_parse_ualpha
    str = <<-STR
A. l1
B. l2
    STR

    expected = [
      @RMP::List.new(:UALPHA, *[
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l1')),
        @RMP::ListItem.new(nil,
          @RMP::Paragraph.new('l2'))])]

    assert_equal expected, @RMP.parse(str).parts
  end

  def test_parse_verbatim
    str = <<-STR
now is
   code
the time
    STR

    expected = [
      @RMP::Paragraph.new('now is'),
      @RMP::Verbatim.new('   ', 'code', "\n"),
      @RMP::Paragraph.new('the time'),
    ]

    assert_equal expected, @RMP.parse(str).parts
  end

  def test_parse_verbatim_bullet
    str = <<-STR
  * blah
    STR

    expected = [
      @RMP::Verbatim.new('  ', '*', ' ', 'blah', "\n")]

    assert_equal expected, @RMP.parse(str).parts
  end

  def test_parse_verbatim_fold
    str = <<-STR
now is
   code


   code1

the time
    STR

    expected = [
      @RMP::Paragraph.new('now is'),
      @RMP::Verbatim.new('   ', 'code',  "\n",
                         "\n",
                         '   ', 'code1', "\n"),
      @RMP::Paragraph.new('the time'),
    ]

    assert_equal expected, @RMP.parse(str).parts
  end

  def test_parse_verbatim_heading
    str = <<-STR
text
   ===   heading three
    STR

    expected = [
      @RMP::Paragraph.new('text'),
      @RMP::Verbatim.new('   ', '===', '   ', 'heading three', "\n")]

    assert_equal expected, @RMP.parse(str).parts
  end

  def test_parse_verbatim_heading2
    str = "text\n   code\n=== heading three"

    expected = [
      @RMP::Paragraph.new('text'),
      @RMP::Verbatim.new('   ', 'code', "\n"),
      @RMP::Heading.new(3, 'heading three')]

    assert_equal expected, @RMP.parse(str).parts
  end

  def test_parse_verbatim_label
    str = <<-STR
  [blah] blah
    STR

    expected = [
      @RMP::Verbatim.new('  ', '[blah]', ' ', 'blah', "\n")]

    assert_equal expected, @RMP.parse(str).parts
  end

  def test_parse_verbatim_lalpha
    str = <<-STR
  b. blah
    STR

    expected = [
      @RMP::Verbatim.new('  ', 'b.', ' ', 'blah', "\n")]

    assert_equal expected, @RMP.parse(str).parts
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

    assert_equal expected, @RMP.parse(str).parts
  end

  def test_parse_verbatim_merge
    str = <<-STR
now is
   code

   code1
the time
    STR

    expected = [
      @RMP::Paragraph.new('now is'),
      @RMP::Verbatim.new('   ', 'code',  "\n",
                         "\n",
                         '   ', 'code1', "\n"),
      @RMP::Paragraph.new('the time'),
    ]

    assert_equal expected, @RMP.parse(str).parts
  end

  def test_parse_verbatim_merge2
    str = <<-STR
now is
   code

   code1

   code2
the time
    STR

    expected = [
      @RMP::Paragraph.new('now is'),
      @RMP::Verbatim.new('   ', 'code',  "\n",
                         "\n",
                         '   ', 'code1', "\n",
                         "\n",
                         '   ', 'code2', "\n"),
      @RMP::Paragraph.new('the time'),
    ]

    assert_equal expected, @RMP.parse(str).parts
  end

  def test_parse_verbatim_multiline
    str = <<-STR
now is
   code
   code1
the time
    STR

    expected = [
      @RMP::Paragraph.new('now is'),
      @RMP::Verbatim.new('   ', 'code',  "\n",
                         '   ', 'code1', "\n"),
      @RMP::Paragraph.new('the time'),
    ]

    assert_equal expected, @RMP.parse(str).parts
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

    assert_equal expected, @RMP.parse(str).parts
  end

  def test_parse_verbatim_note
    str = <<-STR
  blah:: blah
    STR

    expected = [
      @RMP::Verbatim.new('  ', 'blah::', ' ', 'blah', "\n")]

    assert_equal expected, @RMP.parse(str).parts
  end

  def test_parse_verbatim_number
    str = <<-STR
  2. blah
    STR

    expected = [
      @RMP::Verbatim.new('  ', '2.', ' ', 'blah', "\n")]

    assert_equal expected, @RMP.parse(str).parts
  end

  def test_parse_verbatim_rule
    str = <<-STR
text

  --- lib/blah.rb.orig
  +++ lib/blah.rb
    STR

    expected = [
      @RMP::Paragraph.new('text'),
      @RMP::BlankLine.new,
      @RMP::Verbatim.new('  ', '---', ' ', 'lib/blah.rb.orig', "\n",
                         '  ', '+++', ' ', 'lib/blah.rb',      "\n")]

    assert_equal expected, @RMP.parse(str).parts
  end

  def test_parse_verbatim_trim
    str = <<-STR
now is
   code

   code1

the time
    STR

    expected = [
      @RMP::Paragraph.new('now is'),
      @RMP::Verbatim.new('   ', 'code',  "\n",
                         "\n",
                         '   ', 'code1', "\n"),
      @RMP::Paragraph.new('the time'),
    ]

    assert_equal expected, @RMP.parse(str).parts
  end

  def test_parse_verbatim_ualpha
    str = <<-STR
  B. blah
    STR

    expected = [
      @RMP::Verbatim.new('  ', 'B.', ' ', 'blah', "\n")]

    assert_equal expected, @RMP.parse(str).parts
  end

  def test_parse_whitespace
    expected = [
      @RMP::Paragraph.new('hello'),
    ]

    assert_equal expected, @RMP.parse('hello').parts

    expected = [
      @RMP::Verbatim.new(' ', 'hello '),
    ]

    assert_equal expected, @RMP.parse(' hello ').parts

    expected = [
      @RMP::Verbatim.new('                 ', 'hello          '),
    ]

    assert_equal expected, @RMP.parse("                 hello          ").parts

    expected = [
      @RMP::Paragraph.new('1'),
      @RMP::Verbatim.new(' ', '2', "\n",
                         '  ', '3'),
    ]

    assert_equal expected, @RMP.parse("1\n 2\n  3").parts

    expected = [
      @RMP::Verbatim.new('  ', '1', "\n",
                         '   ', '2', "\n",
                         '    ', '3'),
    ]

    assert_equal expected, @RMP.parse("  1\n   2\n    3").parts

    expected = [
      @RMP::Paragraph.new('1'),
      @RMP::Verbatim.new(' ', '2', "\n",
                         '  ', '3', "\n"),
      @RMP::Paragraph.new('1'),
      @RMP::Verbatim.new(' ', '2'),
    ]

    assert_equal expected, @RMP.parse("1\n 2\n  3\n1\n 2").parts

    expected = [
      @RMP::Verbatim.new('  ', '1', "\n",
                         '   ', '2', "\n",
                         '    ', '3', "\n",
                         '  ', '1', "\n",
                         '   ', '2'),
    ]

    assert_equal expected, @RMP.parse("  1\n   2\n    3\n  1\n   2").parts

    expected = [
      @RMP::Verbatim.new('  ', '1', "\n",
                         '   ', '2', "\n",
                         "\n",
                         '    ', '3'),
    ]

    assert_equal expected, @RMP.parse("  1\n   2\n\n    3").parts
  end

  def test_tokenize_bullet
    str = <<-STR
* l1
    STR

    expected = [
      [:BULLET,  :BULLET, 0, 0],
      [:SPACE,   2,       0, 0],
      [:TEXT,    'l1',    2, 0],
      [:NEWLINE, "\n",    4, 0],
    ]

    assert_equal expected, @RMP.tokenize(str)
  end

  def test_tokenize_bullet_indent
    str = <<-STR
* l1
  * l1.1
    STR

    expected = [
      [:BULLET,  :BULLET, 0, 0],
      [:SPACE,   2,       0, 0],
      [:TEXT,    'l1',    2, 0],
      [:NEWLINE, "\n",    4, 0],
      [:INDENT,  2,       0, 1],
      [:BULLET,  :BULLET, 2, 1],
      [:SPACE,   2,       2, 1],
      [:TEXT,    'l1.1',  4, 1],
      [:NEWLINE, "\n",    8, 1],
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

  def test_tokenize_label_note
    str = <<-STR
[label]
  note::
    STR

    expected = [
      [:LABEL,   'label', 0, 0],
      [:SPACE,   7,       0, 0],
      [:NEWLINE, "\n",    7, 0],
      [:INDENT,  2,       0, 1],
      [:NOTE,    'note',  2, 1],
      [:SPACE,   6,       2, 1],
      [:NEWLINE, "\n",    8, 1],
    ]

    assert_equal expected, @RMP.tokenize(str)
  end

  def test_tokenize_lalpha
    str = <<-STR
a. l1
b. l1.1
    STR

    expected = [
      [:LALPHA,  'a',     0, 0],
      [:SPACE,   3,       0, 0],
      [:TEXT,    'l1',    3, 0],
      [:NEWLINE, "\n",    5, 0],
      [:LALPHA,  'b',     0, 1],
      [:SPACE,   3,       0, 1],
      [:TEXT,    'l1.1',  3, 1],
      [:NEWLINE, "\n",    7, 1],
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

  def test_tokenize_note_empty
    str = <<-STR
cat::
dog::
    STR

    expected = [
      [:NOTE,    'cat', 0, 0],
      [:SPACE,   5,     0, 0],
      [:NEWLINE, "\n",  5, 0],
      [:NOTE,    'dog', 0, 1],
      [:SPACE,   5,     0, 1],
      [:NEWLINE, "\n",  5, 1],
    ]

    assert_equal expected, @RMP.tokenize(str)
  end

  def test_tokenize_note_not
    str = <<-STR
Cat::Dog
    STR

    expected = [
      [:TEXT,    'Cat::Dog', 0, 0],
      [:NEWLINE, "\n",       8, 0],
    ]

    assert_equal expected, @RMP.tokenize(str)
  end

  def test_tokenize_number
    str = <<-STR
1. l1
2. l1.1
    STR

    expected = [
      [:NUMBER,  '1',     0, 0],
      [:SPACE,   3,       0, 0],
      [:TEXT,    'l1',    3, 0],
      [:NEWLINE, "\n",    5, 0],
      [:NUMBER,  '2',     0, 1],
      [:SPACE,   3,       0, 1],
      [:TEXT,    'l1.1',  3, 1],
      [:NEWLINE, "\n",    7, 1],
    ]

    assert_equal expected, @RMP.tokenize(str)
  end

  def test_tokenize_number_period
    str = <<-STR
1. blah blah blah
   l.
2. blah blah blah blah
   d.
    STR

    expected = [
      [:NUMBER,  "1",                    0, 0],
      [:SPACE,   3,                      0, 0],
      [:TEXT,    "blah blah blah",       3, 0],
      [:NEWLINE, "\n",                  17, 0],

      [:INDENT,  3,                      0, 1],
      [:TEXT,    "l.",                   3, 1],
      [:NEWLINE, "\n",                   5, 1],

      [:NUMBER,  "2",                    0, 2],
      [:SPACE,   3,                      0, 2],
      [:TEXT,    "blah blah blah blah",  3, 2],
      [:NEWLINE, "\n",                  22, 2],

      [:INDENT,  3,                      0, 3],
      [:TEXT,    "d.",                   3, 3],
      [:NEWLINE, "\n",                   5, 3]
    ]

    assert_equal expected, @RMP.tokenize(str)
  end

  def test_tokenize_number_period_continue
    str = <<-STR
1. blah blah blah
   l.  more stuff
2. blah blah blah blah
   d. other stuff
    STR

    expected = [
      [:NUMBER,  "1",                    0, 0],
      [:SPACE,   3,                      0, 0],
      [:TEXT,    "blah blah blah",       3, 0],
      [:NEWLINE, "\n",                  17, 0],

      [:INDENT,  3,                      0, 1],
      [:LALPHA,  "l",                    3, 1],
      [:SPACE,   4,                      3, 1],
      [:TEXT,    "more stuff",           7, 1],
      [:NEWLINE, "\n",                  17, 1],

      [:NUMBER,  "2",                    0, 2],
      [:SPACE,   3,                      0, 2],
      [:TEXT,    "blah blah blah blah",  3, 2],
      [:NEWLINE, "\n",                  22, 2],

      [:INDENT,  3,                      0, 3],
      [:LALPHA,  "d",                    3, 3],
      [:SPACE,   3,                      3, 3],
      [:TEXT,    "other stuff",          6, 3],
      [:NEWLINE, "\n",                  17, 3]
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

  def test_tokenize_ualpha
    str = <<-STR
A. l1
B. l1.1
    STR

    expected = [
      [:UALPHA,  'A',     0, 0],
      [:SPACE,   3,       0, 0],
      [:TEXT,    'l1',    3, 0],
      [:NEWLINE, "\n",    5, 0],
      [:UALPHA,  'B',     0, 1],
      [:SPACE,   3,       0, 1],
      [:TEXT,    'l1.1',  3, 1],
      [:NEWLINE, "\n",    7, 1],
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

  # HACK move to Verbatim test case
  def test_verbatim_normalize
    v = @RMP::Verbatim.new '  ', 'foo', "\n", "\n", "\n", '  ', 'bar', "\n"

    v.normalize

    assert_equal ['  ', 'foo', "\n", "\n", '  ', 'bar', "\n"], v.parts

    v = @RMP::Verbatim.new '  ', 'foo', "\n", "\n"

    v.normalize

    assert_equal ['  ', 'foo', "\n"], v.parts
  end

end

