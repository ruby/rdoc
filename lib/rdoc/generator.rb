require 'rdoc'

##
# Namespace for generators

module RDoc::Generator

  ##
  # Generic options for HTML-type generators.
  #
  # Included automatically by ::html_options

  module HtmlOptions

    ##
    # Character-set for HTML output.  #encoding is preferred over #charset

    attr_accessor :charset

    ##
    # Old rdoc behavior: hyperlink all words that match a method name,
    # even if not preceded by '#' or '::'

    attr_accessor :hyperlink_all

    ##
    # Include line numbers in the source code

    attr_accessor :line_numbers

    ##
    # Name of the file, class or module to display in the initial index page (if
    # not specified the first file we encounter is used)

    attr_accessor :main_page

    ##
    # Include the '#' at the front of hyperlinked instance method names

    attr_accessor :show_hash

    ##
    # Template to be used when generating output

    attr_accessor :template

    ##
    # Documentation title

    attr_accessor :title

    ##
    # URL of web cvs frontend

    attr_accessor :webcvs

    ##
    # Set the title, but only if not already set. Used to set the title
    # from a source file, so that a title set from the command line
    # will have the priority.

    def default_title=(string)
      @title ||= string
    end

  end

  ##
  # Adds options for HTML-type generators to +options+.
  #
  # This includes <tt>--charset</tt>, <tt>--main</tt>, <tt>--show-hash</tt>,
  # <tt>--tab-width</tt>, <tt>--template</tt>, <tt>--title</tt>,
  # <tt>--webcvs</tt>.

  def self.html_options options
    options.extend HtmlOptions # HACK make this automatic

    opt = options.option_parser

    opt.separator 'HTML generators options:'
    opt.separator nil

    opt.on("--charset=CHARSET", "-c",
           "Specifies the output HTML character-set.",
           "Use --encoding instead of --charset if",
           "available.") do |value|
      options.charset = value
    end

    opt.separator nil

    opt.on("--hyperlink-all", "-A",
           "Generate hyperlinks for all words that",
           "correspond to known methods, even if they",
           "do not start with '#' or '::' (legacy",
           "behavior).") do |value|
      options.hyperlink_all = value
    end

    opt.separator nil

    opt.on("--main=NAME", "-m",
           "NAME will be the initial page displayed.") do |value|
      options.main_page = value
    end

    opt.separator nil

    opt.on("--[no-]line-numbers", "-N",
           "Include line numbers in the source code.",
           "By default, only the number of the first",
           "line is displayed, in a leading comment.") do |value|
      options.line_numbers = value
    end

    opt.separator nil

    opt.on("--show-hash", "-H",
           "A name of the form #name in a comment is a",
           "possible hyperlink to an instance method",
           "name. When displayed, the '#' is removed",
           "unless this option is specified.") do |value|
      options.show_hash = value
    end

    opt.separator nil

    opt.on("--template=NAME", "-T",
           "Set the template used when generating output.",
           "The default depends on the formatter used.") do |value|
      options.template = value
    end

    opt.separator nil

    opt.on("--title=TITLE", "-t",
           "Set TITLE as the title for HTML output.") do |value|
      options.title = value
    end

    opt.separator nil

    opt.on("--webcvs=URL", "-W",
           "Specify a URL for linking to a web frontend",
           "to CVS. If the URL contains a '\%s', the",
           "name of the current file will be",
           "substituted; if the URL doesn't contain a",
           "'\%s', the filename will be appended to it.") do |value|
      options.webcvs = value
    end

    opt.separator nil
  end

end

