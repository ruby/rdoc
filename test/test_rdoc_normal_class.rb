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
    @c1.comment = 'This is a comment.'

    expected = [
      'C1',
      'xref_data.rb',
      'C1.html',
      ' < Object',
      "<p>This is a comment.\n",
      RDoc::Generator::JsonIndex::TYPE_CLASS,
    ]

    assert_equal expected, @c1.search_record
  end

end

