require 'abbrev'
require 'optparse'

begin
  require 'readline'
rescue LoadError
end

require 'rdoc/ri'
require 'rdoc/ri'
require 'rdoc/ri/paths'
require 'rdoc/markup'
require 'rdoc/markup/to_ansi'
require 'rdoc/text'

class RDoc::RI::Driver

  class Error < RDoc::RI::Error; end

  class NotFoundError < Error
    def message
      "Nothing known about #{super}"
    end
  end

  ##
  # Default options for ri

  def self.default_options
    options = {}
    options[:use_stdout] = !$stdout.tty?
    options[:width] = 72
    options[:interactive] = false
    options[:use_cache] = true
    options[:profile] = false

    # By default all standard paths are used.
    options[:use_system] = true
    options[:use_site] = true
    options[:use_home] = true
    options[:use_gems] = true
    options[:extra_doc_dirs] = []

    return options
  end

  ##
  # Parses +argv+ and returns a Hash of options

  def self.process_args argv
    options = default_options

    opts = OptionParser.new do |opt|
      opt.program_name = File.basename $0
      opt.version = RDoc::VERSION
      opt.release = nil
      opt.summary_indent = ' ' * 4

      opt.banner = <<-EOT
Usage: #{opt.program_name} [options] [names...]

Where name can be:

  Class | Class::method | Class#method | Class.method | method

All class names may be abbreviated to their minimum unambiguous form. If a name
is ambiguous, all valid options will be listed.

The form '.' method matches either class or instance methods, while #method
matches only instance and ::method matches only class methods.

For example:

    #{opt.program_name} Fil
    #{opt.program_name} File
    #{opt.program_name} File.new
    #{opt.program_name} zip

Note that shell quoting may be required for method names containing
punctuation:

    #{opt.program_name} 'Array.[]'
    #{opt.program_name} compact\\!

To see the default directories ri will search, run:

    #{opt.program_name} --list-doc-dirs

Specifying the --system, --site, --home, --gems or --doc-dir options will
limit ri to searching only the specified directories.

