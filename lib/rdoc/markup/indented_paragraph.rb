##
# An Indented Paragraph of text

class RDoc::Markup::IndentedParagraph < RDoc::Markup::Raw

  ##
  # The indent in number of spaces

  attr_reader :indent

  ##
  # Creates a new IndentedParagraph containing +parts+ indented with +indent+ spaces

  def initialize indent, *parts
    raise ArgumentError, "First argument must be the indent as an Integer" unless indent.is_a? Integer
    @indent = indent
    super(*parts)
  end

  def == other # :nodoc:
    super and indent == other.indent
  end

  ##
  # Calls #accept_indented_paragraph on +visitor+

  def accept visitor
    visitor.accept_indented_paragraph self
  end

end

