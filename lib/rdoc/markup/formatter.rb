require 'rdoc/markup'

##
# Base class for RDoc markup formatters
#
# Formatters use a visitor pattern to convert content into output.

class RDoc::Markup::Formatter

  InlineTag = Struct.new(:bit, :on, :off)

  ##
  # Creates a new Formatter

  def initialize
    @markup = RDoc::Markup.new

    @in_tt = 0
    @tt_bit = RDoc::Markup::Attribute.bitmap_for :TT
  end

  ##
  # Add a new set of HTML tags for an attribute. We allow separate start and
  # end tags for flexibility

  def add_tag(name, start, stop)
    attr = RDoc::Markup::Attribute.bitmap_for(name), start, stop
    @attr_tags << InlineTag.new(attr)
  end

  ##
  # Marks up +content+

  def convert(content)
    @markup.convert content, self
  end

  ##
  # Converts flow items +flow+

  def convert_flow(flow)
    res = []

    flow.each do |item|
      case item
      when String then
        res << convert_string(item)
      when RDoc::Markup::AttrChanger then
        off_tags res, item
        on_tags res, item
      when RDoc::Markup::Special then
        res << convert_special(item)
      else
        raise "Unknown flow element: #{item.inspect}"
      end
    end

    res.join
  end

  ##
  # Converts added specials.  See RDoc::Markup#add_special

  def convert_special(special)
    handled = false

    RDoc::Markup::Attribute.each_name_of special.type do |name|
      method_name = "handle_special_#{name}"

      if respond_to? method_name then
        special.text = send method_name, special
        handled = true
      end
    end

    raise "Unhandled special: #{special}" unless handled

    special.text
  end

  ##
  # Are we currently inside tt tags?

  def in_tt?
    @in_tt > 0
  end

  ##
  # Set up the standard mapping of attributes to HTML tags

  def init_tags
    @attr_tags = [
      InlineTag.new(RDoc::Markup::Attribute.bitmap_for(:BOLD), "<b>", "</b>"),
      InlineTag.new(RDoc::Markup::Attribute.bitmap_for(:TT),   "<tt>", "</tt>"),
      InlineTag.new(RDoc::Markup::Attribute.bitmap_for(:EM),   "<em>", "</em>"),
    ]
  end

  def on_tags res, item
    attr_mask = item.turn_on
    return if attr_mask.zero?

    @attr_tags.each do |tag|
      if attr_mask & tag.bit != 0
        res << annotate(tag.on)
        @in_tt += 1 if tt? tag
      end
    end
  end

  def off_tags res, item
    attr_mask = item.turn_off
    return if attr_mask.zero?

    @attr_tags.reverse_each do |tag|
      if attr_mask & tag.bit != 0 then
        @in_tt -= 1 if tt? tag
        res << annotate(tag.off)
      end
    end
  end

  ##
  # Is +tag+ a tt tag?

  def tt? tag
    tag.bit == @tt_bit
  end

end

