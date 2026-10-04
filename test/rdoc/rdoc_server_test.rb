# frozen_string_literal: true
require_relative 'support/test_case'
require 'net/http'

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

  def test_cached_templates_render_updated_and_new_classes_after_reparse
    with_running_server do |port|
      original = get port, '/Example.html'
      assert_equal '200', original.code
      assert_include original.body, 'method-i-greet'

      generator = @server.instance_variable_get :@generator
      template = generator.template_for generator.template_dir + 'class.rhtml'
      renderer = template.instance_variable_get(:@compiled_renderers).values.first

      File.write File.join(@dir, 'example.rb'), <<~RUBY
        # Updated documentation from reparsed source.
        class Example
          def changed
          end
        end

        # Documentation for a newly added class.
        class Another
        end
      RUBY

      wait_for('cached class page to reflect reparsed source') do
        get(port, '/Example.html').body.include?('Updated documentation from reparsed source.')
      end

      updated = get port, '/Example.html'
      assert_include updated.body, 'method-i-changed'
      assert_not_include updated.body, 'method-i-greet'

      added = get port, '/Another.html'
      assert_equal '200', added.code
      assert_include added.body, 'Documentation for a newly added class.'
      assert_not_include added.body, 'Updated documentation from reparsed source.'
      assert_same renderer, template.instance_variable_get(:@compiled_renderers).values.first
    end
  end

  def test_check_for_changes_parses_and_reloads_rbs_signatures
    with_running_server do |port|
      sig_dir = File.join @dir, 'sig'
      FileUtils.mkdir_p sig_dir
      File.write File.join(sig_dir, 'example.rbs'), <<~RBS
        class Example
          # RBS method docs.
          def greet: () -> String
        end
      RBS

      wait_for('class page to include the RBS method documentation') do
        get(port, '/Example.html').body.include?('RBS method docs.')
      end

      example = @rdoc.store.find_class_or_module 'Example'
      greet = example.find_method 'greet', false
      assert_equal "RBS method docs.", greet.comment.to_s.strip
      assert_equal ['() -> String'], greet.type_signature_lines
      assert_equal ['() -> String'], @rdoc.store.rbs_signature_for(greet)
    end
  end

  def test_check_for_changes_parses_rbs_sources
    with_running_server do |port|
      File.write File.join(@dir, 'sample.rbs'), <<~RBS
        class Sample
          def greet: () -> String
        end
      RBS

      wait_for('class page to include the new RBS source') do
        get(port, '/Sample.html').code == '200'
      end

      sample = @rdoc.store.find_class_or_module 'Sample'
      greet = sample.find_method 'greet', false
      assert_equal ['() -> String'], greet.type_signature_lines
    end
  end

  def test_current_watch_files_deduplicates_symlinked_source_tree
    source_dir = File.join @dir, 'gem'
    symlink_dir = File.join @dir, 'docs', 'gem'
    FileUtils.mkdir_p [File.dirname(symlink_dir), source_dir]
    source_file = File.join source_dir, 'example.rb'
    FileUtils.touch source_file
    FileUtils.ln_s '../gem', symlink_dir
    omit 'directory symlinks are not supported' unless File.directory? symlink_dir

    assert_equal 1, @server.send(:current_watch_files).count { |file| File.identical?(source_file, file) }
  rescue NotImplementedError, Errno::EACCES, Errno::EPERM
    omit 'symlinks are not supported'
  end

  private

  def with_running_server
    port = TCPServer.open('127.0.0.1', 0) { |socket| socket.addr[1] }
    @server = RDoc::Server.new(@rdoc, port)
    server_thread = Thread.new { @server.start }

    wait_for('server to start') do
      get(port, '/__status').code == '200'
    rescue Errno::ECONNREFUSED
      false
    end

    yield port
  ensure
    server_thread&.raise(Interrupt) if server_thread&.alive?
    server_thread&.join
  end

  def get(port, path)
    Net::HTTP.start('127.0.0.1', port) { |http| http.get(path) }
  end

  def wait_for(description)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 10

    until yield
      flunk "Timed out waiting for #{description}" if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
      sleep 0.05
    end
  end
end
