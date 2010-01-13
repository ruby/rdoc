require 'strscan'
require 'rdoc/text'

##
# A recursive-descent parser for RDoc markup.
#
# The parser tokenizes an input string then parses the tokens into a Document.
# Documents can be converted into output formats by writing a visitor like
# RDoc::Markup::ToHTML.
#
# The parser only handles the block-level constructs Paragraph, List,
# ListItem, Heading, Verbatim, BlankLine and Rule.  Inline markup such as
# <tt>+blah+</tt> is handled separately.
#
# To see what markup the Parser implements read RDoc.  To see how to use
# RDoc markup to format text in your program read RDoc::Markup.

class RDoc::Markup::Parser

  include RDoc::Text

  LIST_TOKENS = [
    :BULLET,
    :LABEL,
    :LALPHA,
    :NOTE,
    :NUMBER,
    :UALPHA,
  ]

  ##
  # Parser error subclass

  class Error < RuntimeError; end

  ##
  # Raised when the parser is unable to handle the given markup

  class ParseError < Error; end

  ##
  # An empty line

  class BlankLine
    def == other # :nodoc:
      self.class == other.class
    end

    def accept attribute_manager, visitor
      visitor.accept_blank_line attribute_manager, self
    end

    def pretty_print q # :nodoc:
      q.text 'blankline'
    end
  end

  ##
  # A Document containing lists, headings, paragraphs, etc.

  class Document

    ##
    # The parts of the Document

    attr_reader :parts

    ##
    # Creates a new Document with +parts+

    def initialize(*parts)
      @parts = []
      @parts.push(*parts)
    end

    def == other # :nodoc:
      self.class == other.class and @parts == other.parts
    end

    def accept(attribute_manager, visitor)
      visitor.start_accepting

      @parts.each do |item|
        item.accept attribute_manager, visitor
      end

      visitor.end_accepting
    end

    def empty?
      @parts.empty?
    end

    def pretty_print q # :nodoc:
      q.group 2, '[doc: ', ']' do
        q.seplist @parts do |part|
          q.pp part
        end
      end
    end
  end

  ##
  # A heading with a level (1-6) and text

  class Heading < Struct.new :level, :text
    def accept attribute_manager, visitor
      visitor.accept_heading attribute_manager, self
    end

    def pretty_print q # :nodoc:
      q.group 2, "[head: #{level} ", ']' do
        q.pp text
      end
    end
  end

  ##
  # A Paragraph of text

  class Paragraph

    ##
    # The component parts of the list

    attr_reader :parts

    ##
    # Creates a new Paragraph containing +parts+

    def initialize *parts
      @parts = []
      @parts.push(*parts)
    end

    ##
    # Appends +text+ to the Paragraph

    def << text
      @parts << text
    end

    def == other # :nodoc:
      self.class == other.class and text == other.text
    end

    def accept attribute_manager, visitor
      visitor.accept_paragraph attribute_manager, self
    end

    ##
    # Appends +other+'s parts into this Paragraph

    def merge other
      @parts.push(*other.parts)
    end

    def pretty_print q # :nodoc:
      self.class.name =~ /.*::(\w{4})/i

      q.group 2, "[#{$1.downcase}: ", ']' do
        q.seplist @parts do |part|
          q.pp part
        end
      end
    end

    ##
    # The text of this paragraph

    def text
      @parts.join ' '
    end
  end

  ##
  # A List of ListItems

  class List

    ##
    # The list's type

    attr_accessor :type

    ##
    # Items in the list

    attr_reader :items

    ##
    # Creates a new list of +type+ with +items+

    def initialize type = nil, *items
      @type = type
      @items = []
      @items.push(*items)
    end

    ##
    # Appends +item+ to the list

    def << item
      @items << item
    end

    def == other # :nodoc:
      self.class == other.class and
        @type == other.type and
        @items == other.items
    end

    def accept attribute_manager, visitor
      visitor.accept_list_start attribute_manager, self

      @items.each do |item|
        item.accept attribute_manager, visitor
      end

      visitor.accept_list_end attribute_manager, self
    end

    ##
    # Is the list empty?

    def empty?
      @items.empty?
    end

    ##
    # Returns the last item in the list

    def last
      @items.last
    end

    def pretty_print q # :nodoc:
      q.group 2, "[list: #{@type} ", ']' do
        q.seplist @items do |item|
          q.pp item
        end
      end
    end

    ##
    # Appends +items+ to the list

    def push *items
      @items.push(*items)
    end
  end

  ##
  # An item within a List that contains paragraphs, headings, etc.

  class ListItem

    ##
    # The label for the ListItem

    attr_accessor :label

    ##
    # Parts of the ListItem

    attr_reader :parts

    ##
    # Creates a new ListItem with an optional +label+ containing +parts+

    def initialize label = nil, *parts
      @label = label
      @parts = []
      @parts.push(*parts)
    end

    ##
    # Appends +part+ to the ListItem

    def << part
      @parts << part
    end

    def == other # :nodoc:
      self.class == other.class and
        @label == other.label and
        @parts == other.parts
    end

    def accept attribute_manager, visitor
      visitor.accept_list_item_start attribute_manager, self

      @parts.each do |part|
        part.accept attribute_manager, visitor
      end

      visitor.accept_list_item_end attribute_manager, self
    end

    ##
    # Is the ListItem empty?

    def empty?
      @parts.empty?
    end

    ##
    # Length of parts in the ListItem

    def length
      @parts.length
    end

    def pretty_print q # :nodoc:
      q.group 2, '[item: ', ']' do
        if @label then
          q.text @label
          q.breakable
        end

        q.seplist @parts do |part|
          q.pp part
        end
      end
    end

    ##
    # Adds +parts+ to the ListItem

    def push *parts
      @parts.push(*parts)
    end
  end

  ##
  # A section of verbatim text

  class Verbatim < Paragraph
    def accept attribute_manager, visitor
      visitor.accept_verbatim attribute_manager, self
    end

    ##
    # Collapses 3+ newlines into two newlines

    def normalize
      parts = []

      newlines = 0

      @parts.each do |part|
        case part
        when /\n/ then
          newlines += 1
          parts << part if newlines <= 2
        else
          newlines = 0
          parts << part
        end
      end

      parts.slice!(-1) if parts[-2..-1] == ["\n", "\n"]

      @parts = parts
    end

    ##
    # The text of the section

    def text
      @parts.join
    end
  end

  ##
  # A horizontal rule with a weight

  class Rule < Struct.new :weight
    def accept attribute_manager, visitor
      visitor.accept_rule attribute_manager, self
    end

    def pretty_print q # :nodoc:
      q.group 2, '[rule:', ']' do
        q.pp level
      end
    end
  end

  ##
  # Enables display of debugging information

  attr_accessor :debug

  ##
  # Token accessor

  attr_reader :tokens

  ##
  # Parsers +str+ into a Document

  def self.parse str
    parser = new
    #parser.debug = true
    parser.tokenize str
    Document.new(*parser.parse)
  end

  ##
  # Returns a token stream for +str+, for testing

  def self.tokenize str
    parser = new
    parser.tokenize str
    parser.tokens
  end

  ##
  # Creates a new Parser.  See also ::parse

  def initialize
    @tokens = []
    @current_token = nil
    @debug = false

    @line = 0
    @line_pos = 0
  end

  ##
  # Builds a Heading of +level+

  def build_heading level

    heading = Heading.new level, text
    skip :NEWLINE

    heading
  end

  ##
  # Builds a List flush to +margin+

  def build_list margin
    p :list_start => margin if @debug

    list = List.new

    until @tokens.empty? do
      type, data, column, = get

      case type
      when :BULLET, :LABEL, :LALPHA, :NOTE, :NUMBER, :UALPHA then
        list_type = type

        if column < margin then
          unget
          break
        end

        if list.type and list.type != list_type then
          unget
          break
        end

        list.type = list_type

        case type
        when :NOTE, :LABEL then
          _, indent, = get # SPACE
          if :NEWLINE == peek_token.first then
            get
            peek_type, new_indent, peek_column, = peek_token
            indent = new_indent if
              peek_type == :INDENT and peek_column >= column
            unget
          end
        else
          data = nil
          _, indent, = get
        end

        list_item = build_list_item(margin + indent, data)

        list << list_item if list_item
      else
        unget
        break
      end
    end

    p :list_end => margin if @debug

    return nil if list.empty?

    list
  end

  ##
  # Builds a ListItem that is flush to +indent+ with type +item_type+

  def build_list_item indent, item_type = nil
    p :list_item_start => [indent, item_type] if @debug

    list_item = ListItem.new item_type

    until @tokens.empty? do
      type, data, column = get

      if column < indent and
         not (type == :INDENT and data >= indent) then
        unget
        break
      end

      case type
      when :INDENT then
        unget
        list_item.push(*parse(indent))
      when :TEXT then
        unget
        list_item << build_paragraph(indent)
      when :HEADER then
        list_item << build_heading(data)
      when :NEWLINE then
        list_item << BlankLine.new
      when *LIST_TOKENS then
        unget
        list_item << build_list(column)
      else
        raise ParseError, "Unhandled token #{@current_token.inspect}"
      end
    end

    p :list_item_end => [indent, item_type] if @debug

    return nil if list_item.empty?

    list_item.parts.shift if BlankLine === list_item.parts.first and
                             list_item.length > 1

    list_item
  end

  ##
  # Builds a Paragraph that is flush to +margin+

  def build_paragraph margin
    p :paragraph_start => margin if @debug

    paragraph = Paragraph.new

    until @tokens.empty? do
      type, data, column, = get

      case type
      when :INDENT then
        next if data == margin and peek_token[0] == :TEXT

        unget
        break
      when :TEXT then
        if column != margin then
          unget
          break
        end

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
  # Builds a Verbatim that is flush to +margin+

  def build_verbatim margin
    p :verbatim_begin => margin if @debug
    verbatim = Verbatim.new

    until @tokens.empty? do
      type, data, column, = get

      case type
      when :INDENT then
        if margin >= data then
          unget
          break
        end

        indent = data - margin

        verbatim << ' ' * indent
      when :HEADER then
        verbatim << '=' * data

        _, _, peek_column, = peek_token
        verbatim << ' ' * (peek_column - column - data)
      when :RULE then
        width = 2 + data
        verbatim << '-' * width

        _, _, peek_column, = peek_token
        verbatim << ' ' * (peek_column - column - width)
      when :TEXT then
        verbatim << data
      when *LIST_TOKENS then
        if column <= margin then
          unget
          break
        end

        list_marker = case type
                      when :BULLET                   then '*'
                      when :LABEL                    then "[#{data}]"
                      when :LALPHA, :NUMBER, :UALPHA then "#{data}."
                      when :NOTE                     then "#{data}::"
                      end

        verbatim << list_marker

        _, data, = get

        verbatim << ' ' * (data - list_marker.length)
      when :NEWLINE then
        verbatim << data
        break unless [:INDENT, :NEWLINE].include? peek_token[0]
      else
        unget
        break
      end
    end

    verbatim.normalize

    p :verbatim_end => margin if @debug

    verbatim
  end

  ##
  # Pulls the next token from the stream.

  def get
    @current_token = @tokens.shift
    p :get => @current_token if @debug
    @current_token
  end

  ##
  # Parses the tokens into a Document

  def parse indent = 0
    p :parse_start => indent if @debug

    document = []

    until @tokens.empty? do
      type, data, = get

      case type
      when :HEADER then
        document << build_heading(data)
      when :INDENT then
        if indent > data then
          unget
          break
        elsif indent == data then
          next
        end

        unget
        document << build_verbatim(indent)
      when :NEWLINE then
        document << BlankLine.new
        skip :NEWLINE, false
      when :RULE then
        document << Rule.new(data)
        skip :NEWLINE
      when :TEXT then
        unget
        document << build_paragraph(indent)

        # we're done with this paragraph (indent mismatch)
        break if peek_token[0] == :TEXT
      when *LIST_TOKENS then
        unget

        list = build_list(indent)

        document << list if list

        # we're done with this list (indent mismatch)
        break if LIST_TOKENS.include? peek_token.first and indent > 0
      else
        type, data, column, line = @current_token
        raise ParseError,
              "Unhandled token #{type} (#{data.inspect}) at #{line}:#{column}"
      end
    end

    p :parse_end => indent if @debug

    document
  end

  ##
  # Returns the next token on the stream without modifying the stream

  def peek_token
    token = @tokens.first || []
    p :peek => token if @debug
    token
  end

  ##
  # Skips a token of +token_type+, optionally raising an error.

  def skip token_type, error = true
    type, data, = get

    return unless type # end of stream

    return @current_token if token_type == type

    unget

    raise ParseError, "expected #{token_type} got #{@current_token.inspect}" if
      error
  end

  ##
  # Consumes tokens until NEWLINE and turns them back into text

  def text
    text = ''

    loop do
      type, data, = get

      text << case type
              when :BULLET then
                _, space, = get # SPACE
                "*#{' ' * (space - 1)}"
              when :LABEL then
                _, space, = get # SPACE
                "[#{data}]#{' ' * (space - data.length - 2)}"
              when :LALPHA, :NUMBER, :UALPHA then
                _, space, = get # SPACE
                "#{data}.#{' ' * (space - 2)}"
              when :NOTE then
                _, space = get # SPACE
                "#{data}::#{' ' * (space - data.length - 2)}"
              when :TEXT then
                data
              when :NEWLINE then
                unget
                break
              when nil then
                break
              else
                raise ParseError, "unhandled token #{@current_token.inspect}"
              end
    end

    text
  end

  ##
  # Calculates the column and line of the current token based on +offset+.

  def token_pos offset
    [offset - @line_pos, @line]
  end

  ##
  # Turns text +input+ into a stream of tokens

  def tokenize input
    s = StringScanner.new input

    @line = 0
    @line_pos = 0

    until s.eos? do
      pos = s.pos

      @tokens << case
                 when s.scan(/\r?\n/) then
                   token = [:NEWLINE, s.matched, *token_pos(pos)]
                   @line_pos = s.pos
                   @line += 1
                   token
                 when s.scan(/ +/) then
                   [:INDENT, s.matched_size, *token_pos(pos)]
                 when s.scan(/(=+)\s+/) then
                   level = s[1].length
                   level = 6 if level > 6
                   @tokens << [:HEADER, level, *token_pos(pos)]

                   pos = s.pos
                   s.scan(/.*/)
                   [:TEXT, s.matched, *token_pos(pos)]
                 when s.scan(/^(-{3,}) *$/) then
                   [:RULE, s[1].length - 2, *token_pos(pos)]
                 when s.scan(/([*-])\s+/) then
                   @tokens << [:BULLET, :BULLET, *token_pos(pos)]
                   [:SPACE, s.matched_size, *token_pos(pos)]
                 when s.scan(/([a-z]|\d+)\.[ \t]+\S/i) then
                   list_label = s[1]
                   width      = s.matched_size - 1

                   s.pos -= 1 # unget \S

                   list_type = case list_label
                               when /[a-z]/ then :LALPHA
                               when /[A-Z]/ then :UALPHA
                               when /\d/    then :NUMBER
                               else
                                 raise ParseError, "BUG token #{list_label}"
                               end

                   @tokens << [list_type, list_label, *token_pos(pos)]
                   [:SPACE, width, *token_pos(pos)]
                 when s.scan(/\[(.*?)\]( +|$)/) then
                   @tokens << [:LABEL, s[1], *token_pos(pos)]
                   [:SPACE, s.matched_size, *token_pos(pos)]
                 when s.scan(/(.*?)::( +|$)/) then
                   @tokens << [:NOTE, s[1], *token_pos(pos)]
                   [:SPACE, s.matched_size, *token_pos(pos)]
                 else s.scan(/.*/)
                   [:TEXT, s.matched, *token_pos(pos)]
                 end
    end

    self
  end

  ##
  # Returns the current token or +token+ to the token stream

  def unget token = @current_token
    p :unget => token if @debug
    raise Error, 'too many #ungets' if token == @tokens.first
    @tokens.unshift token if token
  end

end

