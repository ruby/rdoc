# frozen_string_literal: true
module RDoc
  class Markup
    ##
    # A horizontal rule with a weight

    class Rule < Struct.new :weight

      ##
      # Calls #accept_rule on +visitor+

      def accept(visitor)
        visitor.accept_rule self
      end

      def pretty_print(q) # :nodoc:
        q.group 2, '[rule:', ']' do
          q.pp weight
        end
      end

    end
  end
end
