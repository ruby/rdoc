require 'rdoc/markup/formatter'
require 'rdoc/markup/inline'

class RDoc::Markup::ToAnsi < RDoc::Markup::Formatter

  HEADINGS = {
    1 => ["\033[1;32m", "\033[m"],
    2 => ["\033[4;32m", "\033[m"],
    3 => ["\033[32m",   "\033[m"],
  }

  HEADINGS.default = []

  attr_accessor :indent
  attr_reader :list_index
  attr_reader :list_type
  attr_reader :list_width
  attr_reader :prefix
  attr_reader :res

  def initialize
    super

    @width = 78
    @prefix = ''
  end

  def accept_blank_line am, blank_line
    @res << "\n"
  end

  def accept_heading am, heading
    use_prefix or @res << ' ' * @indent
    @res << HEADINGS[heading.level][0]
    @res << heading.text 
    @res << HEADINGS[heading.level][1]
    @res << "\n"
  end

  def accept_list_end am, list
    @list_index.pop
    @list_type.pop
    @list_width.pop
  end

  def accept_list_item_end am, list_item
    width = case @list_type.last
            when :BULLET then
              1
            when :NOTE, :LABEL then
              list_item.label.length + 1
            else
              bullet = @list_index.last.to_s
              @list_index[-1] = @list_index.last.succ
              bullet.length + 1
            end

    @indent -= width + 1
  end

  def accept_list_item_start am, list_item
    bullet = case @list_type.last
             when :BULLET then
               '*'
             when :NOTE, :LABEL then
               list_item.label + ':'
             else
               @list_index.last.to_s + '.'
             end

    width = bullet.length + 1

    @prefix = (' ' * indent) + bullet.ljust(width)

    @indent += width
  end

  def accept_list_start am, list
    case list.type
    when :BULLET then
      @list_index << nil
      @list_width << 1
    when :LABEL, :NOTE then
      @list_index << nil
      @list_width << list.items.map { |item| item.label.length }.max + 1
    when :LALPHA then
      @list_index << 'a'
      @list_width << list.items.length.to_s.length
    when :NUMBER then
      @list_index << 1
      @list_width << list.items.length.to_s.length
    when :UALPHA then
      @list_index << 'A'
      @list_width << list.items.length.to_s.length
    else
      raise RDoc::Error, "invalid list type #{list.type}"
    end

    @list_type << list.type
  end

  def accept_paragraph am, paragraph
    wrap paragraph.text
  end

  def accept_rule am, rule
    use_prefix or @res << ' ' * @indent
    @res << '-' * (@width - @indent)
  end

  ##
  # HACK doesn't support verbatim sections like:
  #
  #    foo
  #   bar

  def accept_verbatim am, verbatim
    indent = ' ' * @indent

    bol = true

    verbatim.parts.each do |part|
      if bol and part =~ /^\s*$/ then
        bol = false
        use_prefix or @res << indent
        @res << '  '
      elsif part == "\n" then
        @res << "\n"
        bol = true
      else
        bol = false
        @res << part
      end
    end
  end

  def end_accepting
    @res.join
  end

  def start_accepting
    @res = []
    @indent = 0
    @prefix = nil

    @list_index = []
    @list_type  = []
    @list_width = []
  end

  def use_prefix
    prefix = @prefix
    @prefix = nil
    @res << prefix if prefix

    prefix
  end

  def wrap(text)
    return unless text && !text.empty?

    text_len = @width - @indent
    re = /^(.{0,#{text_len}})[ \n]/
    next_prefix = ' ' * @indent

    prefix = @prefix || next_prefix
    @prefix = nil

    @res << prefix

    while text.length > text_len
      if text =~ re then
        @res << $1
        text.slice!(0, $&.length)
      else
        @res << text.slice!(0, text_len)
      end

      @res << "\n" << next_prefix
    end

    if text.empty? then
      @res.pop
      @res.pop
    else
      @res << text
      @res << "\n"
    end
  end

end

