# frozen_string_literal: true

module RDoc
  class Markup
    class BlockQuote < Raw
      # Calls #accept_block_quote on +visitor+
      # @override
      #: (untyped) -> void
      def accept(visitor)
        visitor.accept_block_quote(self)
      end
    end
  end
end
