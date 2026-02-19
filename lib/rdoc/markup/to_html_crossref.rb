# frozen_string_literal: true
##
# Subclass of the RDoc::Markup::ToHtml class that supports looking up method
# names, classes, etc to create links.  RDoc::CrossReference is used to
# generate those links based on the current context.

class RDoc::Markup::ToHtmlCrossref < RDoc::Markup::ToHtml

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
  # which lives at +from_path+ in the generated files.  '#' characters on
  # references are removed unless +show_hash+ is true.  Only method names
  # preceded by '#' or '::' are linked, unless +hyperlink_all+ is true.

  def initialize(options, from_path, context, markup = nil)
    raise ArgumentError, 'from_path cannot be nil' if from_path.nil?

    super options, markup

    @context       = context
    @from_path     = from_path
    @hyperlink_all = @options.hyperlink_all
    @show_hash     = @options.show_hash

    @cross_reference = RDoc::CrossReference.new @context
  end

  # :nodoc:
  def init_link_notation_regexp_handlings
    add_regexp_handling_RDOCLINK

    # The crossref must be linked before tidylink because Klass.method[:sym]
    # will be processed as a tidylink first and will be broken.
    crossref_re = @options.hyperlink_all ? ALL_CROSSREF_REGEXP : CROSSREF_REGEXP
    @markup.add_regexp_handling crossref_re, :CROSSREF
  end

  ##
  # Creates a link to the reference +name+ if the name exists.  If +text+ is
  # given it is used as the link text, otherwise +name+ is used.

  def cross_reference(name, text = nil, code = true, rdoc_ref: false)
    lookup = name

    name = name[1..-1] unless @show_hash if name[0, 1] == '#'

    if !name.end_with?('+@', '-@') && match = name.match(/(.*[^#:])?@(.*)/)
      context_name = match[1]
      label = convert_string(RDoc::Text.decode_legacy_label(match[2]))
      text ||= "#{label} at <code>#{convert_string(context_name)}</code>" if context_name
      text ||= label
      code = false
    else
      text ||= convert_string(name)
    end

    create_html_link lookup, text, code, rdoc_ref: rdoc_ref
  end

  ##
  # We're invoked when any text matches the CROSSREF pattern.  If we find the
  # corresponding reference, generate a link.  If the name we're looking for
  # contains no punctuation, we look for it up the module/class chain.  For
  # example, ToHtml is found, even without the <tt>RDoc::Markup::</tt> prefix,
  # because we look for it in module Markup first.

  def handle_regexp_CROSSREF(name)
    return convert_string(name) if in_tidylink_label?
    return name if @options.autolink_excluded_words&.include?(name)

    return name if name =~ /@[\w-]+\.[\w-]/ # labels that look like emails

    unless @hyperlink_all then
      # This ensures that words entirely consisting of lowercase letters will
      # not have cross-references generated (to suppress lots of erroneous
      # cross-references to "new" in text, for instance)
      return name if name =~ /\A[a-z]*\z/
    end

    # Even if name is not a crossref, RDoc removes prefix '#' here. Maybe bug.
    fallback_name = @show_hash ? name : name.delete_prefix('#')

    cross_reference(name, rdoc_ref: false) || convert_string(fallback_name)
  end

  ##
  # Handles <tt>rdoc-ref:</tt> scheme links and allows RDoc::Markup::ToHtml to
  # handle other schemes.

  def handle_regexp_HYPERLINK(url)
    return convert_string(url) if in_tidylink_label?

    case url
    when /\Ardoc-ref:/
      ref = $'
      cross_reference(ref, rdoc_ref: true) || convert_string(ref)
    else
      super
    end
  end

  ##
  # +target+ is an rdoc-schemed link that will be converted into a hyperlink.
  # For the rdoc-ref scheme the cross-reference will be looked up and the
  # given name will be used.
  #
  # All other contents are handled by
  # {the superclass}[rdoc-ref:RDoc::Markup::ToHtml#handle_regexp_RDOCLINK]

  def handle_regexp_RDOCLINK(url)
    case url
    when /\Ardoc-ref:/
      if in_tidylink_label?
        convert_string(url)
      else
        ref = $'
        cross_reference(ref, rdoc_ref: true) || convert_string(ref)
      end
    else
      super
    end
  end

  ##
  # Generates links for <tt>rdoc-ref:</tt> scheme URLs and allows
  # RDoc::Markup::ToHtml to handle other schemes.

  def gen_url(url, text)
    if url =~ /\Ardoc-ref:/
      name = $'
      cross_reference(name, text, name == text, rdoc_ref: true) || text
    else
      super
    end
  end

  ##
  # Creates an HTML link to +name+ with the given +text+.
  # Called from html generators.

  def link(name, text)
    create_html_link(name, convert_string(text))
  end

  # Creates an HTML link to +name+ with the given html +text+.

  def create_html_link(name, text, code = true, rdoc_ref: false)
    if !(name.end_with?('+@', '-@')) and name =~ /(.*[^#:])?@/
      name = $1
      label = $'
    end

    ref = @cross_reference.resolve(name) if name

    if name && ref.nil?
      if rdoc_ref && @options.warn_missing_rdoc_ref
        puts "#{@from_path}: `rdoc-ref:#{name}` can't be resolved for `#{text}`"
      end
      nil
    else
      path = ref ? ref.as_href(@from_path) : +""

      if code and RDoc::CodeObject === ref and !(RDoc::TopLevel === ref)
        text = "<code>#{text}</code>"
      end

      if label
        # Decode legacy labels (e.g., "What-27s+Here" -> "What's Here")
        # then convert to GitHub-style anchor format
        decoded_label = RDoc::Text.decode_legacy_label(label)
        formatted_label = RDoc::Text.to_anchor(decoded_label)

        # Case 1: Path already has an anchor (e.g., method link)
        #   Input:  C1#method@label -> path="C1.html#method-i-m"
        #   Output: C1.html#method-i-m-label
        if path =~ /#/
          path << "-#{formatted_label}"

        # Case 2: Label matches a section title
        #   Input:  C1@Section -> path="C1.html", section "Section" exists
        #   Output: C1.html#section (uses section.aref for GitHub-style)
        elsif (section = ref&.sections&.find { |s| decoded_label == s.title })
          path << "##{section.aref}"

        # Case 3: Ref has an aref (class/module context)
        #   Input:  C1@heading -> path="C1.html", ref=C1 class
        #   Output: C1.html#class-c1-heading
        elsif ref.respond_to?(:aref)
          path << "##{ref.aref}-#{formatted_label}"

        # Case 4: No context, just the label (e.g., TopLevel/file)
        #   Input:  README@section -> path="README_md.html"
        #   Output: README_md.html#section
        else
          path << "##{formatted_label}"
        end
      end

      "<a href=\"#{path}\">#{text}</a>"
    end
  end

  def handle_TT(code)
    emit_inline(tt_cross_reference(code) || "<code>#{convert_string(code)}</code>")
  end

  # Applies additional special handling on top of the one defined in ToHtml.
  # When a tidy link is <tt>{Foo}[rdoc-ref:Foo]</tt>, the label part is surrounded by <tt><code></code></tt>.
  # TODO: reconsider this workaround.
  def apply_tidylink_label_special_handling(label, url)
    if url == "rdoc-ref:#{label}" && cross_reference(label)&.include?('<code>')
      "<code>#{convert_string(label)}</code>"
    else
      super
    end
  end

  # Handles cross-reference and suppressed-crossref inside tt tag.
  # Returns nil if code is not a cross-reference nor a suppressed-crossref.
  def tt_cross_reference(code)
    return if in_tidylink_label?

    crossref_regexp = @options.hyperlink_all ? ALL_CROSSREF_REGEXP : CROSSREF_REGEXP
    # REGEXP sometimes matches to a string starts with backslash which is not a suppressed crossref. (e.g. `\+`)
    # We need to check the backslash removed part matches to crossref_regexp
    match = crossref_regexp.match(code.delete_prefix('\\'))
    return unless match && match.begin(1).zero?
    return unless match.post_match.match?(/\A[[:punct:]\s]*\z/)

    if code.start_with?('\\')
      # Remove leading backslash if crossref exists
      "<code>#{convert_string(code[1..])}</code>" if cross_reference(code[1..])
    else
      # Even if code is not a crossref, RDoc removes prefix '#' here. Maybe bug.
      # `<tt>#comment</tt>` will be rendered as `<tt>comment</tt>`
      fallback_code = @show_hash ? code : code.delete_prefix('#')

      cross_reference(code) || "<code>#{convert_string(fallback_code)}</code>"
    end
  end
end
