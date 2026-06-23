# frozen_string_literal: true
##
# Handle common RDoc::Markup tasks for various CodeObjects
#
# This module is loaded by generators.  It allows RDoc's CodeObject tree to
# avoid loading generator code to improve startup time for +ri+.

module RDoc::Generator::Markup

  ##
  # Generates a relative URL from this object's path to +target_path+

  def aref_to(target_path)
    RDoc::Markup::ToHtml.gen_relative_url path, target_path
  end

  ##
  # Generates a relative URL from +from_path+ to this object's path

  def as_href(from_path)
    RDoc::Markup::ToHtml.gen_relative_url from_path, path
  end

  ##
  # Handy wrapper for marking up this object's comment

  def description
    markup @comment
  end

  ##
  # Creates an RDoc::Markup::ToHtmlCrossref formatter

  def formatter
    return @formatter if defined? @formatter

    options = @store.options
    this = RDoc::Context === self ? self : @parent

    @formatter = RDoc::Markup::ToHtmlCrossref.new(
      this.path, this,
      pipe: options.pipe,
      output_decoration: options.output_decoration,
      hyperlink_all: options.hyperlink_all,
      show_hash: options.show_hash,
      autolink_excluded_words: options.autolink_excluded_words || [],
      warn_missing_rdoc_ref: options.warn_missing_rdoc_ref
    )
    @formatter.code_object = self
    @formatter
  end

  ##
  # Build a webcvs URL starting for the given +url+ with +full_path+ appended
  # as the destination path.  If +url+ contains '%s' +full_path+ will be
  # will replace the %s using sprintf on the +url+.

  def cvs_url(url, full_path)
    if /%s/ =~ url then
      sprintf url, full_path
    else
      url + full_path
    end
  end

  ##
  # The preferred URL for this object.

  def canonical_url
    options = @store.options
    if path
      File.join(options.canonical_root, path.to_s)
    else
      options.canonical_root
    end
  end

end

class RDoc::CodeObject

  include RDoc::Generator::Markup

end

class RDoc::AnyMethod

  ##
  # Creates an HTML link to the superclass method called by this method.

  def superclass_method_link
    target = superclass_method
    return unless target

    html_formatter = formatter
    name = target.full_name

    html_formatter.link name, html_formatter.convert_string(name)
  end

end

class RDoc::MethodAttr

  ##
  # Prepend +src+ with line numbers.

  def add_line_numbers(src)
    return if src.empty? || !line
    start_line = line
    end_line  = start_line + src.count("\n")
    number_digits = end_line.to_s.length

    current_line = start_line
    src.gsub!(/^/) do
      res = "<span class=\"line-num\">#{current_line.to_s.rjust(number_digits)}</span> "

      current_line += 1
      res
    end
  end

  ##
  # Prepend +src+ with a comment that declares its location in the source.

  def add_location_comment(src)
    path = CGI.escapeHTML(file.relative_name)
    if options.line_numbers && !src.empty?
      src.prepend("<span class=\"ruby-comment\"># File #{path}</span>\n")
    else
      src.prepend("<span class=\"ruby-comment\"># File #{path}, line #{line}</span>\n")
    end
  end

  ##
  # Turns the method's token stream into HTML.
  #
  # Prepends line numbers if +options.line_numbers+ is true.

  def markup_code
    return '' if !@token_stream

    src = RDoc::TokenStream.to_html @token_stream

    # dedent the source
    common_indent = src.length
    src.scan(/^ *(?=\S)/) do |whitespace|
      common_indent = whitespace.length if whitespace.length < common_indent
      break if common_indent == 0
    end
    src.gsub!(/^#{' ' * common_indent}/, '') if common_indent > 0

    if source_language == 'ruby'
      add_line_numbers(src) if options.line_numbers
      add_location_comment(src)
    end

    src
  end

end

class RDoc::ClassModule

  ##
  # Handy wrapper for marking up this class or module's comment

  def description
    markup @comment_location
  end

end

class RDoc::Context::Section

  include RDoc::Generator::Markup

end

class RDoc::TopLevel

  ##
  # Returns a URL for this source file on some web repository.  Use the -W
  # command line option to set.

  def cvs_url
    url = @store.options.webcvs

    if /%s/ =~ url then
      url % @relative_name
    else
      url + @relative_name
    end
  end

end
