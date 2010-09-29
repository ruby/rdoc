require File.expand_path '../xref_test_case', __FILE__

class RDocMethodAttr < XrefTestCase

  def test_record_location
    @c1_m.record_location @xref_data

    assert_equal 'xref_data.rb', @c1_m.top_level.relative_name
  end

end