Options may also be set in the 'RI' environment variable.
      EOT

      opt.separator nil
      opt.separator "Options:"
      opt.separator nil

      opt.on("--doc-dir=DIRNAME", "-d", Array,
             "List of directories from which to source",
             "documentation in addition to the standard",
             "directories.  May be repeated.") do |value|
        value.each do |dir|
          unless File.directory? dir then
            raise OptionParser::InvalidArgument, "#{dir} is not a directory"
          end

          options[:extra_doc_dirs] << File.expand_path(dir)
        end
      end

      opt.separator nil

      opt.on("--[no-]use-cache",
             "Whether or not to use ri's cache.",
             "True by default.") do |value|
        options[:use_cache] = value
      end

      opt.separator nil

      opt.on("--no-standard-docs",
             "Do not include documentation from",
             "the Ruby standard library, site_lib,",
             "installed gems, or ~/.rdoc.",
             "Equivalent to specifying",
             "the options --no-system, --no-site, --no-gems,",
             "and --no-home") do
        options[:use_system] = false
        options[:use_site] = false
        options[:use_gems] = false
        options[:use_home] = false
      end

      opt.separator nil

      opt.on("--[no-]system",
             "Include documentation from Ruby's standard",
             "library.  Defaults to true.") do |value|
        options[:use_system] = value
      end

      opt.separator nil

      opt.on("--[no-]site",
             "Include documentation from libraries",
             "installed in site_lib.",
             "Defaults to true.") do |value|
        options[:use_site] = value
      end

      opt.separator nil

      opt.on("--[no-]gems",
             "Include documentation from RubyGems.",
             "Defaults to true.") do |value|
        options[:use_gems] = value
      end

      opt.separator nil

      opt.on("--[no-]home",
             "Include documentation stored in ~/.rdoc.",
             "Defaults to true.") do |value|
        options[:use_home] = value
      end

      opt.separator nil

      opt.on("--list-doc-dirs",
             "List the directories from which ri will",
             "source documentation on stdout and exit.") do
        options[:list_doc_dirs] = true
      end

      opt.separator nil

      opt.on("--no-pager", "-T",
             "Send output directly to stdout,",
             "rather than to a pager.") do
        options[:use_stdout] = true
      end

      opt.on("--interactive", "-i",
             "This makes ri go into interactive mode.",
             "When ri is in interactive mode it will",
             "allow the user to disambiguate lists of",
             "methods in case multiple methods match",
             "against a method search string.  It also",
             "will allow the user to enter in a method",
             "name (with auto-completion, if readline",
             "is supported) when viewing a class.") do
        options[:interactive] = true
      end

      opt.separator nil

      opt.on("--width=WIDTH", "-w", OptionParser::DecimalInteger,
             "Set the width of the output.") do |value|
        options[:width] = value
      end

      opt.separator nil

      opt.on("--[no-]profile",
             "Run with the ruby profiler") do |value|
        options[:profile] = value
      end
    end

    argv = ENV['RI'].to_s.split.concat argv

    opts.parse! argv

    options[:names] = argv

    options[:use_stdout] ||= !$stdout.tty?
    options[:use_stdout] ||= options[:interactive]
    options[:width] ||= 72

    options

  rescue OptionParser::InvalidArgument, OptionParser::InvalidOption => e
    puts opts
    puts
    puts e
    exit 1
  end

  ##
  # Runs the ri command line executable using +argv+

  def self.run argv = ARGV
    options = process_args argv
    ri = new options
    ri.run
  end

  def initialize initial_options = {}
    @classes = nil

    options = self.class.default_options.update(initial_options)

    require 'profile' if options[:profile]

    @names = options[:names]

    @doc_dirs = RDoc::RI::Paths.path(options[:use_system],
                                     options[:use_site],
                                     options[:use_home],
                                     options[:use_gems],
                                     options[:extra_doc_dirs])

    @homepath = RDoc::RI::Paths.raw_path(false, false, true, false).first
    @homepath = if options[:home] then
                  File.join options[:home], '.ri'
                else
                  @homepath.sub(/\.rdoc/, '.ri')
                end

    @sys_dir = RDoc::RI::Paths.raw_path(true, false, false, false).first
    @list_doc_dirs = options[:list_doc_dirs]

    @interactive = options[:interactive]
    @use_stdout  = options[:use_stdout]

    @stores = @doc_dirs.map do |path|
      store = RDoc::RI::Store.new path
      store.load_cache
      store
    end
  end

  def classes
    return @classes if @classes

    @classes = Hash.new { |h,k| h[k] = [] }

    @stores.each do |store|
      store.cache[:modules].each do |mod|
        @classes[mod] << store
      end
    end

    @classes
  end

  def complete name
    klasses = classes.keys

    case name
    when /(#|\.|::)([^A-Z]|$)/ then
      selector = $1
      name_prefix = $2

      methods = []

      klass, type, method = if name_prefix.empty? then
                              [$`, '']
                            else
                              parse_name name
                            end

      # HACK refactor
      classes[klass].each do |store|
        if selector =~ /#|\./ then
          cache = store.instance_methods[klass]

          if cache then
            methods += cache.select do |method_name|
              method_name =~ /^#{method}/
            end.map do |method_name|
              "#{klass}##{method_name}"
            end
          end
        end

        if selector =~ /::|\./ then
          cache = store.class_methods[klass]

          if cache then
            methods += cache.select do |method_name|
              method_name =~ /^#{method}/
            end.map do |method_name|
              "#{klass}::#{method_name}"
            end
          end
        end
      end

      # TODO ancestor lookup

      if selector == '::' and methods.empty? then
        methods += klasses.grep(/^#{klass}::/)
      end

      methods
    when /^[A-Z]\w*/ then
      klasses.grep(/^#{name}/)
    else
      []
    end
  end

  ##
  # Converts +document+ to text and writes it to the pager

  def display document
    text = document.accept(RDoc::Markup::AttributeManager.new,
                           RDoc::Markup::ToAnsi.new)

    page do |io|
      io.write text
    end
  end

  def display_class name
    return if name =~ /#|\./

    name = expand_class name

    found = @stores.map do |store|
      begin
        [store.path, store.load_class(name)]
      rescue Errno::ENOENT
      end
    end.compact

    return if found.empty?

    out = RDoc::Markup::Parser::Document.new

    out.parts << RDoc::Markup::Parser::Heading.new(1, name)
    out.parts << RDoc::Markup::Parser::BlankLine.new

    found.each do |path, klass|
      out.parts << RDoc::Markup::Parser::Paragraph.new("(from #{path})")
      out.parts << RDoc::Markup::Parser::Rule.new(1)
      out.parts << RDoc::Markup::Parser::BlankLine.new
      out.parts.push(*klass.comment.parts)
      out.parts << RDoc::Markup::Parser::BlankLine.new
    end

    display out
  end

  def display_method name
    klass, type, method = parse_name name

    types = if type == '.' then
              :both
            elsif type == '#' then
              :instance
            else
              :class
            end

    found = @stores.map do |store|
      methods = []
      case types
      when :instance then
        methods << load_method(store, :instance_methods, klass, '#',  method)
      when :class then
        methods << load_method(store, :class_methods,    klass, '::', method)
      else
        methods << load_method(store, :instance_methods, klass, '#',  method)
        methods << load_method(store, :class_methods,    klass, '::', method)
      end

      [store.path, methods.compact]
    end

    found = found.reject do |path, methods| methods.empty? end

    raise NotFoundError, name if found.empty?

    out = RDoc::Markup::Parser::Document.new

    out.parts << RDoc::Markup::Parser::Heading.new(1, name)
    out.parts << RDoc::Markup::Parser::BlankLine.new

    found.each do |path, methods|
      methods.each do |method|
        out.parts << RDoc::Markup::Parser::Paragraph.new("(from #{path})")
        out.parts << RDoc::Markup::Parser::Rule.new(1)
        out.parts << RDoc::Markup::Parser::BlankLine.new
        out.parts.push(*method.comment.parts)
        out.parts << RDoc::Markup::Parser::BlankLine.new
      end
    end

    display out
  end

  def display_name name
    return if display_class name

    display_method name if name =~ /::|#|\./
  end

  ##
  # Expands abbreviated klass +klass+ into a fully-qualified klass.  "Zl::Da"
  # will be expanded to Zlib::DataError.

  def expand_class klass
    klass.split('::').inject '' do |expanded, klass_part|
      expanded << '::' unless expanded.empty?
      short = expanded << klass_part

      subset = classes.keys.select do |klass_name|
        klass_name =~ /^#{expanded}[^:]*$/
      end

      abbrevs = Abbrev.abbrev subset

      expanded = abbrevs[short]

      raise NotFoundError, short unless expanded

      expanded.dup
    end
  end

  ##
  # Runs ri interactively using Readline if it is available.

  def interactive
    if defined? Readline then
      # prepare abbreviations for tab completion
      Readline.completion_proc = method :complete
    end

    puts "\nEnter the method name you want to look up."

    if defined? Readline then
      puts "You can use tab to autocomplete."
    end

    puts "Enter a blank line to exit.\n\n"

    loop do
      name = if defined? Readline then
               Readline.readline ">> "
             else
               print ">> "
               $stdin.gets
             end

      return if name.nil? or name.empty?

      name = name.strip

      begin
        display_name name
      rescue NotFoundError => e
        puts e.message
      end
    end

  rescue Interrupt
    exit
  end

  def load_method store, cache, klass, type, name
    method = store.send(cache)[klass].find do |method_name|
      method_name == name
    end

    return unless method

    store.load_method klass, "#{type}#{method}"
  end

  ##
  # Paginates output through a pager program.

  def page
    if pager = setup_pager then
      begin
        yield pager
      ensure
        pager.close
      end
    else
      yield $stdout
    end
  rescue Errno::EPIPE
  end

  ##
  # Extract the class and method name parts from +name+ like Foo::Bar#baz

  def parse_name(name)
    parts = name.split(/(::|\#|\.)/)

    if parts[-2] != '::' or parts.last !~ /^[A-Z]/ then
      meth = parts.pop
      type = parts.pop
    end

    klass = parts.join

    [klass, type, meth]
  end

  ##
  # Looks up and displays ri data according to the options given.

  def run
    if @list_doc_dirs then
      puts @doc_dirs
    elsif @interactive then
      interactive
    elsif @names.empty? then
      @display.list_known_classes class_cache.keys.sort
    else
      @names.each do |name|
        display_name name
      end
    end
  rescue NotFoundError => e
    abort e.message
  end

  ##
  # Sets up a pager program to pass output through.  Tries the PAGER
  # environment variable, followed by pager, less then more.

  def setup_pager
    unless @use_stdout then
      for pager in [ENV['PAGER'], 'pager', 'less', 'more'].compact.uniq
        return IO.popen(pager, "w") rescue nil
      end

      @use_stdout = true

      nil
    end
  end

end

