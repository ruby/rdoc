require 'rubygems'
require 'minitest/autorun'
require 'rdoc'
require 'rdoc/code_objects'

class TestRDocContextSection < MiniTest::Unit::TestCase
  
  def setup
    @s = RDoc::Context::Section.new nil, 'section', '# comment'
  end

  def test_comment_equals
    @s.comment = "# :section: section\n"

    assert_equal "# comment", @s.comment

    @s.comment = "# :section: section\n# other"

    assert_equal "# comment\n# ---\n# other", @s.comment

    s = RDoc::Context::Section.new nil, nil, nil

    s.comment = "# :section:\n# other"

    assert_equal "# other", s.comment
  end

  def test_extract_comment
    assert_equal '',    @s.extract_comment('')
    assert_equal '',    @s.extract_comment("# :section: b\n")
    assert_equal '# c', @s.extract_comment("# :section: b\n# c")
    assert_equal '# c', @s.extract_comment("# a\n# :section: b\n# c")
  end

end

