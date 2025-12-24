# frozen_string_literal: true

module RDoc
  class Markup
    # An item within a List that contains paragraphs, headings, etc.
    #
    # For BULLET, NUMBER, LALPHA and UALPHA lists, the label will always be nil.
    # For NOTE and LABEL lists, the list label may contain:
    #
    # * a single String for a single label
    # * an Array of Strings for a list item with multiple terms
    # * nil for an extra description attached to a previously labeled list item
    class ListItem < Element
      # The label for the ListItem
      #: (Array[String] | String)?
      attr_accessor :label

      # Parts of the ListItem
      attr_reader :parts

      # Creates a new ListItem with an optional +label+ containing +parts+
      #: ((Array[String] | String)?, *Element) -> void
      def initialize(label = nil, *parts)
        @label = label
        @parts = parts
      end

      # Appends +part+ to the ListItem
      #: (Element) -> void
      def <<(part)
        @parts << part
      end

      #: (top) -> bool
      def ==(other) # :nodoc:
        self.class == other.class &&
          @label == other.label &&
          @parts == other.parts
      end

      # Runs this list item and all its #parts through +visitor+
      # @override
      #: (untyped) -> void
      def accept(visitor)
        visitor.accept_list_item_start(self)
        @parts.each { |part| part.accept(visitor) }
        visitor.accept_list_item_end(self)
      end

      # Is the ListItem empty?
      #: () -> bool
      def empty?
        @parts.empty?
      end

      # Length of parts in the ListItem
      #: () -> Integer
      def length
        @parts.length
      end

      # @override
      #: (PP) -> void
      def pretty_print(q) # :nodoc:
        q.group(2, "[item: ", "]") do
          if @label
            q.pp(@label)
            q.text(";")
            q.breakable
          end

          q.seplist(@parts) do |part|
            q.pp(part)
          end
        end
      end

      # Adds +parts+ to the ListItem
      #: (*Element) -> void
      def push(*parts)
        @parts.concat(parts)
      end
    end
  end
end
