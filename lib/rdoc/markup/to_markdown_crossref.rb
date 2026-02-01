# frozen_string_literal: true

##
# Subclass of the RDoc::Markup::ToMarkdown class that supports looking up method
# names, classes, etc to create links. RDoc::CrossReference is used to
# generate those links based on the current context.

class RDoc::Markup::ToMarkdownCrossref < RDoc::Markup::ToMarkdown

  # :stopdoc:
  ALL_CROSSREF_REGEXP = RDoc::CrossReference::ALL_CROSSREF_REGEXP
  CLASS_REGEXP_STR    = RDoc::CrossReference::CLASS_REGEXP_STR
  CROSSREF_REGEXP     = RDoc::CrossReference::CROSSREF_REGEXP
  METHOD_REGEXP_STR   = RDoc::CrossReference::METHOD_REGEXP_STR
  # :startdoc:

  ##
  # RDoc::CodeObject for generating references

  attr_accessor :context

  ##
  # Should we show '#' characters on method references?

  attr_accessor :show_hash

  ##
  # Creates a new crossref resolver that generates links relative to +context+
  # which lives at +from_path+ in the generated files. '#' characters on
  # references are removed unless +show_hash+ is true. Only method names
  # preceded by '#' or '::' are linked, unless +hyperlink_all+ is true.

  def initialize(options, from_path, context, markup = nil)
    raise ArgumentError, 'from_path cannot be nil' if from_path.nil?

    super markup

    @options       = options
    @context       = context
    @from_path     = from_path
    @hyperlink_all = @options.hyperlink_all
    @show_hash     = @options.show_hash
    @in_tidylink_label = false

    @cross_reference = RDoc::CrossReference.new @context

    init_link_notation_regexp_handlings
  end

  ##
  # Returns true if we are processing inside a tidy link label.

  def in_tidylink_label?
    @in_tidylink_label
  end

  # :nodoc:
  def init_link_notation_regexp_handlings
    # RDOCLINK already registered by ToMarkdown#initialize via add_regexp_handling_RDOCLINK
    crossref_re = @options.hyperlink_all ? ALL_CROSSREF_REGEXP : CROSSREF_REGEXP
    @markup.add_regexp_handling crossref_re, :CROSSREF
  end

  def handle_TIDYLINK(label_part, url)
    if url =~ /^rdoc-label:foot/ then
      emit_inline(handle_rdoc_link(url))
    elsif url =~ /\Ardoc-ref:/
      # Resolve rdoc-ref: URLs through cross-reference lookup
      @in_tidylink_label = true
      label_text = label_part.map { |n| String === n ? convert_string(n) : n }.join
      @in_tidylink_label = false
      emit_inline(gen_url(url, label_text))
    else
      emit_inline('[')
      @in_tidylink_label = true
      traverse_inline_nodes(label_part)
      @in_tidylink_label = false
      emit_inline("](#{url})")
    end
  end

  ##
  # Creates a link to the reference +name+ if the name exists. If +text+ is
  # given it is used as the link text, otherwise +name+ is used.

  def cross_reference(name, text = nil, code = true, rdoc_ref: false)
    lookup = name

    name = name[1..-1] unless @show_hash if name[0, 1] == '#'

    if !(name.end_with?('+@', '-@')) and name =~ /(.*[^#:])?@/
      text ||= [CGI.unescape($'), (" at `#{$1}`" if $~.begin(1))].join("")
      code = false
    else
      text ||= name
    end

    link lookup, text, code, rdoc_ref: rdoc_ref
  end

  ##
  # We're invoked when any text matches the CROSSREF pattern. If we find the
  # corresponding reference, generate a link. If the name we're looking for
  # contains no punctuation, we look for it up the module/class chain.

  def handle_regexp_CROSSREF(name)
    return convert_string(name) if in_tidylink_label?
    return name if @options.autolink_excluded_words&.include?(name)

    return name if name =~ /@[\w-]+\.[\w-]/ # labels that look like emails

    unless @hyperlink_all then
      return name if name =~ /\A[a-z]*\z/
    end

    cross_reference name, rdoc_ref: false
  end

  ##
  # Handles <tt>rdoc-ref:</tt> scheme links and allows RDoc::Markup::ToMarkdown to
  # handle other schemes.

  def handle_regexp_HYPERLINK(url)
    return convert_string(url) if in_tidylink_label?

    case url
    when /\Ardoc-ref:/
      cross_reference $', rdoc_ref: true
    else
      super
    end
  end

  ##
  # +target+ is an rdoc-schemed link that will be converted into a hyperlink.
  # For the rdoc-ref scheme the cross-reference will be looked up and the
  # given name will be used.

  def handle_regexp_RDOCLINK(url)
    case url
    when /\Ardoc-ref:/
      if in_tidylink_label?
        convert_string(url)
      else
        cross_reference $', rdoc_ref: true
      end
    else
      super
    end
  end

  ##
  # Generates links for <tt>rdoc-ref:</tt> scheme URLs and allows
  # RDoc::Markup::ToMarkdown to handle other schemes.

  def gen_url(url, text)
    if url =~ /\Ardoc-ref:/
      name = $'
      cross_reference name, text, name == text, rdoc_ref: true
    else
      super
    end
  end

  ##
  # Creates a Markdown link to +name+ with the given +text+.

  def link(name, text, code = true, rdoc_ref: false)
    if !(name.end_with?('+@', '-@')) and name =~ /(.*[^#:])?@/
      name = $1
      label = $'
    end

    ref = @cross_reference.resolve name, text if name

    case ref
    when String then
      if rdoc_ref && @options.warn_missing_rdoc_ref
        puts "#{@from_path}: `rdoc-ref:#{name}` can't be resolved for `#{text}`"
      end
      ref
    else
      # Suppress self-referential links
      if ref == @context
        return code ? "`#{text}`" : text
      end

      path = ref ? ref.as_href(@from_path) : +""

      # Convert .html to .md for markdown output
      path = path.sub(/\.html(?=#|$)/, '.md')

      if code and RDoc::CodeObject === ref and !(RDoc::TopLevel === ref)
        text = "`#{text}`"
      end

      if label
        formatted_label = RDoc::Text.to_anchor(label.tr('+', ' '))

        if path =~ /#/
          path << "-#{formatted_label}"
        elsif (section = ref&.sections&.find { |s| label.tr('+', ' ') == s.title })
          path << "##{section.aref}"
        elsif ref.respond_to?(:aref)
          path << "##{ref.aref}-#{formatted_label}"
        else
          path << "##{formatted_label}"
        end
      end

      "[#{text}](#{path})"
    end
  end

  def handle_TT(code)
    result = tt_cross_reference(code)
    if result
      emit_inline(result)
    else
      add_tag('code', '`', convert_string(code))
    end
  end

  def tt_cross_reference(code)
    return if in_tidylink_label?

    crossref_regexp = @options.hyperlink_all ? ALL_CROSSREF_REGEXP : CROSSREF_REGEXP
    match = crossref_regexp.match(code)
    return unless match && match.begin(1).zero?
    return unless match.post_match.match?(/\A[[:punct:]\s]*\z/)

    ref = cross_reference(code)
    ref if ref != code
  end
end
