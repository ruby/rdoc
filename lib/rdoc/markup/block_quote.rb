# frozen_string_literal: true
module RDoc
  class Markup
    ##
    # A quoted section which contains markup items.

    class BlockQuote < ::RDoc::Markup::Raw

      ##
      # Calls #accept_block_quote on +visitor+

      def accept(visitor)
        visitor.accept_block_quote self
      end

    end
  end
end
