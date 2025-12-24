# frozen_string_literal: true

module RDoc
  class Markup
    # A horizontal rule with a weight
    class Rule < Element
      #: Integer
      attr_reader :weight

      #: (Integer) -> void
      def initialize(weight)
        super()
        @weight = weight
      end

      #: (top) -> bool
      def ==(other)
        other.is_a?(Rule) && other.weight == @weight
      end

      # Calls #accept_rule on +visitor+
      # @override
      #: (untyped) -> void
      def accept(visitor)
        visitor.accept_rule(self)
      end

      # @override
      #: (PP) -> void
      def pretty_print(q) # :nodoc:
        q.group(2, '[rule:', ']') do
          q.pp(weight)
        end
      end
    end
  end
end
