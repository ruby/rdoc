# frozen_string_literal: true

module RDoc
  class Markup
    # A section of verbatim text
    class Verbatim < Raw
      # Format of this verbatim section
      #: Symbol?
      attr_accessor :format

      #: (*String) -> void
      def initialize(*parts) # :nodoc:
        super
        @format = nil
      end

      #: (top) -> bool
      def ==(other) # :nodoc:
        super && @format == other.format
      end

      # Calls #accept_verbatim on +visitor+
      # @override
      #: (untyped) -> void
      def accept(visitor)
        visitor.accept_verbatim self
      end

      # Collapses 2+ newlines into a single one
      #: () -> void
      def normalize
        # Chunk the parts into groups of entries that are only line breaks and other content. For line break groups,
        # take only 1
        parts = @parts
          .chunk { |part| part.match?(/^\s*\n/) }
          .flat_map { |is_newline, group| is_newline ? group.take(1) : group }

        # Remove any trailing line breaks
        parts.pop if @parts.last&.match?(/\A\r?\n\z/)
        @parts = parts
      end

      # @override
      #: (PP) -> void
      def pretty_print(q) # :nodoc:
        self.class.name =~ /.*::(\w{1,4})/i

        q.group(2, "[#{$1.downcase}: ", ']') do
          if @format
            q.text("format: #{@format}")
            q.breakable
          end

          q.seplist(@parts) do |part|
            q.pp(part)
          end
        end
      end

      # Is this verbatim section Ruby code?
      #: () -> bool
      def ruby?
        @format ||= nil # TODO for older ri data, switch the tree to marshal_dump
        @format == :ruby
      end

      # The text of the section
      #: () -> String
      def text
        @parts.join
      end
    end
  end
end
