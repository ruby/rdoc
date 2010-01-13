require 'abbrev'
require 'optparse'

begin
  require 'readline'
rescue LoadError
end

require 'rdoc/ri'
require 'rdoc/ri/paths'
require 'rdoc/markup'
require 'rdoc/markup/to_ansi'
require 'rdoc/text'

##
# For RubyGems backwards compatibility
require 'rdoc/ri/formatter'

##
# The RI driver implements the command-line ri tool.
#
# The driver supports:
# * loading RI data from:
#   * Ruby's standard library
#   * RubyGems
#   * ~/.rdoc
#   * A user-supplied directory
# * Paging output (uses PAGER environment variable or the less, more and
#   pager programs)
# * Interactive mode with tab-completion
# * Abbreviated names (ri Zl shows Zlib documentation)
# * Colorized output
# * Merging output from multiple RI data sources

class RDoc::RI::Driver

  ##
  # Base Driver error class

  class Error < RDoc::RI::Error; end

  ##
  # Raised when a name isn't found in the ri data stores

  class NotFoundError < Error

    ##
    # Name that wasn't found

    alias name message

    def message # :nodoc:
      "Nothing known about #{super}"
    end

  end

  attr_accessor :stores

  ##
  # Controls the user of the pager vs $stdout

  attr_accessor :use_stdout

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

      opt.separator nil

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

      opt.separator "Deprecated Options: (these warn)"
      opt.separator nil

      opt.on("--format=NAME", "-f") do
        warn "-f (--format) is deprecated"
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

  ##
  # Creates a new driver using +initial_options+ from ::process_args

  def initialize initial_options = {}
    @paging = false
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

  ##
  # Returns ancestor classes of +klass+

  def ancestors_of klass
    ancestors = []

    unexamined = [klass]

    loop do
      break if unexamined.empty?
      current = unexamined.shift

      stores = classes[current]

      break unless stores and not stores.empty?

      klasses = stores.map { |store| store.ancestors[current] }.flatten

      ancestors.push(*klasses)
      unexamined.push(*klasses)
    end

    ancestors.reverse
  end

  ##
  # For RubyGems backwards compatibility

  def class_cache # :nodoc:
  end

  ##
  # Hash mapping a known class or module to the stores it can be loaded from

  def classes
    return @classes if @classes

    @classes = {}

    @stores.each do |store|
      store.cache[:modules].each do |mod|
        # using default block causes searched-for modules to be added
        @classes[mod] ||= []
        @classes[mod] << store
      end
    end

    @classes
  end

  ##
  # Completes +name+ based on the caches.  For Readline

  def complete name
    klasses = classes.keys
    completions = []

    klass, selector, method = parse_name name

    # may need to include Foo when given Foo::
    klass_name = method ? name : klass

    if name !~ /#|\./ then
      completions.push(*klasses.grep(/^#{klass_name}/))
    elsif selector then
      completions << klass if classes.key? klass
    elsif classes.key? klass_name then
      completions << klass_name
    end

    if completions.include? klass and name =~ /#|\.|::/ then
      methods = list_methods_matching name

      if not methods.empty? then
        # remove Foo if given Foo:: and a method was found
        completions.delete klass
      elsif selector then
        # replace Foo with Foo:: as given
        completions.delete klass
        completions << "#{klass}#{selector}" 
      end

      completions.push(*methods)
    end

    completions.sort
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

  ##
  # Outputs formatted RI data for class +name+

  def display_class name
    return if name =~ /#|\./

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
      if klass.comment then
        out.parts.push(*klass.comment.parts)
      else
        out.parts << RDoc::Markup::Parser::Paragraph.new("[Not documented]")
      end
      out.parts << RDoc::Markup::Parser::BlankLine.new
    end

    display out
  end

  ##
  # Outputs formatted RI data for method +name+

  def display_method name
    found = load_methods_matching name

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

  ##
  # Outputs formatted RI data for the class or method +name+.
  #
  # Returns true if +name+ was found, false if it was not an alternative could
  # be guessed, raises an error if +name+ couldn't be guessed.

  def display_name name
    return true if display_class name

    display_method name if name =~ /::|#|\./

    true
  rescue NotFoundError
    matches = list_methods_matching name if name =~ /::|#|\./
    matches = classes.keys.grep(/^#{name}/) if matches.empty?

    raise if matches.empty?

    page do |io|
      io.puts "#{name} not found, maybe you meant:"
      io.puts
      io.puts matches.join("\n")
    end

    false
  end

  ##
  # Expands abbreviated klass +klass+ into a fully-qualified class.  "Zl::Da"
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
  # Expands the class portion of +name+ into a fully-qualified class.  See
  # #expand_class.

  def expand_name name
    klass, selector, method = parse_name name

    "#{expand_class klass}#{selector}#{method}"
  end

  ##
  # Yields items matching +name+ including the store they were found in, the
  # class being searched for, the class they were found in (an ancestor) the
  # types of methods to look up (from #method_type), and the method name being
  # searched for

  def find_methods name
    klass, selector, method = parse_name name

    types = method_type selector

    klasses = ancestors_of klass

    klasses.unshift klass

    klasses.each do |ancestor|
      ancestors = classes[ancestor]

      next unless ancestors

      ancestors.each do |store|
        yield store, klass, ancestor, types, method
      end
    end

    self
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

      name = expand_name name.strip

      begin
        display_name name
      rescue NotFoundError => e
        puts e.message
      end
    end

  rescue Interrupt
    exit
  end

  ##
  # Loads RI data for method +name+ on +klass+ from +store+.  +type+ and
  # +cache+ indicate if it is a class or instance method.

  def load_method store, cache, klass, type, name
    methods = store.send(cache)[klass]

    return unless methods

    method = methods.find do |method_name|
      method_name == name
    end

    return unless method

    store.load_method klass, "#{type}#{method}"
  end

  ##
  # Lists classes known to ri

  def list_known_classes
    classes = []

    stores.each do |store|
      classes << store.modules
    end

    classes = classes.flatten.uniq.sort

    page do |io|
      if paging? or io.tty? then
        io.puts "Classes and Modules known to ri:"
        io.puts
      end

      io.puts classes.join("\n")
    end
  end

  ##
  # Returns an Array of methods matching +name+

  def list_methods_matching name
    found = []

    find_methods name do |store, klass, ancestor, types, method|
      if types == :instance or types == :both then
        methods = store.instance_methods[ancestor]

        if methods then
          matches = methods.grep(/^#{method}/)

          matches = matches.map do |match|
            "#{klass}##{match}"
          end

          found.push(*matches)
        end
      end

      if types == :class or types == :both then
        methods = store.class_methods[ancestor]

        next unless methods
        matches = methods.grep(/^#{method}/)

        matches = matches.map do |match|
          "#{klass}::#{match}"
        end

        found.push(*matches)
      end
    end

    found.uniq
  end

  ##
  # Returns an Array of RI data for methods matching +name+

  def load_methods_matching name
    found = []

    find_methods name do |store, klass, ancestor, types, method|
      methods = []

      methods << load_method(store, :class_methods, ancestor, '::',  method) if
        types == :class or types == :both

      methods << load_method(store, :instance_methods, ancestor, '#',  method) if
        types == :instance or types == :both

      found << [store.path, methods.compact]
    end

    found.reject do |path, methods| methods.empty? end
  end

  ##
  # Returns the type of method (:both, :instance, :class) for +selector+

  def method_type selector
    case selector
    when '.', nil then :both
    when '#'      then :instance
    else               :class
    end
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
  ensure
    @paging = false
  end

  ##
  # Are we using a pager?

  def paging?
    @paging
  end

  ##
  # Extract the class, selector and method name parts from +name+ like
  # Foo::Bar#baz.
  #
  # NOTE: Given Foo::Bar, Bar is considered a class even though it may be a
  #       method

  def parse_name(name)
    parts = name.split(/(::|#|\.)/)

    if parts.length == 1 then
      type = nil
      meth = nil
    elsif parts.length == 2 or parts.last =~ /::|#|\./ then
      type = parts.pop
      meth = nil
    elsif parts[-2] != '::' or parts.last !~ /^[A-Z]/ then
      meth = parts.pop
      type = parts.pop
    end

    klass = parts.join

    [klass, type, meth]
  end

  ##
  # Looks up and displays ri data according to the options given.

  def run
    trap 'INFO' do
      puts caller[1]
    end

    if @list_doc_dirs then
      puts @doc_dirs
    elsif @interactive then
      interactive
    elsif @names.empty? then
      list_known_classes
    else
      @names.each do |name|
        name = expand_name name

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
    return if @use_stdout

    [ENV['PAGER'], 'pager', 'less', 'more'].compact.uniq.each do |pager|
      io = IO.popen(pager, "w") rescue next

      @paging = true

      return io
    end

    @use_stdout = true

    nil
  end

end

