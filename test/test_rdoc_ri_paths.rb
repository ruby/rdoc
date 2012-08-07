require 'rdoc/test_case'

class TestRDocRIPaths < RDoc::TestCase

  def setup
    super

    RDoc::RI::Paths.instance_variable_set :@gemdirs, %w[/nonexistent/gemdir]

    @spec = Gem::Specification.new 'test', '1.0'
    @spec.loaded_from =
      File.expand_path '../specifications/test-1.0.gemspec', __FILE__

    Gem::Specification.reset
    Gem::Specification.all = [@spec]
  end

  def teardown
    super

    RDoc::RI::Paths.instance_variable_set :@gemdirs, nil
    Gem::Specification.reset
  end

  def test_class_gem_dir
    dir = RDoc::RI::Paths.gem_dir 'test', '1.0'

    expected = File.expand_path '../doc/test-1.0/ri', __FILE__

    assert_equal expected, dir
  end

  def test_class_home_dir
    dir = RDoc::RI::Paths.home_dir

    assert_equal RDoc::RI::Paths::HOMEDIR, dir
  end

  def test_class_path_nonexistent
    temp_dir do |dir|
      nonexistent = File.join dir, 'nonexistent'
      dir = RDoc::RI::Paths.path true, true, true, true, nonexistent

      refute_includes dir, nonexistent
    end
  end

  def test_class_raw_path
    path = RDoc::RI::Paths.raw_path true, true, true, true

    assert_equal RDoc::RI::Paths.system_dir, path.shift
    assert_equal RDoc::RI::Paths.site_dir,   path.shift
    assert_equal RDoc::RI::Paths.home_dir,   path.shift
    assert_equal '/nonexistent/gemdir',      path.shift
  end

  def test_class_raw_path_extra_dirs
    path = RDoc::RI::Paths.raw_path true, true, true, true, '/nonexistent'

    assert_equal '/nonexistent',             path.shift
    assert_equal RDoc::RI::Paths.system_dir, path.shift
    assert_equal RDoc::RI::Paths.site_dir,   path.shift
    assert_equal RDoc::RI::Paths.home_dir,   path.shift
    assert_equal '/nonexistent/gemdir',      path.shift
  end

  def test_class_site_dir
    dir = RDoc::RI::Paths.site_dir

    assert_equal File.join(RDoc::RI::Paths::BASE, 'site'), dir
  end

  def test_class_system_dir
    dir = RDoc::RI::Paths.system_dir

    assert_equal File.join(RDoc::RI::Paths::BASE, 'system'), dir
  end

end

