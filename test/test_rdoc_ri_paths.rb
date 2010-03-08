require 'rubygems'
require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require 'rdoc/ri/paths'

class TestRDocRIPaths < MiniTest::Unit::TestCase

  def test_class_path_nonexistent
    path = RDoc::RI::Paths.path true, true, true, true, '/nonexistent'

    refute_includes path, '/nonexistent'
  end

  def test_class_raw_path
    path = RDoc::RI::Paths.raw_path true, true, true, true

    assert_equal RDoc::RI::Paths::SYSDIR,  path.shift
    assert_equal RDoc::RI::Paths::SITEDIR, path.shift
    assert_equal RDoc::RI::Paths::HOMEDIR, path.shift

    refute_empty path
    assert_kind_of String, path.first
  end

  def test_class_raw_path_extra_dirs
    path = RDoc::RI::Paths.raw_path true, true, true, true, '/nonexistent'

    assert_equal '/nonexistent',           path.shift
    assert_equal RDoc::RI::Paths::SYSDIR,  path.shift
    assert_equal RDoc::RI::Paths::SITEDIR, path.shift
    assert_equal RDoc::RI::Paths::HOMEDIR, path.shift

    refute_empty path
    assert_kind_of String, path.first
  end

end

