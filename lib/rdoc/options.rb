require 'optparse'

require 'rdoc/ri/paths'

##
# RDoc::Options handles the parsing and storage of options

class RDoc::Options

  ##
  # The deprecated options.

  DEPRECATED = {
    '--accessor'      => 'support discontinued',
    '--diagram'       => 'support discontinued',
    '--help-output'   => 'support discontinued',
    '--image-format'  => 'was an option for --diagram',
    '--inline-source' => 'source code is now always inlined',
    '--merge'         => 'ri now always merges class information',
    '--one-file'      => 'support discontinued',
    '--op-name'       => 'support discontinued',
    '--opname'        => 'support discontinued',
    '--promiscuous'   => 'files always only document their content',
    '--ri-system'     =>  'Ruby installers use other techniques',
  }

  ##
  # Character-set for HTML output.  #encoding is peferred over #charset

  attr_accessor :charset

  ##
  # If true, RDoc will not write any files.

  attr_accessor :dry_run

  ##
  # Encoding of output where.  This is set via --encoding.

  attr_accessor :encoding if Object.const_defined? :Encoding

  ##
  # Files matching this pattern will be excluded

  attr_accessor :exclude

  ##
  # The list of files to be processed

  attr_accessor :files

  ##
  # Create the output even if the output directory does not look
  # like an rdoc output directory

  attr_accessor :force_output

  ##
  # Scan newer sources than the flag file if true.

  attr_accessor :force_update

  ##
  # Formatter to mark up text with

  attr_accessor :formatter

  ##
  # Description of the output generator (set with the <tt>-fmt</tt> option)

  attr_accessor :generator

  ##
  # Include line numbers in the source code

  attr_accessor :hyperlink_all

  ##
  # Old rdoc behavior: hyperlink all words that match a method name,
  # even if not preceded by '#' or '::'

  attr_accessor :line_numbers

  ##
  # Name of the file, class or module to display in the initial index page (if
  # not specified the first file we encounter is used)

  attr_accessor :main_page

  ##
  # The name of the output directory

  attr_accessor :op_dir

  ##
  # The OptionParser for this instance

  attr_reader :opts

  ##
  # Is RDoc in pipe mode?

  attr_accessor :pipe

  ##
  # Array of directories to search for files to satisfy an :include:

  attr_accessor :rdoc_include

  ##
  # Include the '#' at the front of hyperlinked instance method names

  attr_accessor :show_hash

  ##
  # URL of the stylesheet to use. +nil+ by default.

  attr_accessor :stylesheet_url

  ##
  # The number of columns in a tab

  attr_accessor :tab_width

  ##
  # Template to be used when generating output

  attr_accessor :template

  ##
  # Documentation title

  attr_accessor :title

  ##
  # Verbosity, zero means quiet

  attr_accessor :verbosity

  ##
  # Minimum visibility of a documented method. One of +:public+,
  # +:protected+, +:private+. May be overridden on a per-method
  # basis with the :doc: directive.

  attr_accessor :visibility

  ##
  # URL of web cvs frontend

  attr_accessor :webcvs

  def initialize # :nodoc:
    require 'rdoc/rdoc'
    @dry_run = false
    @exclude = []
    @force_output = false
    @force_update = true
    @generator = RDoc::Generator::Darkfish
    @generator_name = nil
    @generators = RDoc::RDoc::GENERATORS
    @hyperlink_all = false
    @line_numbers = false
    @main_page = nil
    @op_dir = nil
    @pipe = false
    @rdoc_include = []
    @show_hash = false
    @stylesheet_url = nil
    @tab_width = 8
    @template = nil
    @title = nil
    @verbosity = 1
    @visibility = :protected
    @webcvs = nil

    if Object.const_defined? :Encoding then
      @encoding = Encoding.default_external
      @charset = @encoding.to_s
    else
      @charset = 'UTF-8'
    end
  end

  ##
  # Parse command line options.

  def parse(argv)
    ignore_invalid = true

    @opts = OptionParser.new do |opt|
      opt.program_name = File.basename $0
      opt.version = RDoc::VERSION
      opt.release = nil
      opt.summary_indent = ' ' * 4
      opt.banner = <<-EOF
