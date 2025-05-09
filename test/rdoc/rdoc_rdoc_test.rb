# frozen_string_literal: true
require_relative 'helper'

class RDocRDocTest < RDoc::TestCase

  def setup
    super

    @rdoc = RDoc::RDoc.new
    @options = RDoc::Options.new
    @rdoc.options = @options

    @stats = RDoc::Stats.new @store, 0, 0
    @rdoc.instance_variable_set :@stats, @stats
  end

  def test_document # functional test
    options = RDoc::Options.new
    options.files = [File.expand_path('../xref_data.rb', __FILE__)]
    options.setup_generator 'ri'
    options.main_page = 'MAIN_PAGE.rdoc'
    options.root      = Pathname File.expand_path('..', __FILE__)
    options.title     = 'title'

    rdoc = RDoc::RDoc.new

    temp_dir do
      options.op_dir = 'ri'

      capture_output do
        rdoc.document options
      end

      assert File.directory? 'ri'
    end

    store = rdoc.store

    assert_equal 'MAIN_PAGE.rdoc', store.main
    assert_equal 'title',          store.title
  end

  def test_document_with_dry_run # functional test
    options = RDoc::Options.new
    options.files = [File.expand_path('../xref_data.rb', __FILE__)]
    options.setup_generator 'darkfish'
    options.main_page = 'MAIN_PAGE.rdoc'
    options.root      = Pathname File.expand_path('..', __FILE__)
    options.title     = 'title'
    options.dry_run = true

    rdoc = RDoc::RDoc.new

    out = nil
    temp_dir do
      out, = capture_output do
        rdoc.document options
      end

      refute File.directory? 'doc'
    end
    assert_includes out, '100%'

    store = rdoc.store

    assert_equal 'MAIN_PAGE.rdoc', store.main
    assert_equal 'title',          store.title
  end

  def test_gather_files
    a = File.expand_path __FILE__
    b = File.expand_path '../rdoc_text_test.rb', __FILE__

    assert_equal [a, b], @rdoc.gather_files([b, a, b])

    assert_empty @rdoc.gather_files([b, a, b])

    @rdoc.last_modified[a] -= 10
    assert_equal [a, b], @rdoc.gather_files([b, a, b])
  end

  def test_handle_pipe
    $stdin = StringIO.new "hello"

    out, = capture_output do
      @rdoc.handle_pipe
    end

    assert_equal "\n<p>hello</p>\n", out
  ensure
    $stdin = STDIN
  end

  def test_handle_pipe_rd
    $stdin = StringIO.new "=begin\nhello\n=end"

    @rdoc.options.markup = 'rd'

    out, = capture_output do
      @rdoc.handle_pipe
    end

    assert_equal "\n<p>hello</p>\n", out
  ensure
    $stdin = STDIN
  end

  def test_normalized_file_list
    test_path = File.expand_path(__FILE__)
    files = temp_dir do |dir|
      flag_file = @rdoc.output_flag_file dir

      FileUtils.touch flag_file

      @rdoc.normalized_file_list [test_path, flag_file]
    end

    files = files.map { |file, *| File.expand_path file }

    assert_equal [test_path], files
  end

  def test_normalized_file_list_not_modified
    @rdoc.last_modified[__FILE__] = File.stat(__FILE__).mtime

    files = @rdoc.normalized_file_list [__FILE__]

    files = files.collect {|file, mtime| file if mtime}.compact

    assert_empty(files)
  end

  def test_normalized_file_list_non_file_directory
    dev = File::NULL
    omit "#{dev} is not a character special" unless
      File.chardev? dev

    files = nil

    out, err = verbose_capture_output do
      files = @rdoc.normalized_file_list [dev]
    end

    files = files.map { |file| File.expand_path file }

    assert_empty files

    assert_empty out
    assert_match %r"^rdoc can't parse", err
    assert_match %r"#{dev}$",           err
  end

  def test_normalized_file_list_with_dot_doc
    expected_files = []
    files = temp_dir do |dir|
      a = File.expand_path('a.rb')
      b = File.expand_path('b.rb')
      c = File.expand_path('c.rb')
      FileUtils.touch a
      FileUtils.touch b
      FileUtils.touch c
      # Use Dir.glob to convert short path of Dir.tmpdir to long path.
      a = Dir.glob(a).first
      b = Dir.glob(b).first
      c = Dir.glob(c).first

      File.write('.document', "a.rb\n""b.rb\n")
      expected_files << a
      expected_files << b

      @rdoc.normalized_file_list [File.realpath(dir)]
    end

    files = files.map { |file, *| File.expand_path file }

    assert_equal expected_files, files
  end

  def test_normalized_file_list_with_dot_doc_overridden_by_exclude_option
    expected_files = []
    files = temp_dir do |dir|
      a = File.expand_path('a.rb')
      b = File.expand_path('b.rb')
      c = File.expand_path('c.rb')
      FileUtils.touch a
      FileUtils.touch b
      FileUtils.touch c
      # Use Dir.glob to convert short path of Dir.tmpdir to long path.
      a = Dir.glob(a).first
      b = Dir.glob(b).first
      c = Dir.glob(c).first

      File.write('.document', "a.rb\n""b.rb\n")
      expected_files << a

      @rdoc.options.exclude = /b\.rb$/
      @rdoc.normalized_file_list [File.realpath(dir)]
    end

    files = files.map { |file, *| File.expand_path file }

    assert_equal expected_files, files
  end

  def test_normalized_file_list_with_skipping_tests_enabled
    files = temp_dir do |dir|
      @a = File.expand_path('a.rb')
      spec_dir = File.expand_path('spec')
      spec_file = File.expand_path(File.join('spec', 'my_spec.rb'))
      test_dir = File.expand_path('test')
      test_file = File.expand_path(File.join('test', 'my_test.rb'))
      FileUtils.touch @a
      FileUtils.mkdir_p spec_dir
      FileUtils.touch spec_file
      FileUtils.mkdir_p test_dir
      FileUtils.touch test_file

      @rdoc.options.skip_tests = true
      @rdoc.normalized_file_list [File.realpath(dir)]
    end

    files = files.map { |file, *| File.expand_path file }
    assert_equal [@a], files
  end

  def test_normalized_file_list_with_skipping_tests_disabled
    files = temp_dir do |dir|
      @a = File.expand_path('a.rb')
      spec_dir = File.expand_path('spec')
      @spec_file = File.expand_path(File.join('spec', 'my_spec.rb'))
      test_dir = File.expand_path('test')
      @test_file = File.expand_path(File.join('test', 'my_test.rb'))
      FileUtils.touch @a
      FileUtils.mkdir_p spec_dir
      FileUtils.touch @spec_file
      FileUtils.mkdir_p test_dir
      FileUtils.touch @test_file

      @rdoc.options.skip_tests = false
      @rdoc.normalized_file_list [File.realpath(dir)]
    end

    files = files.map { |file, *| File.expand_path file }
    assert_equal [@a, @spec_file, @test_file], files.sort
  end

  def test_parse_file
    @rdoc.store = RDoc::Store.new(@options)

    temp_dir do |dir|
      @rdoc.options.root = Pathname(Dir.pwd)

      File.open 'test.txt', 'w' do |io|
        io.puts 'hi'
      end

      top_level = @rdoc.parse_file 'test.txt'

      assert_equal 'test.txt', top_level.absolute_name
      assert_equal 'test.txt', top_level.relative_name
    end
  end

  def test_parse_file_binary
    @rdoc.store = RDoc::Store.new(@options)

    root = File.dirname __FILE__

    @rdoc.options.root = Pathname root

    out, err = capture_output do
      Dir.chdir root do
        assert_nil @rdoc.parse_file 'binary.dat'
      end
    end

    assert_empty out
    assert_empty err
  end

  def test_parse_file_include_root
    @rdoc.store = RDoc::Store.new(@options)

    test_path = File.expand_path('..', __FILE__)
    top_level = nil
    temp_dir do |dir|
      @rdoc.options.parse %W[--root #{test_path}]
      @rdoc.options.finish

      File.open 'include.txt', 'w' do |io|
        io.puts ':include: test.txt'
      end

      out, err = capture_output do
        top_level = @rdoc.parse_file 'include.txt'
      end
      assert_empty out
      assert_empty err
    end
    assert_equal "test file", top_level.comment.text
  end

  def test_parse_file_page_dir
    @rdoc.store = RDoc::Store.new(@options)

    temp_dir do |dir|
      FileUtils.mkdir 'pages'
      @rdoc.options.page_dir = Pathname('pages')
      @rdoc.options.root = Pathname(Dir.pwd)

      File.open 'pages/test.txt', 'w' do |io|
        io.puts 'hi'
      end

      top_level = @rdoc.parse_file 'pages/test.txt'

      assert_equal 'pages/test.txt', top_level.absolute_name
      assert_equal 'test.txt',       top_level.relative_name
    end
  end

  def test_parse_file_relative
    pwd = Dir.pwd

    @rdoc.store = RDoc::Store.new(@options)

    temp_dir do |dir|
      @rdoc.options.root = Pathname(dir)

      File.open 'test.txt', 'w' do |io|
        io.puts 'hi'
      end

      test_txt = File.join dir, 'test.txt'

      Dir.chdir pwd do
        top_level = @rdoc.parse_file test_txt

        assert_equal test_txt,   top_level.absolute_name
        assert_equal 'test.txt', top_level.relative_name
      end
    end
  end

  def test_parse_file_encoding
    @rdoc.options.encoding = Encoding::ISO_8859_1
    @rdoc.store = RDoc::Store.new(@options)

    tf = Tempfile.open 'test.txt' do |io|
      io.write 'hi'
      io.rewind

      top_level = @rdoc.parse_file io.path

      assert_equal Encoding::ISO_8859_1, top_level.absolute_name.encoding
      io
    end
    tf.close!
  end

  def test_parse_file_forbidden
    omit 'chmod not supported' if Gem.win_platform?
    omit "assumes that euid is not root" if Process.euid == 0

    @rdoc.store = RDoc::Store.new(@options)

    tf = Tempfile.open 'test.txt' do |io|
      io.write 'hi'
      io.rewind

      File.chmod 0000, io.path

      begin
        top_level = :bug

        _, err = capture_output do
          top_level = @rdoc.parse_file io.path
        end

        assert_match "Unable to read #{io.path},", err

        assert_nil top_level
      ensure
        File.chmod 0400, io.path
      end
      io
    end
    tf.close!
  end

  def test_remove_unparseable
    file_list = %w[
      blah.class
      blah.eps
      blah.erb
      blah.scpt.txt
      blah.svg
      blah.ttf
      blah.yml
    ]

    assert_empty @rdoc.remove_unparseable file_list
  end

  def test_remove_unparseable_tags_emacs
    temp_dir do
      File.open 'TAGS', 'wb' do |io| # emacs
        io.write "\f\nlib/foo.rb,43\n"
      end

      file_list = %w[
        TAGS
      ]

      assert_empty @rdoc.remove_unparseable file_list
    end
  end

  def test_remove_unparseable_tags_vim
    temp_dir do
      File.open 'TAGS', 'w' do |io| # emacs
        io.write "!_TAG_"
      end

      file_list = %w[
        TAGS
      ]

      assert_empty @rdoc.remove_unparseable file_list
    end
  end

  def test_remove_unparseable_CVE_2021_31799
    omit 'for Un*x platforms' if Gem.win_platform?
    temp_dir do
      file_list = ['| touch evil.txt && echo tags']
      file_list.each do |f|
        FileUtils.touch f rescue omit
      end

      assert_equal file_list, @rdoc.remove_unparseable(file_list)
      assert_equal file_list, Dir.children('.')
    end
  end

  def test_setup_output_dir
    Dir.mktmpdir {|d|
      path = File.join d, 'testdir'

      last = @rdoc.setup_output_dir path, false

      assert_empty last

      assert File.directory? path
      assert File.exist? @rdoc.output_flag_file path
    }
  end

  def test_setup_output_dir_dry_run
    @rdoc.options.dry_run = true

    Dir.mktmpdir do |d|
      path = File.join d, 'testdir'

      @rdoc.setup_output_dir path, false

      refute File.exist? path
    end
  end

  def test_setup_output_dir_exists
    Dir.mktmpdir {|path|
      File.open @rdoc.output_flag_file(path), 'w' do |io|
        io.puts Time.at 0
        io.puts "./lib/rdoc.rb\t#{Time.at 86400}"
      end

      last = @rdoc.setup_output_dir path, false

      assert_equal 1, last.size
      assert_equal Time.at(86400), last['./lib/rdoc.rb']
    }
  end

  def test_setup_output_dir_exists_empty_created_rid
    Dir.mktmpdir {|path|
      File.open @rdoc.output_flag_file(path), 'w' do end

      e = assert_raise RDoc::Error do
        @rdoc.setup_output_dir path, false
      end

      assert_match %r%Directory #{Regexp.escape path} already exists%, e.message
    }
  end

  def test_setup_output_dir_exists_file
    tf = Tempfile.open 'test_rdoc_rdoc' do |tempfile|
      path = tempfile.path

      e = assert_raise RDoc::Error do
        @rdoc.setup_output_dir path, false
      end

      assert_match(%r%#{Regexp.escape path} exists and is not a directory%,
                   e.message)
      tempfile
    end
    tf.close!
  end

  def test_setup_output_dir_exists_not_rdoc
    Dir.mktmpdir do |dir|
      e = assert_raise RDoc::Error do
        @rdoc.setup_output_dir dir, false
      end

      assert_match %r%Directory #{Regexp.escape dir} already exists%, e.message
    end
  end

  def test_update_output_dir
    Dir.mktmpdir do |d|
      @rdoc.update_output_dir d, Time.now, {}

      assert File.exist? "#{d}/created.rid"
    end
  end

  def test_update_output_dir_dont
    Dir.mktmpdir do |d|
      @rdoc.options.update_output_dir = false
      @rdoc.update_output_dir d, Time.now, {}

      refute File.exist? "#{d}/created.rid"
    end
  end

  def test_update_output_dir_dry_run
    Dir.mktmpdir do |d|
      @rdoc.options.dry_run = true
      @rdoc.update_output_dir d, Time.now, {}

      refute File.exist? "#{d}/created.rid"
    end
  end

  def test_update_output_dir_with_reproducible_time
    Dir.mktmpdir do |d|
      backup_epoch = ENV['SOURCE_DATE_EPOCH']
      ruby_birthday = Time.parse 'Wed, 24 Feb 1993 21:00:00 +0900'
      ENV['SOURCE_DATE_EPOCH'] = ruby_birthday.to_i.to_s

      @rdoc.update_output_dir d, Time.now, {}

      assert File.exist? "#{d}/created.rid"

      f = File.open("#{d}/created.rid", 'r')
      head_timestamp = Time.parse f.gets.chomp
      f.close
      assert_equal ruby_birthday, head_timestamp

      ENV['SOURCE_DATE_EPOCH'] = backup_epoch
    end
  end

  def test_normalized_file_list_removes_created_rid_dir
    temp_dir do |d|
      FileUtils.mkdir "doc"
      flag_file = @rdoc.output_flag_file "doc"
      file = File.join "doc", "test"
      FileUtils.touch flag_file
      FileUtils.touch file

      file_list = ["doc"]

      output = @rdoc.normalized_file_list file_list

      assert_empty output
    end
  end
end
