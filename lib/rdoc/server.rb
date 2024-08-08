# frozen_string_literal: true
require 'erb'
require 'time'
require 'json'

class RDoc::Server < WEBrick::HTTPServlet::AbstractServlet
  ##
  # Creates an instance of this servlet that shares cached data between
  # requests.

  def self.get_instance server, rdoc # :nodoc:
    new server, rdoc
  end

  ##
  # Creates a new WEBrick servlet.
  #
  # +server+ is provided automatically by WEBrick when mounting.
  # +rdoc+ is the RDoc::RDoc instance to display documentation from.

  def initialize server, rdoc
    super server

    @rdoc = rdoc
    @generator = rdoc.generator
    @generator.file_output = false

    darkfish_dir = File.join(__dir__, 'generator/template/darkfish/')
    json_index_dir = File.join(__dir__, 'generator/template/json_index/')

    @asset_dirs = {
      :darkfish   => darkfish_dir,
      :json_index => json_index_dir,
    }
  end

  ##
  # GET request entry point.  Fills in +res+ for the path, etc. in +req+.

  def do_GET req, res
    req.path.sub!(/\A\//, '')

    case req.path
    when '/'
      res.body = @generator.generate_servlet_root installed_docs
      res.content_type = 'text/html'
    when 'js/darkfish.js', 'js/jquery.js', 'js/search.js', %r{^css/}, %r{^images/}, %r{^fonts/}
      asset :darkfish, req, res
    when 'js/navigation.js', 'js/searcher.js'
      asset :json_index, req, res
    when 'js/search_index.js'
      res.body = "var search_data = #{JSON.dump @generator.json_index.build_index}"
      res.content_type = 'application/javascript'
    else
      show_documentation req, res
    end
  rescue WEBrick::HTTPStatus::NotFound => e
    not_found @generator, req, res, e.message
  rescue WEBrick::HTTPStatus::Status
    raise
  rescue => e
    $stderr.puts e.full_message
    error e, req, res
  end

  private

  def asset generator_name, req, res
    asset_dir = @asset_dirs[generator_name]

    asset_path = File.join asset_dir, req.path

    res.body = File.read asset_path

    res.content_type = case req.path
                       when /\.css\z/ then 'text/css'
                       when /\.js\z/  then 'application/javascript'
                       else                'application/octet-stream'
                       end
  end

  PAGE_NAME_SUB_REGEXP = /_([^_]*)\z/

  def documentation_page store, generator, path, req, res
    text_name = path.chomp '.html'
    name = text_name.gsub '/', '::'

    content = if klass = store.find_class_or_module(name)
      generator.generate_class klass
    elsif page = store.find_text_page(name.sub(PAGE_NAME_SUB_REGEXP, '.\1'))
      generator.generate_page page
    elsif page = store.find_text_page(text_name.sub(PAGE_NAME_SUB_REGEXP, '.\1'))
      generator.generate_page page
    elsif page = store.find_file_named(text_name.sub(PAGE_NAME_SUB_REGEXP, '.\1'))
      generator.generate_page page
    end

    if content
      res.body = content
    else
      not_found generator, req, res
    end
  end

  def error exception, req, res
    backtrace = exception.backtrace.join "\n"

    res.content_type = 'text/html'
    res.status = 500
    res.body = <<-BODY
<!DOCTYPE html>
<html>
<head>
<meta content="text/html; charset=UTF-8" http-equiv="Content-Type">

<title>Error - #{ERB::Util.html_escape exception.class}</title>

<link type="text/css" media="screen" href="/css/rdoc.css" rel="stylesheet">
</head>
<body>
<h1>Error</h1>

<p>While processing <code>#{ERB::Util.html_escape req.request_uri}</code> the
RDoc (#{ERB::Util.html_escape RDoc::VERSION}) server has encountered a
<code>#{ERB::Util.html_escape exception.class}</code>
exception:

<pre>#{ERB::Util.html_escape exception.message}</pre>

<p>Please report this to the
<a href="https://github.com/ruby/rdoc/issues">RDoc issues tracker</a>.  Please
include the RDoc version, the URI above and exception class, message and
backtrace.  If you're viewing a gem's documentation, include the gem name and
version.  If you're viewing Ruby's documentation, include the version of ruby.

<p>Backtrace:

<pre>#{ERB::Util.html_escape backtrace}</pre>

</body>
</html>
    BODY
  end

  def not_found generator, req, res, message = nil
    message ||= "The page <kbd>#{ERB::Util.h req.path}</kbd> was not found"
    res.body = generator.generate_servlet_not_found message
    res.status = 404
  end

  def show_documentation req, res
    # Clear all the previous data
    @rdoc.store.classes_hash.clear
    @rdoc.store.modules_hash.clear
    @rdoc.store.files_hash.clear

    # RDoc instance use last_modified list to avoid reparsing files
    # We need to clear it to force reparsing
    @rdoc.last_modified.clear

    # Reparse the files
    @rdoc.parse_files(@rdoc.options.files)

    # Regenerate the documentation and asserts
    @generator.generate_for_server

    case req.path
    when nil, '', 'index.html'
      res.body = @generator.generate_index
    when 'table_of_contents.html'
      res.body = @generator.generate_table_of_contents
    else
      documentation_page @rdoc.store, @generator, req.path, req, res
    end
  ensure
    res.content_type ||= 'text/html'
  end
end
