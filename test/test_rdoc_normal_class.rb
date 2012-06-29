require File.expand_path '../xref_test_case', __FILE__

class TestRDocNormalClass < XrefTestCase

  def test_ancestors
    klass = RDoc::NormalClass.new 'Klass'
    incl = RDoc::Include.new 'Incl', ''

    sub_klass = RDoc::NormalClass.new 'SubClass'
    sub_klass.superclass = klass
    sub_klass.add_include incl

    assert_equal [incl.name, klass], sub_klass.ancestors
  end

  def test_ancestors_multilevel
    c1 = RDoc::NormalClass.new 'Outer'
    c2 = RDoc::NormalClass.new 'Middle', c1
    c3 = RDoc::NormalClass.new 'Inner', c2

    assert_equal [c2, c1], c3.ancestors
  end

  def test_direct_ancestors
    incl = RDoc::Include.new 'Incl', ''

    c1 = RDoc::NormalClass.new 'Outer'
    c2 = RDoc::NormalClass.new 'Middle', c1
    c3 = RDoc::NormalClass.new 'Inner', c2
    c3.add_include incl

    assert_equal [incl.name, c2], c3.direct_ancestors
  end

  def test_definition
    c = RDoc::NormalClass.new 'C'

    assert_equal 'class C', c.definition
  end

end

