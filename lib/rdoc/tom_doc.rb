# :markup: tomdoc

# A parser for TomDoc based on TomDoc 1.0.0-rc1 (02adef9b5a)
#
# The TomDoc specification can be found at:
#
# http://tomdoc.org
#
# The latest version of the TomDoc specification can be found at:
#
# https://github.com/mojombo/tomdoc/blob/master/tomdoc.md
#
# There are a few differences between this parser and the specification.  A
# best-effort was made to follow the specification as closely as possible but
# some choices to deviate were made.
#
# A future version of RDoc will warn when a MUST or MUST NOT is violated and
# may warn when a SHOULD or SHOULD NOT is violated.  RDoc will always try
# to emit documentation even if given invalid TomDoc.
#
# Here are some implementation choices this parser currently makes:
#
# This parser allows rdoc-style inline markup but you should not depended on
# it.
#
# This parser allows a space between the comment and the method body.
#
# This parser does not require the default value to be described for an
# optional argument.
#
# This parser does not examine the order of sections.  An Examples section may
# precede the Arguments section.
#
# This class is documented in TomDoc format.  Since this is a subclass of the
# RDoc markup parser there isn't much to see here, unfortunately.

class RDoc::TomDoc < RDoc::Markup::Parser

  # Internal: Token accessor

  attr_reader :tokens

  # Internal: Adds a post-processor which sets the RDoc section based on the
  # comment's status.
  #
  # Returns nothing.

  def self.add_post_processor # :nodoc:
    RDoc::Markup::PreProcess.post_process do |comment, code_object|
      next unless code_object and
                  RDoc::Comment === comment and comment.format == 'tomdoc'

      comment.text.gsub!(/(\A\s*# )(Public|Internal|Deprecated):\s+/) do
        section = code_object.add_section $2
        code_object.temporary_section = section

        $1
      end
    end
  end

  add_post_processor

  # Parses TomDoc from text
  #
  # text - A String containing TomDoc-format text.
  #
  # Examples
  #
  #   RDoc::TomDoc.parse <<-TOMDOC
  #   This method does some things
  #
  #   Returns nothing.
  #   TOMDOC
  #
  # Returns an RDoc::Markup::Document representing the TomDoc format.

  def self.parse text
    parser = new

    parser.tokenize text
    doc = RDoc::Markup::Document.new
    parser.parse doc
    doc
  end

  # Internal: Builds a paragraph from the token stream
  #
  # margin - Unused
  #
  # Returns an RDoc::Markup::Paragraph.

  def build_paragraph margin
    p :paragraph_start => margin if @debug

    paragraph = RDoc::Markup::Paragraph.new

    until @tokens.empty? do
      type, data, = get

      if type == :TEXT then
        paragraph << data
        skip :NEWLINE
      else
        unget
        break
      end
    end

    p :paragraph_end => margin if @debug

    paragraph
  end

  # Internal: Turns text into an Array of tokens
  #
  # text - A String containing TomDoc-format text.
  #
  # Returns self.

  def tokenize text
    text.sub!(/\A(Public|Internal|Deprecated):\s+/, '')

    s = StringScanner.new text

    @line = 0
    @line_pos = 0

    until s.eos? do
      pos = s.pos

      # leading spaces will be reflected by the column of the next token
      # the only thing we loose are trailing spaces at the end of the file
      next if s.scan(/ +/)

      @tokens << case
                 when s.scan(/\r?\n/) then
                   token = [:NEWLINE, s.matched, *token_pos(pos)]
                   @line_pos = s.pos
                   @line += 1
                   token
                 when s.scan(/(Examples|Signature)$/) then
                   @tokens << [:HEADER, 3, *token_pos(pos)]

                   [:TEXT, s[1], *token_pos(pos)]
                 when s.scan(/([:\w]\w*)[ ]+- /) then
                   [:NOTE, s[1], *token_pos(pos)]
                 else
                   s.scan(/.*/)
                   [:TEXT, s.matched.sub(/\r$/, ''), *token_pos(pos)]
                 end
    end

    self
  end

end