Usage: #{opt.program_name} [options] [names...]

  Files are parsed, and the information they contain collected, before any
  output is produced. This allows cross references between all files to be
  resolved. If a name is a directory, it is traversed. If no names are
  specified, all Ruby files in the current directory (and subdirectories) are
  processed.

  How RDoc generates output depends on the output formatter being used, and on
  the options you give.

  Options can be specified via the RDOCOPT environment variable, which
  functions similar to the RUBYOPT environment variable for ruby.
  
    $ export RDOCOPT="--show-hash"
  
  will make rdoc show hashes in method links by default.  Command-line options
  always will override those in RDOCOPT.

  - Darkfish creates frameless HTML output by Michael Granger.
  - ri creates ri data files

  RDoc understands the following file formats:

      EOF

      parsers = Hash.new { |h,parser| h[parser] = [] }

      RDoc::Parser.parsers.each do |regexp, parser|
        parsers[parser.name.sub('RDoc::Parser::', '')] << regexp.source
      end

      parsers.sort.each do |parser, regexp|
        opt.banner << "  - #{parser}: #{regexp.join ', '}\n"
      end

      opt.banner << "\n  The following options are deprecated:\n\n"

      name_length = DEPRECATED.keys.sort_by { |k| k.length }.last.length

      DEPRECATED.sort_by { |k,| k }.each do |name, reason|
        opt.banner << "    %*1$2$s  %3$s\n" % [-name_length, name, reason]
      end

      opt.separator nil
      opt.separator "Parsing Options:"
      opt.separator nil

      if Object.const_defined? :Encoding then
        opt.on("--encoding=ENCODING", "-e", Encoding.list.map { |e| e.name },
               "Specifies the output encoding.  All files",
               "read will be converted to this encoding.",
               "Preferred over --charset") do |value|
                 @encoding = Encoding.find value
                 @charset = @encoding.to_s # may not be valid value
               end

        opt.separator nil
      end

      opt.on("--all", "-a",
             "Synonym for --visibility=private.") do |value|
        @visibility = :private
      end

      opt.separator nil

      opt.on("--exclude=PATTERN", "-x", Regexp,
             "Do not process files or directories",
             "matching PATTERN.") do |value|
        @exclude << value
      end

      opt.separator nil

      opt.on("--extension=NEW=OLD", "-E",
             "Treat files ending with .new as if they",
             "ended with .old. Using '-E cgi=rb' will",
             "cause xxx.cgi to be parsed as a Ruby file.") do |value|
        new, old = value.split(/=/, 2)

        unless new and old then
          raise OptionParser::InvalidArgument, "Invalid parameter to '-E'"
        end

        unless RDoc::Parser.alias_extension old, new then
          raise OptionParser::InvalidArgument, "Unknown extension .#{old} to -E"
        end
      end

      opt.separator nil

      opt.on("--[no-]force-update", "-U",
             "Forces rdoc to scan all sources even if",
             "newer than the flag file.") do |value|
        @force_update = value
      end

      opt.separator nil

      opt.on("--pipe",
             "Convert RDoc on stdin to HTML") do
        @pipe = true
      end

      opt.separator nil

      opt.on("--visibility=VISIBILITY", "-V", RDoc::VISIBILITIES,
             "Minimum visibility to document a method.",
             "One of 'public', 'protected' (the default) or",
             "'private'. Can be abbreviated.") do |value|
        @visibility = value
      end

      opt.separator nil
      opt.separator "Generator Options:"
      opt.separator nil

      opt.on("--charset=CHARSET", "-c",
             "Specifies the output HTML character-set.",
             "Use --encoding instead of --charset if",
             "available.") do |value|
        @charset = value
      end

      opt.separator nil

      opt.on("--force-output", "-O",
             "Forces rdoc to write the output files,",
             "even if the output directory exists",
             "and does not seem to have been created",
             "by rdoc.") do |value|
        @force_output = value
      end

      opt.separator nil

      generator_text = @generators.keys.map { |name| "  #{name}" }.sort

      opt.on("--fmt=FORMAT", "--format=FORMAT", "-f", @generators.keys,
             "Set the output formatter.  One of:", *generator_text) do |value|
        @generator_name = value.downcase
        setup_generator
      end

      opt.separator nil

      opt.on("--hyperlink-all", "-A",
             "Generate hyperlinks for all words that",
             "correspond to known methods, even if they",
             "do not start with '#' or '::' (legacy",
             "behavior).") do |value|
        @hyperlink_all = value
      end

      opt.separator nil

      opt.on("--include=DIRECTORIES", "-i", Array,
             "Set (or add to) the list of directories to",
             "be searched when satisfying :include:",
             "requests. Can be used more than once.") do |value|
        @rdoc_include.concat value.map { |dir| dir.strip }
      end

      opt.separator nil

      opt.on("--line-numbers", "-N",
             "Include line numbers in the source code.",
             "By default, only the number of the first",
             "line is displayed, in a leading comment.") do |value|
        @line_numbers = value
      end

      opt.separator nil

      opt.on("--main=NAME", "-m",
             "NAME will be the initial page displayed.") do |value|
        @main_page = value
      end

      opt.separator nil

      opt.on("--output=DIR", "--op", "-o",
             "Set the output directory.") do |value|
        @op_dir = value
      end

      opt.separator nil

      opt.on("--show-hash", "-H",
             "A name of the form #name in a comment is a",
             "possible hyperlink to an instance method",
             "name. When displayed, the '#' is removed",
             "unless this option is specified.") do |value|
        @show_hash = value
      end

      opt.separator nil

      opt.on("--style=URL", "-s",
             "Specifies the URL of a stylesheet to use",
             "in lieu of the default stylesheet of the",
             "template.") do |value|
        @stylesheet_url = value
      end

      opt.separator nil

      opt.on("--tab-width=WIDTH", "-w", OptionParser::DecimalInteger,
             "Set the width of tab characters.") do |value|
        @tab_width = value
      end

      opt.separator nil

      opt.on("--template=NAME", "-T",
             "Set the template used when generating",
             "output. The default is 'TODO'.") do |value|
        @template = value
      end

      opt.separator nil

      opt.on("--title=TITLE", "-t",
             "Set TITLE as the title for HTML output.") do |value|
        @title = value
      end

      opt.separator nil

      opt.on("--webcvs=URL", "-W",
             "Specify a URL for linking to a web frontend",
             "to CVS. If the URL contains a '\%s', the",
             "name of the current file will be",
             "substituted; if the URL doesn't contain a",
             "'\%s', the filename will be appended to it.") do |value|
        @webcvs = value
      end

      opt.separator nil

      opt.on("-d",
             "Deprecated --diagram option.",
             "Prevents firing debug mode",
             "with legacy invocation.") do |value|
      end

      opt.separator nil
      opt.separator "ri Generator Options:"
      opt.separator nil

      opt.on("--ri", "-r",
             "Generate output for use by `ri`. The files",
             "are stored in the '.rdoc' directory under",
             "your home directory unless overridden by a",
             "subsequent --op parameter, so no special",
             "privileges are needed.") do |value|
        @generator_name = "ri"
        @op_dir ||= RDoc::RI::Paths::HOMEDIR
        setup_generator
      end

      opt.separator nil

      opt.on("--ri-site", "-R",
             "Generate output for use by `ri`. The files",
             "are stored in a site-wide directory,",
             "making them accessible to others, so",
             "special privileges are needed.") do |value|
        @generator_name = "ri"
        @op_dir = RDoc::RI::Paths::SITEDIR
        setup_generator
      end

      opt.separator nil
      opt.separator "Generic Options:"
      opt.separator nil

      opt.on("--[no-]dry-run",
             "Don't write any files") do |value|
        @dry_run = value
      end

      opt.on("-D", "--[no-]debug",
             "Displays lots on internal stuff.") do |value|
        $DEBUG_RDOC = value
      end

      opt.on("--[no-]ignore-invalid",
             "Ignore invalid options and continue",
             "(default true).") do |value|
        ignore_invalid = value
      end

      opt.on("--quiet", "-q",
             "Don't show progress as we parse.") do |value|
        @verbosity = 0
      end

      opt.on("--verbose", "-v",
             "Display extra progress as we parse.") do |value|
        @verbosity = 2
      end

      opt.separator nil

    end

    argv.insert(0, *ENV['RDOCOPT'].split) if ENV['RDOCOPT']
    deprecated = []
    invalid = []

    begin
      @opts.parse! argv
    rescue OptionParser::InvalidArgument, OptionParser::InvalidOption => e
      if DEPRECATED[e.args.first]
        deprecated << e.args.first
      else
        invalid << e.args.join(' ')
      end
      retry
    end

    if @pipe and not argv.empty? then
      @pipe = false
      invalid << '-p (with files)'
    end

    unless quiet
      deprecated.each do |opt|
        $stderr.puts 'option ' << opt << ' is deprecated: ' << DEPRECATED[opt]
      end
      unless invalid.empty?
        invalid = "invalid options: #{invalid.join ', '}"
        if ignore_invalid
          $stderr.puts invalid
          $stderr.puts '(invalid options are ignored)'
        else
          $stderr.puts @opts
          $stderr.puts invalid
          exit 1
        end
      end
    end

    @op_dir ||= 'doc'
    @files = argv.dup

    @rdoc_include << "." if @rdoc_include.empty?

    if @exclude.empty? then
      @exclude = nil
    else
      @exclude = Regexp.new(@exclude.join("|"))
    end

    check_files

    # If no template was specified, use the default template for the output
    # formatter

    @template ||= @generator_name
  end

  ##
  # Set the title, but only if not already set. This means that a title set
  # from the command line trumps one set in a source file

  def title=(string)
    @title ||= string
  end

  ##
  # Don't display progress as we process the files

  def quiet
    @verbosity.zero?
  end

  def quiet=(bool)
    @verbosity = bool ? 0 : 1
  end

  private

  ##
  # Set up an output generator for the format in @generator_name
  #
  # If the found generator responds to :setup_options it will be called with
  # the options instance.  This allows generators to add custom options or set
  # default options.

  def setup_generator
    @generator = @generators[@generator_name]

    unless @generator then
      raise OptionParser::InvalidArgument, "Invalid output formatter"
    end

    @generator.setup_options self if @generator.respond_to? :setup_options
  end

  ##
  # Check that the files on the command line exist

  def check_files
    @files.each do |f|
      raise RDoc::Error, "file '#{f}' not found" unless File.exist?(f)
      stat = File.stat f
      raise RDoc::Error, "file '#{f}' not readable" unless stat.readable?
    end
  end

end

