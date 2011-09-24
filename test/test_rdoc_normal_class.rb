require File.expand_path '../xref_test_case', __FILE__

class TestRDocNormalClass < XrefTestCase

  def test_ancestors_class
    top_level = RDoc::TopLevel.new 'file.rb'
    klass = top_level.add_class RDoc::NormalClass, 'Klass'
    incl = RDoc::Include.new 'Incl', ''

    sub_klass = klass.add_class RDoc::NormalClass, 'SubClass', 'Klass'
    sub_klass.add_include incl

    assert_equal [incl.name, klass], sub_klass.ancestors
  end

  def test_definition
    c = RDoc::NormalClass.new 'C'

    assert_equal 'class C', c.definition
  end

  def test_search_record
    @c2_c3.comment = 'This is a comment.'

    expected = [
      'C2::C3',
      '',
      'C2/C3.html',
      '',
      "<p>This is a comment.\n"
    ]

    assert_equal expected, @c2_c3.search_record
  end

end

