require 'rdoc/test_case'

class TestRDocRIPaths < RDoc::TestCase

  def setup
    super

    @tempdir = File.join Dir.tmpdir, "test_rdoc_ri_paths_#{$$}"

    @rake_10   = File.join @tempdir, 'doc/rake-10.0.1/ri'
    @rdoc_4_0  = File.join @tempdir, 'doc/rdoc-4.0/ri'
    @rdoc_3_12 = File.join @tempdir, 'doc/rdoc-3.12/ri'

    FileUtils.mkdir_p @rake_10
    FileUtils.mkdir_p @rdoc_3_12
    FileUtils.mkdir_p @rdoc_4_0

    @spec = Gem::Specification.new 'test', '1.0'
    @spec.loaded_from =
      File.expand_path '../specifications/test-1.0.gemspec', __FILE__

    @orig_gem_path = Gem.path
    Gem.use_paths @tempdir
    Gem::Specification.reset
    Gem::Specification.all = [@spec]
  end

  def teardown
    super

    Gem.use_paths(*@orig_gem_path)
    Gem::Specification.reset
    FileUtils.rm_rf @tempdir
  end

  def test_class_each
    enum = RDoc::RI::Paths.each true, true, true, :all

    path = enum.map { |dir,| dir }

    assert_equal RDoc::RI::Paths.system_dir, path.shift
    assert_equal RDoc::RI::Paths.site_dir,   path.shift
    assert_equal RDoc::RI::Paths.home_dir,   path.shift
    assert_equal @rake_10,                   path.shift
    assert_equal @rdoc_4_0,                  path.shift
    assert_equal @rdoc_3_12,                 path.shift
    assert_empty path
  end

  def test_class_gemdirs_latest
    Dir.chdir @tempdir do
      gemdirs = RDoc::RI::Paths.gemdirs :latest, %w[.]

      assert_equal %w[./doc/rake-10.0.1/ri ./doc/rdoc-4.0/ri], gemdirs
    end
  end

  def test_class_gemdirs_legacy
    Dir.chdir @tempdir do
      gemdirs = RDoc::RI::Paths.gemdirs true, %w[.]

      assert_equal %w[./doc/rake-10.0.1/ri ./doc/rdoc-4.0/ri], gemdirs
    end
  end

  def test_class_gemdirs_all
    Dir.chdir @tempdir do
      gemdirs = RDoc::RI::Paths.gemdirs :all, %w[.]

      expected = %w[./doc/rake-10.0.1/ri ./doc/rdoc-4.0/ri ./doc/rdoc-3.12/ri]

      assert_equal expected, gemdirs
    end
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
    assert_equal @rake_10,                   path.shift
  end

  def test_class_raw_path_extra_dirs
    path = RDoc::RI::Paths.raw_path true, true, true, true, '/nonexistent'

    assert_equal '/nonexistent',             path.shift
    assert_equal RDoc::RI::Paths.system_dir, path.shift
    assert_equal RDoc::RI::Paths.site_dir,   path.shift
    assert_equal RDoc::RI::Paths.home_dir,   path.shift
    assert_equal @rake_10,                   path.shift
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

