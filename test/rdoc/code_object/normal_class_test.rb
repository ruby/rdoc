# frozen_string_literal: true
require_relative '../xref_test_case'

class RDocNormalClassTest < XrefTestCase

  def test_ancestors
    klass = @top_level.add_class RDoc::NormalClass, 'Klass'
    incl = RDoc::Include.new 'Incl', ''

    sub_klass = @top_level.add_class RDoc::NormalClass, 'SubClass'
    sub_klass.superclass = klass
    sub_klass.add_include incl

    assert_equal [incl.name, klass, @object, 'BasicObject'], sub_klass.ancestors
  end

  def test_ancestors_multilevel
    c1 = @top_level.add_class RDoc::NormalClass, 'Outer'
    c2 = @top_level.add_class RDoc::NormalClass, 'Middle', c1.full_name
    c3 = @top_level.add_class RDoc::NormalClass, 'Inner', c2.full_name

    assert_equal [c2, c1, @object, 'BasicObject'], c3.ancestors
  end

  def test_ancestors_superclass_cycle
    c1 = @top_level.add_class RDoc::NormalClass, 'Cycle1'
    c2 = @top_level.add_class RDoc::NormalClass, 'Cycle2'
    c1.superclass = c2
    c2.superclass = c1

    assert_equal [c2], c1.ancestors
    assert_equal [c1], c2.ancestors
  end

  def test_ancestors_superclass_referencing_itself
    klass = @top_level.add_class RDoc::NormalClass, 'Klass'
    incl = RDoc::Include.new 'Incl', ''
    klass.add_include incl
    klass.superclass = klass

    assert_equal [incl.name], klass.ancestors
  end

  def test_ancestors_chain_ending_with_nil_superclass
    base = @top_level.add_class RDoc::NormalClass, 'Base'
    base.superclass = nil
    sub = @top_level.add_class RDoc::NormalClass, 'Sub', 'Base'

    assert_equal [base], sub.ancestors
  end

  def test_ancestors_superclass_is_module
    klass = @top_level.add_class RDoc::NormalClass, 'Klass'
    mod = @top_level.add_module RDoc::NormalModule, 'Mod'
    klass.superclass = mod

    # A module is not registered as a class, so the superclass stays a String
    assert_equal 'Mod', klass.superclass
    assert_equal ['Mod'], klass.ancestors
  end

  def test_aref
    assert_equal 'class-c1',    @c1.aref
    assert_equal 'class-c2-c3', @c2_c3.aref
  end

  def test_direct_ancestors
    incl = RDoc::Include.new 'Incl', ''

    c1 = @top_level.add_class RDoc::NormalClass, 'Outer'
    c2 = @top_level.add_class RDoc::NormalClass, 'Middle', c1.full_name
    c3 = @top_level.add_class RDoc::NormalClass, 'Inner', c2.full_name
    c3.add_include incl

    assert_equal [incl.name, c2], c3.direct_ancestors
  end

  def test_definition
    c = RDoc::NormalClass.new 'C'

    assert_equal 'class C', c.definition
  end

end
