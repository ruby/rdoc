# frozen_string_literal: true

require 'socket'
require 'json'
require 'erb'
require 'set'
require 'uri'

##
# A minimal HTTP server for live-reloading RDoc documentation.
#
# Uses Ruby's built-in +TCPServer+ (no external dependencies).
#
# Used by <tt>rdoc --server</tt> to let developers preview documentation
# while editing source files.  Parses sources once on startup, watches for
# file changes, re-parses only the changed files, and auto-refreshes the
# browser via a simple polling script.

class RDoc::Server

  ##
  # Returns a live-reload polling script with the given +last_change_time+
  # embedded so the browser knows the exact timestamp of the content it
  # received.  This avoids a race where a change that occurs between page
  # generation and the first poll would be silently skipped.

  def self.live_reload_script(last_change_time)
    <<~JS
      <script>
      (function() {
        var lastChange = #{last_change_time.to_json};
        setInterval(function() {
          fetch('/__status').then(function(r) { return r.json(); }).then(function(data) {
            if (data.last_change > lastChange) location.reload();
            lastChange = data.last_change;
          }).catch(function() {});
        }, 1000);
      })();
      </script>
    JS
  end

  CONTENT_TYPES = {
    '.html' => 'text/html',
    '.css'  => 'text/css',
    '.js'   => 'application/javascript',
    '.json' => 'application/json',
  }.freeze

  STATUS_TEXTS = {
    200 => 'OK',
    400 => 'Bad Request',
    404 => 'Not Found',
    405 => 'Method Not Allowed',
    500 => 'Internal Server Error',
  }.freeze

  class FileChanges # :nodoc:
    attr_reader :changed_files, :removed_files

    def initialize(rdoc)
      @rdoc = rdoc
      @changed_files = []
      @removed_files = []
      @reload_rbs_signatures = false
    end

    def empty?
      !source_files_changed? && !reload_rbs_signatures?
    end

    def record_changed(file)
      reload_rbs_signatures_if_needed file
      changed_files << file
    end

    def record_removed(file)
      reload_rbs_signatures_if_needed file
      removed_files << file
    end

    def reload_rbs_signatures?
      @reload_rbs_signatures
    end

    def source_files_changed?
      !changed_files.empty? || !removed_files.empty?
    end

    private

    def reload_rbs_signatures_if_needed(file)
      @reload_rbs_signatures = true if @rdoc.auto_discovered_rbs_signature_file?(file)
    end
  end

  ##
  # Creates a new server.
  #
  # +rdoc+ is the RDoc::RDoc instance that has already parsed the source
  # files.
  # +port+ is the TCP port to listen on.

  def initialize(rdoc, port)
    @rdoc = rdoc
    @options = rdoc.options
    @store = rdoc.store
    @port = port

    # Silence stats output — the server prints its own timing.
    @rdoc.stats.verbosity = 0
    @generator = create_generator
    @template_dir = File.expand_path(@generator.template_dir)
    @page_cache = {}
    @last_change_time = Time.now.to_f
    @mutex = Mutex.new
    @running = false
  end

  ##
  # Starts the server.  Blocks until interrupted.

  def start
    @tcp_server = TCPServer.new('127.0.0.1', @port)
    @running = true

    @watcher_thread = start_watcher(@rdoc.watch_files)

    url = "http://localhost:#{@port}"
    $stderr.puts "\nServing documentation at: \e]8;;#{url}\e\\#{url}\e]8;;\e\\"
    $stderr.puts "Press Ctrl+C to stop.\n\n"

    loop do
      client = @tcp_server.accept
      Thread.new(client) { |c| handle_client(c) }
    end
  rescue Interrupt
    # Ctrl+C
  ensure
    @running = false
    @tcp_server&.close
    @watcher_thread&.join(2)
  end

  private

  def measure
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
    ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000).round(1)
  end

  def create_generator
    gen = RDoc::Generator::Aliki.new(@store, @options)
    gen.file_output = false
    gen.asset_rel_path = ''
    gen.setup
    gen
  end

  ##
  # Reads an HTTP request from +client+ and dispatches to the router.

  def handle_client(client)
    client.binmode

    return unless IO.select([client], nil, nil, 5)

    request_line = client.gets("\n")
    return unless request_line

    method, request_uri, = request_line.split(' ', 3)
    return write_response(client, 400, 'text/plain', 'Bad Request') unless request_uri

    begin
      path = URI.parse(request_uri).path
    rescue URI::InvalidURIError
      return write_response(client, 400, 'text/plain', 'Bad Request')
    end

    while (line = client.gets("\n"))
      break if line.strip.empty?
    end

    unless method == 'GET'
      return write_response(client, 405, 'text/plain', 'Method Not Allowed')
    end

    if path.start_with?('/__') || %r{\A/(?:css|js)/}.match?(path)
      status, content_type, body = route(path)
    else
      duration_ms = measure do
        status, content_type, body = route(path)
      end
      $stderr.puts "#{status} #{path} (#{duration_ms}ms)"
    end
    write_response(client, status, content_type, body)
  rescue => e
    write_response(client, 500, 'text/html', <<~HTML)
      <!DOCTYPE html>
      <html><body>
      <h1>Internal Server Error</h1>
      <pre>#{ERB::Util.html_escape e.message}\n#{ERB::Util.html_escape e.backtrace.join("\n")}</pre>
      </body></html>
    HTML
  ensure
    client.close rescue nil
  end

  ##
  # Routes a request path and returns [status, content_type, body].

  def route(path)
    case path
    when '/__status'
      t = @mutex.synchronize { @last_change_time }
      [200, 'application/json', JSON.generate(last_change: t)]
    when '/js/search_data.js'
      # Search data is dynamically generated, not a static asset
      serve_page(path)
    when %r{\A/(?:css|js)/}
      serve_asset(path)
    else
      serve_page(path)
    end
  end

  ##
  # Writes an HTTP/1.1 response to +client+.

  def write_response(client, status, content_type, body)
    body_bytes = body.b

    header = +"HTTP/1.1 #{status} #{STATUS_TEXTS[status] || 'Unknown'}\r\n"
    header << "Content-Type: #{content_type}\r\n"
    header << "Content-Length: #{body_bytes.bytesize}\r\n"
    header << "Connection: close\r\n"
    header << "\r\n"

    client.write(header)
    client.write(body_bytes)
    client.flush
  rescue Errno::EPIPE
    # Client disconnected before we finished writing — harmless.
  end

  ##
  # Serves a static asset (CSS, JS) from the Aliki template directory.

  def serve_asset(path)
    rel_path = path.delete_prefix("/")
    asset_path = File.join(@generator.template_dir, rel_path)
    real_asset = File.expand_path(asset_path)

    unless real_asset.start_with?("#{@template_dir}/") && File.file?(real_asset)
      return [404, 'text/plain', "Asset not found: #{rel_path}"]
    end

    ext = File.extname(rel_path)
    content_type = CONTENT_TYPES[ext] || 'application/octet-stream'
    [200, content_type, File.read(real_asset)]
  end

  ##
  # Serves an HTML page, rendering from the generator or returning a cached
  # version.

  def serve_page(path)
    name = path.delete_prefix("/")
    name = 'index.html' if name.empty?

    html = render_page(name)

    unless html
      not_found = @generator.generate_servlet_not_found(
        "The page <kbd>#{ERB::Util.html_escape path}</kbd> was not found"
      )
      t = @mutex.synchronize { @last_change_time }
      return [404, 'text/html', inject_live_reload(not_found || '', t)]
    end

    ext = File.extname(name)
    content_type = CONTENT_TYPES[ext] || 'text/html'
    [200, content_type, html]
  end

  ##
  # Renders a page through the Aliki generator and caches the result.

  def render_page(name)
    @mutex.synchronize do
      return @page_cache[name] if @page_cache[name]

      result = generate_page(name)
      return nil unless result

      result = inject_live_reload(result, @last_change_time) if name.end_with?('.html')
      @page_cache[name] = result
    end
  end

  ##
  # Dispatches to the appropriate generator method based on the page name.

  def generate_page(name)
    case name
    when 'index.html'
      @generator.generate_index
    when 'table_of_contents.html'
      @generator.generate_table_of_contents
    when 'js/search_data.js'
      "var search_data = #{JSON.generate(index: @generator.build_search_index)};"
    else
      text_name = name.chomp('.html')
      class_name = text_name.gsub('/', '::')

      if klass = @store.find_class_or_module(class_name)
        @generator.generate_class(klass)
      elsif page = @store.find_text_page(text_name.sub(/_([^_]*)\z/, '.\1'))
        @generator.generate_page(page)
      end
    end
  end

  ##
  # Injects the live-reload polling script before +</body>+.

  def inject_live_reload(html, last_change_time)
    html.sub('</body>', "#{self.class.live_reload_script(last_change_time)}</body>")
  end

  ##
  # Starts a background thread that polls source file mtimes and triggers
  # re-parsing when changes are detected.

  def start_watcher(source_files)
    @file_mtimes = file_mtimes_for(source_files)

    Thread.new do
      while @running
        begin
          sleep 1
          check_for_changes
        rescue => e
          $stderr.puts "RDoc server watcher error: #{e.message}"
        end
      end
    end
  end

  def file_mtimes_for(files)
    files.each_with_object({}) do |f, h|
      h[f] = RDoc.safe_mtime(f)
    end
  end

  ##
  # Checks for modified, new, and deleted files.  Returns true if any
  # changes were found and processed.

  def check_for_changes
    changes = FileChanges.new @rdoc
    current_files = current_watch_files
    current_file_set = current_files.to_set

    @file_mtimes.each_key do |file|
      changes.record_removed file unless current_file_set.include? file
    end

    current_files.each do |file|
      next unless file_changed? file

      @file_mtimes[file] = nil unless @file_mtimes.key? file
      changes.record_changed file
    end

    return false if changes.empty?

    reparse_and_refresh changes
    true
  end

  ##
  # Re-parses changed files, removes deleted files from the store,
  # refreshes the generator, and invalidates caches.

  def reparse_and_refresh(changes)
    @mutex.synchronize do
      remove_files changes.removed_files
      reparse_files changes.changed_files
      reload_rbs_signatures if changes.reload_rbs_signatures?
      @store.complete(@options.visibility)
      @store.invalidate_type_name_lookup if changes.source_files_changed?

      @generator.refresh_store_data
      @page_cache.clear
      @last_change_time = Time.now.to_f
    end
  end

  def current_watch_files
    file_list = @rdoc.normalized_file_list(
      @options.files.empty? ? [@options.root.to_s] : @options.files,
      true, @options.exclude
    )
    @rdoc.remove_unparseable(file_list).keys | @rdoc.auto_discovered_rbs_signature_files
  end

  def file_changed?(file)
    return true unless @file_mtimes.key? file

    old_mtime = @file_mtimes[file]
    return true unless old_mtime

    current_mtime = RDoc.safe_mtime(file)
    current_mtime && current_mtime > old_mtime
  end

  def remove_files(files)
    return if files.empty?

    $stderr.puts "Removed: #{files.join(', ')}"
    files.each do |f|
      @file_mtimes.delete(f)
      relative = @rdoc.relative_path_for(f)
      @store.clear_file_contributions(relative)
      @store.remove_file(relative)
    end
  end

  def reload_rbs_signatures
    duration_ms = measure do
      @rdoc.load_auto_discovered_rbs_signatures
      @rdoc.record_auto_discovered_rbs_signature_mtimes
      @rdoc.auto_discovered_rbs_signature_files.each do |file|
        @file_mtimes[file] = RDoc.safe_mtime(file)
      end
    end
    $stderr.puts "Reloaded RBS signatures (#{duration_ms}ms)"
  end

  def reparse_files(files)
    return if files.empty?

    changed_file_names = []
    duration_ms = measure do
      files.each do |f|
        relative = @rdoc.relative_path_for(f)
        changed_file_names << relative
        begin
          @store.clear_file_contributions(relative, keep_position: true)
          @rdoc.parse_file(f)
          @file_mtimes[f] = RDoc.safe_mtime(f)
        rescue => e
          $stderr.puts "Error parsing #{f}: #{e.message}"
        end
      end

      @store.cleanup_stale_contributions
    end
    $stderr.puts "Re-parsed #{changed_file_names.join(', ')} (#{duration_ms}ms)"
  end

end
