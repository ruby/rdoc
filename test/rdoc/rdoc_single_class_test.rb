# frozen_string_literal: true
require_relative 'helper'

class RDocSingleClassTest < RDoc::TestCase

  def setup
    super

    @c = RDoc::SingleClass.new 'C'
  end

  def test_aref_prefix
    assert_equal 'sclass', @c.aref_prefix
  end

  def test_definition
    assert_equal 'class << C', @c.definition
  end

end
