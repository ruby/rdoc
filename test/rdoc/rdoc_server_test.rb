# frozen_string_literal: true
require_relative 'support/test_case'

class RDocServerTest < RDoc::TestCase

  def setup
    super

    @dir = Dir.mktmpdir("test_rdoc_server_")

    File.write File.join(@dir, "PAGE.md"), "# A Page\n\nSome content.\n"
    File.write File.join(@dir, "NOTES.rdoc"), "= Notes\n\nSome notes.\n"
    File.write File.join(@dir, "example.rb"), <<~RUBY
      # A class
      class Example
        def greet
        end
      end
    RUBY

    @options.files = [@dir]
    @options.op_dir = File.join(@dir, "_site")
    @options.root = Pathname(@dir)
    @options.verbosity = 0
    @options.finish

    @rdoc.options = @options
    @rdoc.store = RDoc::Store.new(@options)

    capture_output do
      @rdoc.parse_files @options.files
    end
    @rdoc.store.complete @options.visibility

    @server = RDoc::Server.new(@rdoc, 0)
  end

  def teardown
    FileUtils.rm_rf @dir
    super
  end

  def test_route_serves_text_page
    status, content_type, body = @server.send(:route, '/PAGE_md.html')

    assert_equal 200, status
    assert_equal 'text/html', content_type
    assert_include body, 'A Page'
  end

  def test_route_serves_rdoc_text_page
    status, content_type, body = @server.send(:route, '/NOTES_rdoc.html')

    assert_equal 200, status
    assert_equal 'text/html', content_type
    assert_include body, 'Notes'
  end

  def test_route_serves_class_page
    status, content_type, body = @server.send(:route, '/Example.html')

    assert_equal 200, status
    assert_equal 'text/html', content_type
    assert_include body, 'Example'
  end

  def test_route_serves_index
    status, content_type, _body = @server.send(:route, '/')

    assert_equal 200, status
    assert_equal 'text/html', content_type
  end

  def test_route_returns_404_for_missing_page
    status, content_type, _body = @server.send(:route, '/nonexistent.html')

    assert_equal 404, status
    assert_equal 'text/html', content_type
  end

  def test_check_for_changes_parses_and_reloads_rbs_signatures
    @server.instance_variable_set(:@file_mtimes, @rdoc.last_modified.keys.to_h { |file|
      [file, File.mtime(file)]
    })

    sig_dir = File.join @dir, 'sig'
    FileUtils.mkdir_p sig_dir
    File.write File.join(sig_dir, 'example.rbs'), <<~RBS
      class Example
        # RBS method docs.
        def greet: () -> String
      end
    RBS

    _out, err = capture_output do
      assert @server.send(:check_for_changes)
    end

    assert_not_include err, 'Error parsing'

    example = @rdoc.store.find_class_or_module 'Example'
    greet = example.find_method 'greet', false
    assert_equal "RBS method docs.", greet.comment.to_s.strip
    assert_equal ['() -> String'], greet.type_signature_lines
    assert_equal ['() -> String'], @rdoc.store.rbs_signature_for(greet)
  end

  def test_check_for_changes_parses_rbs_sources
    @server.instance_variable_set(:@file_mtimes, @rdoc.last_modified.keys.to_h { |file|
      [file, File.mtime(file)]
    })

    File.write File.join(@dir, 'sample.rbs'), <<~RBS
      class Sample
        def greet: () -> String
      end
    RBS

    _out, err = capture_output do
      assert @server.send(:check_for_changes)
    end

    assert_not_include err, 'Error parsing'

    sample = @rdoc.store.find_class_or_module 'Sample'
    greet = sample.find_method 'greet', false
    assert_equal ['() -> String'], greet.type_signature_lines
  end
end
