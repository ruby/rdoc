##
# An empty line.  This class is a singleton.

class RDoc::Markup::BlankLine

  @instance = new

  def self.new
    @instance
  end

  def accept visitor
    visitor.accept_blank_line self
  end

  def pretty_print q # :nodoc:
    q.text 'blankline'
  end

end

