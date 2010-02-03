##
# A Document containing lists, headings, paragraphs, etc.

class RDoc::Markup::Document

  ##
  # The parts of the Document

  attr_reader :parts

  ##
  # Creates a new Document with +parts+

  def initialize *parts
    @parts = []
    @parts.push(*parts)
  end

  def == other # :nodoc:
    self.class == other.class and @parts == other.parts
  end

  def accept visitor
    visitor.start_accepting

    @parts.each do |item|
      item.accept visitor
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

