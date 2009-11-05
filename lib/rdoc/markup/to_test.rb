require 'rdoc/markup'
require 'rdoc/markup/formatter'

##
# This Markup outputter is used for testing purposes.

class RDoc::Markup::ToTest < RDoc::Markup::Formatter

  ##
  # :section: Visitor

  def start_accepting
    @res = []
    @list = []
  end

  def end_accepting
    @res
  end

  def accept_paragraph(am, paragraph)
    @res << paragraph.text
  end

  def accept_verbatim(am, verbatim)
    @res << verbatim.text
  end

  def accept_list_start(am, list)
    @list << list.type
  end

  def accept_list_end(am, list)
    @list.pop
  end

  def accept_list_item_start(am, list_item)
    @res << "#{' ' * (@list.size - 1)}#{@list.last}: "
  end

  def accept_list_item_end(am, list_item)
  end

  def accept_blank_line(am, blank_line)
    @res << "\n"
  end

  def accept_heading(am, heading)
    @res << "#{'=' * heading.level} #{heading.text}"
  end

  def accept_rule(am, rule)
    @res << '-' * rule.weight
  end

end

