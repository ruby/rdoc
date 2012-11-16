require 'rdoc'
require 'webrick'

class RDoc::Servlet < WEBrick::HTTPServlet::AbstractServlet

  @server_stores = Hash.new { |hash, server| hash[server] = {} }

  def self.get_instance server, *options
    stores = @server_stores[server]

    new server, stores, *options
  end

  def initialize server, stores
    super server

    @cache   = Hash.new { |hash, store| hash[store] = {} }
    @stores  = stores
    @options = RDoc::Options.new
    @options.op_dir = '.'

    darkfish_dir = nil

    # HACK dup
    $LOAD_PATH.each do |path|
      darkfish_dir = File.join path, 'rdoc/generator/template/darkfish/'
      next unless File.directory? darkfish_dir
      @options.template_dir = darkfish_dir
      break
    end

    @asset_dirs = {
      :darkfish   => darkfish_dir,
      :json_index =>
        File.expand_path('../generator/template/json_index/', __FILE__),
    }
  end

  def asset generator, req, res
    asset_dir = @asset_dirs[generator]

    asset_path = File.join asset_dir, req.path

    res.body = File.read asset_path

    res.content_type = case req.path
                       when /css$/ then 'text/css'
                       when /js$/  then 'application/javascript'
                       else             'application/octet-stream'
                       end
  end

  def do_GET req, res
    case req.path
    when '/' then
      root req, res
    when '/rdoc.css', '/js/darkfish.js', '/js/jquery.js', '/js/search.js',
         %r%^/images/% then
      asset :darkfish, req, res
    when '/js/navigation.js', '/js/searcher.js' then
      asset :json_index, req, res
    else
      show_documentation req, res
    end
  rescue => e
    error e, req, res
  end

  def documentation_source path
    _, source_name, path = path.split '/', 3

    store = @stores[source_name]
    return store, path if store

    store = case source_name
            when 'ruby' then
              RDoc::Store.new RDoc::RI::Paths.system_dir, :system
            else
              ri_dir, type = RDoc::RI::Paths.each.find do |dir, dir_type|
                next unless dir_type == :gem

                source_name == dir[%r%/([^/]*)/ri$%, 1]
              end

              raise "could not find ri documentation for #{source_name}" unless
                ri_dir

              RDoc::Store.new ri_dir, type
            end

    store.load_all

    @stores[source_name] = store

    return store, path
  end

  def error e, req, res
    backtrace = e.backtrace.join "\n"

    res.content_type = 'text/html'
    res.status = 500
    res.body = <<-BODY
<!DOCTYPE html>
<html>
<head>
<meta content="text/html; charset=UTF-8" http-equiv="Content-Type">

<title>Error - #{ERB::Util.html_escape e.class}</title>

<link type="text/css" media="screen" href="/rdoc.css" rel="stylesheet">
</head>
<body>
<h1>Error</h1>

<p>While processing <code>#{ERB::Util.html_escape req.request_uri}</code> the
RDoc server has encountered a <code>#{ERB::Util.html_escape e.class}</code>
exception:

<pre>#{ERB::Util.html_escape e.message}</pre>

<p>Backtrace:

<pre>#{ERB::Util.html_escape backtrace}</pre>

</body>
</html>
    BODY
  end

  def root req, res
    installed = RDoc::RI::Paths.each.map do |path, type|
      store = RDoc::Store.new path, type

      next unless File.exist? store.cache_path

      case type
      when :gem then
        gem_path = path[%r%/([^/]*)/ri$%, 1]
        [gem_path, "#{gem_path}/"]
      when :system then
        ['Ruby Documentation', 'ruby/']
      when :site then
        ['Site Documentation', 'site/']
      when :home then
        ['Home Documentation', 'home/']
      end
    end.compact

    generator = RDoc::Generator::Darkfish.new nil, @options

    res.body = generator.generate_servlet_root installed

    res.content_type = 'text/html'
  end

  def show_documentation req, res
    store, path = documentation_source req.path

    generator = RDoc::Generator::Darkfish.new store, @options
    generator.file_output = false
    generator.asset_rel_path = '..'

    rdoc = RDoc::RDoc.new
    rdoc.store = store
    rdoc.generator = generator
    rdoc.options = @options

    case path
    when nil, '', 'index.html' then
      res.body = generator.generate_index
    when 'table_of_contents.html' then
      res.body = generator.generate_table_of_contents
    when 'js/search_index.js' then
      json_index = @cache[store].fetch :json_index do
        @cache[store][:json_index] =
          JSON.dump generator.json_index.build_index
      end

      res.content_type = 'application/javascript'
      res.body = "var search_data = #{json_index}"
    else
      name = path.sub(/.html$/, '').gsub '/', '::'

      klass = store.find_class_or_module name

      res.body = generator.generate_class klass
    end

    res.content_type ||= 'text/html'
  end

end

