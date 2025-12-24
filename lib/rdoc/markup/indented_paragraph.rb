# frozen_string_literal: true

module RDoc
  class Markup
    # An Indented Paragraph of text
    class IndentedParagraph < Raw
      # The indent in number of spaces
      #: Integer
      attr_reader :indent

      # Creates a new IndentedParagraph containing +parts+ indented with +indent+ spaces
      #: (Integer, *String) -> void
      def initialize(indent, *parts)
        @indent = indent

        super(*parts)
      end

      #: (top) -> bool
      def ==(other) # :nodoc:
        super && @indent == other.indent
      end

      # Calls #accept_indented_paragraph on +visitor+
      # @override
      #: (untyped) -> void
      def accept(visitor)
        visitor.accept_indented_paragraph(self)
      end

      # Joins the raw paragraph text and converts inline HardBreaks to the +hard_break+ text followed by the indent.
      #: (?String) -> String
      def text(hard_break = nil)
        @parts.map do |part|
          if HardBreak === part then
            '%1$s%3$*2$s' % [hard_break, @indent, ' '] if hard_break
          else
            part
          end
        end.join
      end
    end
  end
end
