# frozen_string_literal: true
require_relative 'xref_test_case'

class RDocAliasTest < XrefTestCase

  def test_to_s
    a = RDoc::Alias.new nil, 'a', 'b', ''
    a.parent = @c2

    assert_equal 'alias: b -> #a in: RDoc::NormalClass C2 < Object', a.to_s
  end

end
