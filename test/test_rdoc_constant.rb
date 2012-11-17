require File.expand_path '../xref_test_case', __FILE__

class TestRDocConstant < XrefTestCase

  def setup
    super

    @const = @c1.constants.first
  end

  def test_full_name
    assert_equal 'C1::CONST', @const.full_name
  end

  def test_path
    assert_equal 'C1.html#CONST', @const.path
  end

end
