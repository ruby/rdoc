require 'rdoc/markup/to_html'
require 'rdoc/cross_reference'

##
# Subclass of the RDoc::Markup::ToHtml class that supports looking up words
# from a context.  Those that are found will be linked.

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

  def initialize(from_path, context, show_hash, hyperlink_all = false,
                 markup = nil)
    raise ArgumentError, 'from_path cannot be nil' if from_path.nil?
    super markup

    crossref_re = hyperlink_all ? ALL_CROSSREF_REGEXP : CROSSREF_REGEXP

    @cross_reference = RDoc::CrossReference.new context, from_path

    @markup.add_special crossref_re, :CROSSREF
    @markup.add_special /rdoc:\S+\w/, :HYPERLINK

    @show_hash = show_hash
    @hyperlink_all = hyperlink_all
  end

  ##
  # Creates a link to the reference +name+ if the name exists.  If +text+ is
  # given it is used as the link text, otherwise +name+ is used.

  def cross_reference name, text = nil
    lookup = name

    name = name[1..-1] unless @show_hash if name[0, 1] == '#'

    text = name unless text

    @cross_reference.link lookup, text
  end

  ##
  # We're invoked when any text matches the CROSSREF pattern.  If we find the
  # corresponding reference, generate a link.  If the name we're looking for
  # contains no punctuation, we look for it up the module/class chain.  For
  # example, ToHtml is found, even without the <tt>RDoc::Markup::</tt> prefix,
  # because we look for it in module Markup first.

  def handle_special_CROSSREF(special)
    name = special.text

    unless @hyperlink_all then
      # This ensures that words entirely consisting of lowercase letters will
      # not have cross-references generated (to suppress lots of erroneous
      # cross-references to "new" in text, for instance)
      return name if name =~ /\A[a-z]*\z/
    end

    cross_reference name
  end

  ##
  # Handles <tt>rdoc-ref:</tt> scheme links and allows RDoc::Markup::ToHtml to
  # handle other schemes.

  def handle_special_HYPERLINK special
    return cross_reference $' if special.text =~ /\Ardoc-ref:/

    super
  end

  ##
  # Generates links for <tt>rdoc-ref:</tt> scheme URLs and allows
  # RDoc::Markup::ToHtml to handle other schemes.

  def gen_url url, text
    super unless url =~ /\Ardoc-ref:/

    cross_reference $', text
  end

end

