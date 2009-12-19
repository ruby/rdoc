require 'strscan'
require 'rdoc/text'

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

  class Error < RuntimeError; end
  class ParseError < Error; end

  class BlankLine
    def == other
      self.class == other.class
    end

    def accept attribute_manager, visitor
      visitor.accept_blank_line attribute_manager, self
    end

    def pretty_print q
      q.text 'blankline'
    end
  end

  class Document
    attr_reader :parts

    def initialize(*parts)
      @parts = []
      @parts.push(*parts)
    end

    def == other
      self.class == other.class and @parts == other.parts
    end


    def accept(attribute_manager, visitor)
      visitor.start_accepting

      @parts.each do |item|
        item.accept attribute_manager, visitor
      end

      visitor.end_accepting
    end

    def pretty_print q
      q.group 2, '[doc: ', ']' do
        q.seplist @parts do |part|
          q.pp part
        end
      end
    end
  end

  class Heading < Struct.new :level, :text
    def accept attribute_manager, visitor
      visitor.accept_heading attribute_manager, self
    end

    def pretty_print q
      q.group 2, "[head: #{level} ", ']' do
        q.pp text
      end
    end
  end

  class Paragraph

    attr_reader :parts

    def initialize *parts
      @parts = []
      @parts.push(*parts)
    end

    def << text
      @parts << text
    end

    def == other
      self.class == other.class and text == other.text
    end

    def accept attribute_manager, visitor
      visitor.accept_paragraph attribute_manager, self
    end

    def merge other
      @parts.push(*other.parts)
    end

    def pretty_print q
      self.class.name =~ /.*::(\w{4})/i

      q.group 2, "[#{$1.downcase}: ", ']' do
        q.seplist @parts do |part|
          q.pp part
        end
      end
    end

    def text
      @parts.join ' '
    end
  end

  class List
    attr_accessor :type
    attr_reader :items

    def initialize type = nil, *items
      @type = type
      @items = []
      @items.push(*items)
    end

    def << item
      @items << item
    end

    def == other
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

    def empty?
      @items.empty?
    end

    def last
      @items.last
    end

    def pretty_print q
      q.group 2, "[list: #{@type} ", ']' do
        q.seplist @items do |item|
          q.pp item
        end
      end
    end

    def push *items
      @items.push(*items)
    end
  end

  class ListItem
    attr_accessor :label
    attr_reader :parts

    def initialize label = nil, *parts
      @label = label
      @parts = []
      @parts.push(*parts)
    end

    def << part
      @parts << part
    end

    def == other
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

    def empty?
      @parts.empty?
    end

    def length
      @parts.length
    end

    def pretty_print q
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

    def push *parts
      @parts.push(*parts)
    end
  end

  class Verbatim < Paragraph
    def accept attribute_manager, visitor
      visitor.accept_verbatim attribute_manager, self
    end

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

    def text
      @parts.join
    end
  end

  class Rule < Struct.new :weight
    def accept attribute_manager, visitor
      visitor.accept_rule attribute_manager, self
    end

    def pretty_print q
      q.group 2, '[rule:', ']' do
        q.pp level
      end
    end
  end

  attr_accessor :debug
  attr_reader :tokens

  def self.parse str
    parser = new
    #parser.debug = true
    parser.tokenize str
    Document.new(*parser.parse)
  end

  def self.tokenize str
    parser = new
    parser.tokenize str
    parser.tokens
  end

  def initialize
    @tokens = []
    @current_token = nil
    @debug = false

    @line = 0
    @line_pos = 0
  end

  def build_heading level
    heading = Heading.new level, text
    skip :NEWLINE

    heading
  end

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

  def get
    @current_token = @tokens.shift
    p :get => @current_token if @debug
    @current_token
  end

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

  def peek_token
    token = @tokens.first || []
    p :peek => token if @debug
    token
  end

  def skip token_type, error = true
    type, data, = get

    return unless type

    if type != token_type then
      raise ParseError, "expected #{token_type} got #{@current_token.inspect}" if error

      unget
      return nil
    end

    @current_token
  end

  def text
    type, data, = get

    raise ParseError, "expected TEXT got #{@current_token.inspect}" unless
      type == :TEXT

    data
  end

  def token_pos offset
    [offset - @line_pos, @line]
  end

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
                   [:HEADER, level, *token_pos(pos)]
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

  def unget token = @current_token
    p :unget => token if @debug
    @tokens.unshift token if token
  end

end

