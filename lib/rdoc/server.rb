# frozen_string_literal: true

require 'socket'
require 'json'
require 'erb'
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
        var lastChange = #{last_change_time};
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

    @generator = create_generator
    @page_cache = {}
    @search_index_cache = nil
    @last_change_time = Time.now.to_f
    @mutex = Mutex.new
    @running = false
  end

  ##
  # Starts the server.  Blocks until interrupted.

  def start
    @tcp_server = TCPServer.new('127.0.0.1', @port)
    @running = true

    @watcher_thread = start_watcher(@rdoc.last_modified.keys)

    url = "http://localhost:#{@port}"
    $stderr.puts "\nServing documentation at: \e]8;;#{url}\e\\#{url}\e]8;;\e\\"
    $stderr.puts "Press Ctrl+C to stop.\n\n"

    loop do
      client = @tcp_server.accept
      Thread.new(client) { |c| handle_client(c) }
    rescue IOError
      break
    end
  end

  ##
  # Shuts down the server.

  def shutdown
    @running = false
    @tcp_server&.close
    @watcher_thread&.join(2)
  end

  private

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

    status, content_type, body = route(path)
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
  end

  ##
  # Serves a static asset (CSS, JS) from the Aliki template directory.

  def serve_asset(path)
    rel_path = path.sub(%r{\A/}, '')
    asset_path = File.join(@generator.template_dir, rel_path)
    real_asset = File.expand_path(asset_path)
    real_template = File.expand_path(@generator.template_dir)

    unless real_asset.start_with?("#{real_template}/") && File.file?(real_asset)
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
    name = path.sub(%r{\A/}, '')
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
      build_search_index
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
  # Builds the search index JavaScript.

  def build_search_index
    @search_index_cache ||=
      "var search_data = #{JSON.generate(index: @generator.build_search_index)};"
  end

  ##
  # Injects the live-reload polling script before +</body>+.

  def inject_live_reload(html, last_change_time)
    html.sub('</body>', "#{self.class.live_reload_script(last_change_time)}</body>")
  end

  ##
  # Clears all cached HTML pages and the search index.

  def invalidate_all_caches
    @page_cache.clear
    @search_index_cache = nil
  end

  ##
  # Starts a background thread that polls source file mtimes and triggers
  # re-parsing when changes are detected.

  def start_watcher(source_files)
    @file_mtimes = source_files.each_with_object({}) do |f, h|
      h[f] = File.mtime(f) rescue nil
    end

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

  ##
  # Checks for modified, new, and deleted files.  Returns true if any
  # changes were found and processed.

  def check_for_changes
    changed = []
    removed = []

    @file_mtimes.each do |file, old_mtime|
      unless File.exist?(file)
        removed << file
        next
      end

      current_mtime = File.mtime(file) rescue nil
      next unless current_mtime
      changed << file if old_mtime.nil? || current_mtime > old_mtime
    end

    file_list = @rdoc.normalized_file_list(
      @options.files.empty? ? [@options.root.to_s] : @options.files,
      true, @options.exclude
    )
    file_list = @rdoc.remove_unparseable(file_list)
    file_list.each_key do |file|
      unless @file_mtimes.key?(file)
        @file_mtimes[file] = nil # will be updated after parse
        changed << file
      end
    end

    return false if changed.empty? && removed.empty?

    reparse_and_refresh(changed, removed)
    true
  end

  ##
  # Re-parses changed files, removes deleted files from the store,
  # refreshes the generator, and invalidates caches.

  def reparse_and_refresh(changed_files, removed_files)
    @mutex.synchronize do
      unless removed_files.empty?
        $stderr.puts "Removed: #{removed_files.join(', ')}"
        removed_files.each do |f|
          @file_mtimes.delete(f)
          relative = @rdoc.relative_path_for(f)
          @store.clear_file_contributions(relative)
          @store.remove_file(relative)
        end
      end

      unless changed_files.empty?
        $stderr.puts "Re-parsing: #{changed_files.join(', ')}"
        changed_files.each do |f|
          begin
            relative = @rdoc.relative_path_for(f)
            @store.clear_file_contributions(relative)
            @rdoc.parse_file(f)
            @file_mtimes[f] = File.mtime(f) rescue nil
          rescue => e
            $stderr.puts "Error parsing #{f}: #{e.message}"
          end
        end
      end

      @store.complete(@options.visibility)

      @generator.refresh_store_data
      invalidate_all_caches
      @last_change_time = Time.now.to_f
    end
  end

end
