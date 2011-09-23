##
# Outputs RDoc markup as paragraphs with inline markup only.

class RDoc::Markup::ToHtmlSnippet < RDoc::Markup::ToHtml

  ##
  # After this many characters the input will be cut off.

  attr_reader :limit

  ##
  # The number of characters seen so far.

  attr_reader :chars # :nodoc:

  ##
  # The attribute bitmask

  attr_reader :mask

  ##
  # Creates a new ToHtmlSnippet formatter that will cut off the input on the
  # next word boundary after +limit+ characters.

  def initialize limit = 100, markup = nil
    super markup

    @limit = limit
    @chars = 0
    @mask  = 0

    @markup.add_special RDoc::CrossReference::CROSSREF_REGEXP, :CROSSREF
  end

  ##
  # Adds +heading+ to the output as a paragraph

  def accept_heading heading
    @res << "<p>#{to_html heading.text}\n"
  end

  ##
  # Raw content is untrusted and ignored.

  def accept_raw raw
  end

  ##
  # Rules are ignored

  def accept_rule rule
  end

  def accept_paragraph paragraph
    para = @in_list_entry.last || "<p>"

    @res << "#{para}#{wrap to_html paragraph.text}\n"
  end

  ##
  # Finishes consumption of +list_item+

  def accept_list_item_end list_item
  end

  ##
  # Prepares the visitor for consuming +list_item+

  def accept_list_item_start list_item
    @res << list_item_start(list_item, @list.last)
  end

  ##
  # Prepares the visitor for consuming +list+

  def accept_list_start list
    @list << list.type
    @res << html_list_name(list.type, true)
    @in_list_entry.push ''
  end

  ##
  # Adds +verbatim+ to the output

  def accept_verbatim verbatim
    input = verbatim.text.rstrip
    text = truncate input

    super RDoc::Markup::Verbatim.new text

    @res << '...' unless text == input
  end

  ##
  # Prepares the visitor for HTML snippet generation

  def start_accepting
    super

    @chars = 0
  end

  def handle_special_CROSSREF special
    special.text.sub(/\A\\/, '')
  end

  ##
  # Lists are paragraphs, but notes and labels have a separator

  def list_item_start list_item, list_type
    throw :done if @chars >= @limit

    case list_type
    when :BULLET, :LALPHA, :NUMBER, :UALPHA then
      "<p>"
    when :LABEL, :NOTE then
      start = "<p>#{to_html list_item.label} &mdash; "
      @chars += 1 # try to include the label
      start
    else
      raise RDoc::Error, "Invalid list type: #{list_type.inspect}"
    end
  end

  ##
  # Returns just the text of +link+, +url+ is only used to determine the link
  # type.

  def gen_url url, text
    if url =~ /^rdoc-label:([^:]*)(?::(.*))?/ then
      type = "link"
    elsif url =~ /([A-Za-z]+):(.*)/ then
      type = $1
    else
      type = "http"
    end

    if (type == "http" or type == "https" or type == "link") and
       url =~ /\.(gif|png|jpg|jpeg|bmp)$/ then
      ''
    else
      text.sub(%r%^#{type}:/*%, '')
    end
  end

  ##
  # In snippets, there are no lists

  def html_list_name list_type, open_tag
    ''
  end

  ##
  # Marks up +content+

  def convert content
    catch :done do
      return @markup.convert(content, self)
    end

    end_accepting
  end

  ##
  # Converts flow items +flow+

  def convert_flow flow
    throw :done if @chars >= @limit

    res = []
    @mask = 0

    flow.each do |item|
      case item
      when RDoc::Markup::AttrChanger then
        off_tags res, item
        on_tags  res, item
      when String then
        text = convert_string item
        res << truncate(text)
      when RDoc::Markup::Special then
        text = convert_special item
        res << truncate(text)
      else
        raise "Unknown flow element: #{item.inspect}"
      end

      if @chars >= @limit then
        off_tags res, RDoc::Markup::AttrChanger.new(0, @mask)
        break
      end
    end

    res << '...' if @chars >= @limit

    res.join
  end

  def on_tags res, item
    @mask ^= item.turn_on

    super
  end

  def off_tags res, item
    @mask ^= item.turn_off

    super
  end

  def truncate text
    length = text.length
    chars = @chars
    @chars += length

    return text if @chars < @limit

    remaining = @limit - chars

    text =~ /\A(.{#{remaining},}?)(\s|$)/

    $1
  end

end

