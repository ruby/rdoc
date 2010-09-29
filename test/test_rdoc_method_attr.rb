require File.expand_path '../xref_test_case', __FILE__

class TestRDocMethodAttr < XrefTestCase

  def test_to_s
    assert_equal 'RDoc::AnyMethod: C1#m',  @c1_m.to_s
    assert_equal 'RDoc::AnyMethod: C2#b',  @c2_b.to_s
    assert_equal 'RDoc::AnyMethod: C1::m', @c1__m.to_s
  end

end

