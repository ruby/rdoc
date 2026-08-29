# frozen_string_literal: true
module RDoc
  class Markup
    ##
    # A Paragraph of text

    class Paragraph < ::RDoc::Markup::Raw

      ##
      # Calls #accept_paragraph on +visitor+

      def accept(visitor)
        visitor.accept_paragraph self
      end

      ##
      # Joins the raw paragraph text and converts inline HardBreaks to the
      # +hard_break+ text.

      def text(hard_break = '')
        @parts.map do |part|
          if ::RDoc::Markup::HardBreak === part
            hard_break
          else
            part
          end
        end.join
      end

    end
  end
end
