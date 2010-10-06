require 'rdoc'

##
# Namespace for generators

module RDoc::Generator

  module HtmlOptions

    ##
    # Character-set for HTML output.  #encoding is peferred over #charset

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
    # URL of web cvs frontend

    attr_accessor :webcvs

  end

  def self.html_options options
    options.extend HtmlOptions # HACK make this automatic

    opt = options.option_parser

    opt.separator nil
    opt.separator 'Darkfish generator options:'
    opt.separator nil

    opt.on("--charset=CHARSET", "-c",
           "Specifies the output HTML character-set.",
           "Use --encoding instead of --charset if",
           "available.") do |value|
      options.charset = value
    end

    opt.separator nil

    opt.on("--main=NAME", "-m",
           "NAME will be the initial page displayed.") do |value|
      options.main_page = value
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

    opt.on("--style=URL", "-s",
           "Specifies the URL of a stylesheet to use",
           "in lieu of the default stylesheet of the",
           "template.") do |value|
      options.stylesheet_url = value
    end

    opt.separator nil

    opt.on("--tab-width=WIDTH", "-w", OptionParser::DecimalInteger,
           "Set the width of tab characters.") do |value|
      options.tab_width = value
    end

    opt.separator nil

    opt.on("--template=NAME", "-T",
           "Set the template used when generating",
           "output. The default is 'TODO'.") do |value|
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

