require 'rubygems'
require 'minitest/autorun'
require 'rdoc/rdoc'

require 'fileutils'
require 'tempfile'
require 'tmpdir'

class TestRDocRDoc < MiniTest::Unit::TestCase

  def setup
    @rdoc = RDoc::RDoc.new
    @rdoc.options = RDoc::Options.new

    @stats = RDoc::Stats.new 0, 0
    @rdoc.instance_variable_set :@stats, @stats

    @tempfile = Tempfile.new 'test_rdoc_rdoc'
  end

  def teardown
    @tempfile.close rescue nil # HACK for 1.8.6
  end

  def test_class_read_file
    @tempfile.write "hi everybody"
    @tempfile.flush

    assert_equal "hi everybody", RDoc::RDoc.read_file(@tempfile.path, nil)
  end

  def test_class_read_file_encoding
    skip "Encoding not implemented" unless Object.const_defined? :Encoding

    expected = "# coding: utf-8\nhi everybody"

    @tempfile.write expected
    @tempfile.flush

    # FIXME 1.9 fix on windoze
    expected.gsub!("\n", "\r\n") if RUBY_VERSION =~ /^1.9/ && RUBY_PLATFORM =~ /mswin|mingw/

    contents = RDoc::RDoc.read_file @tempfile.path, Encoding::UTF_8
    assert_equal expected, contents
    assert_equal Encoding::UTF_8, contents.encoding
  end

  def test_class_read_file_encoding_convert
    skip "Encoding not implemented" unless Object.const_defined? :Encoding

    content = ""
    content.encode! 'ISO-8859-1'
    content << "# coding: ISO-8859-1\nhi \xE9verybody"

    @tempfile.write content
    @tempfile.flush

    contents = RDoc::RDoc.read_file @tempfile.path, Encoding::UTF_8
    assert_equal Encoding::UTF_8, contents.encoding
    assert_equal "# coding: ISO-8859-1\nhi \u00e9verybody", contents.sub("\r", '')
  end

  def test_class_read_file_encoding_fancy
    skip "Encoding not implemented" unless Object.const_defined? :Encoding

    expected = "# -*- coding: utf-8; fill-column: 74 -*-\nhi everybody"
    expected.encode! Encoding::UTF_8

    @tempfile.write expected
    @tempfile.flush

    # FIXME 1.9 fix on windoze
    expected.gsub!("\n", "\r\n") if RUBY_VERSION =~ /^1.9/ && RUBY_PLATFORM =~ /win32|mingw32/

    contents = RDoc::RDoc.read_file @tempfile.path, Encoding::UTF_8
    assert_equal expected, contents
    assert_equal Encoding::UTF_8, contents.encoding
  end

  def test_class_read_file_encoding_guess
    skip "Encoding not implemented" unless Object.const_defined? :Encoding

    path = File.expand_path '../test.ja.txt', __FILE__
    content = RDoc::RDoc.read_file path, Encoding::UTF_8

    assert_equal Encoding::UTF_8, content.encoding
  end

  def test_class_read_file_encoding_with_signature
    skip "Encoding not implemented" unless defined? ::Encoding

    @tempfile.write "\xEF\xBB\xBFhi everybody"
    @tempfile.flush

    bug3360 = '[ruby-dev:41452]'
    content = RDoc::RDoc.read_file @tempfile.path, Encoding::UTF_8
    assert_equal Encoding::UTF_8, content.encoding, bug3360
    assert_equal "hi everybody", content, bug3360
  end

  def test_class_set_encoding
    skip "Encoding not implemented" unless Object.const_defined? :Encoding

    s = "# coding: UTF-8\n"
    RDoc::RDoc.set_encoding s

    assert_equal Encoding::UTF_8, s.encoding

    s = "#!/bin/ruby\n# coding: UTF-8\n"
    RDoc::RDoc.set_encoding s

    assert_equal Encoding::UTF_8, s.encoding

    s = "<?xml version='1.0' encoding='UTF-8'?>\n"
    expected = s.encoding
    RDoc::RDoc.set_encoding s

    assert_equal Encoding::UTF_8, s.encoding

    s = "<?xml version='1.0' encoding=\"UTF-8\"?>\n"
    expected = s.encoding
    RDoc::RDoc.set_encoding s

    assert_equal Encoding::UTF_8, s.encoding
  end

  def test_class_set_encoding_bad
    skip "Encoding not implemented" unless Object.const_defined? :Encoding

    s = ""
    expected = s.encoding
    RDoc::RDoc.set_encoding s

    assert_equal expected, s.encoding

    s = "# vim:set fileencoding=utf-8:\n"
    expected = s.encoding
    RDoc::RDoc.set_encoding s

    assert_equal expected, s.encoding

    s = "# vim:set fileencoding=utf-8:\n"
    expected = s.encoding
    RDoc::RDoc.set_encoding s

    assert_equal expected, s.encoding

    assert_raises ArgumentError do
      RDoc::RDoc.set_encoding "# -*- encoding: undecided -*-\n"
    end
  end

  def test_gather_files
    file = File.expand_path __FILE__
    assert_equal [file], @rdoc.gather_files([file, file])
  end

  def test_normalized_file_list
    files = @rdoc.normalized_file_list [__FILE__]

    files = files.map { |file| File.expand_path file }

    assert_equal [File.expand_path(__FILE__)], files
  end

  def test_normalized_file_list_not_modified
    files = [__FILE__]

    @rdoc.last_modified[__FILE__] = File.stat(__FILE__).mtime

    files = @rdoc.normalized_file_list [__FILE__]

    assert_empty files
  end

  def test_remove_unparsable
    file_list = %w[
      blah.class
      blah.eps
      blah.erb
      blah.scpt.txt
      blah.ttf
      blah.yml
    ]

    assert_empty @rdoc.remove_unparseable file_list
  end

  def test_setup_output_dir
    skip "No Dir::mktmpdir, upgrade your ruby" unless Dir.respond_to? :mktmpdir

    Dir.mktmpdir {|d|
      path = File.join(d, 'testdir')

      last = @rdoc.setup_output_dir path, false

      assert_empty last

      assert File.directory? path
    }
  end

  def test_setup_output_dir_dry_run
    skip "No Dir::mktmpdir, upgrade your ruby" unless Dir.respond_to? :mktmpdir

    @rdoc.options.dry_run = true

    Dir.mktmpdir do |d|
      path = File.join d, 'testdir'

      @rdoc.setup_output_dir path, false

      refute File.exist? path
    end
  end

  def test_setup_output_dir_exists
    skip "No Dir::mktmpdir, upgrade your ruby" unless Dir.respond_to? :mktmpdir

    Dir.mktmpdir {|path|
      open @rdoc.output_flag_file(path), 'w' do |io|
        io.puts Time.at 0
        io.puts "./lib/rdoc.rb\t#{Time.at 86400}"
      end

      last = @rdoc.setup_output_dir path, false

      assert_equal 1, last.size
      assert_equal Time.at(86400), last['./lib/rdoc.rb']
    }
  end

  def test_setup_output_dir_exists_empty_created_rid
    skip "No Dir::mktmpdir, upgrade your ruby" unless Dir.respond_to? :mktmpdir

    Dir.mktmpdir {|path|
      open @rdoc.output_flag_file(path), 'w' do end

      e = assert_raises RDoc::Error do
        @rdoc.setup_output_dir path, false
      end

      assert_match %r%Directory #{Regexp.escape path} already exists%, e.message
    }
  end

  def test_setup_output_dir_exists_file
    path = @tempfile.path

    e = assert_raises RDoc::Error do
      @rdoc.setup_output_dir path, false
    end

    assert_match(%r%#{Regexp.escape path} exists and is not a directory%,
                 e.message)
  end

  def test_setup_output_dir_exists_not_rdoc
    skip "No Dir::mktmpdir, upgrade your ruby" unless Dir.respond_to? :mktmpdir

    Dir.mktmpdir do |dir|
      e = assert_raises RDoc::Error do
        @rdoc.setup_output_dir dir, false
      end

      assert_match %r%Directory #{Regexp.escape dir} already exists%, e.message
    end
  end

  def test_update_output_dir
    skip "No Dir::mktmpdir, upgrade your ruby" unless Dir.respond_to? :mktmpdir

    Dir.mktmpdir do |d|
      @rdoc.update_output_dir d, Time.now, {}

      assert File.exist? "#{d}/created.rid"
    end
  end

  def test_update_output_dir_dry_run
    skip "No Dir::mktmpdir, upgrade your ruby" unless Dir.respond_to? :mktmpdir

    Dir.mktmpdir do |d|
      @rdoc.options.dry_run = true
      @rdoc.update_output_dir d, Time.now, {}

      refute File.exist? "#{d}/created.rid"
    end
  end

end

