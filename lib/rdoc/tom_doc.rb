##
# A parser for TomDoc based on TomDoc 1.0.0-pre (d38f5da7)
#
# The TomDoc format can be found at:
#
# http://tomdoc.org
#
# The latest version of the TomDoc format can be found at:
#
# https://github.com/mojombo/tomdoc/blob/master/tomdoc.md

class RDoc::TomDoc < RDoc::Markup::Parser

  ##
  # Token accessor

  attr_reader :tokens

  ##
  # Adds a post-processor which sets the RDoc section based on the comment's
  # status.

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

  ##
  # Parses TomDoc from +text+

  def self.parse text
    parser = new

    parser.tokenize text
    doc = RDoc::Markup::Document.new
    parser.parse doc
    doc
  end

  ##
  # Builds a Paragraph.

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

  ##
  # Turns text +input+ into a stream of tokens

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
                 when s.scan(/(Examples)$/) then
                   @tokens << [:HEADER, 3, *token_pos(pos)]

                   [:TEXT, 'Examples', *token_pos(pos)]
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

