# frozen_string_literal: true
module RDoc
  class Context
    ##
    # Internal method storage with a lazy name index. Keeping the index on the
    # list lets shallow-copied class/module aliases share its invalidation.
    # Context exposes only frozen snapshots and invalidates destructive changes.

    class MethodList < Array # :nodoc:
      EMPTY = [].freeze

      # Finds the first method named +name+ accepted by the optional block.
      # Keep candidate buckets private so callers cannot mutate the name index.

      #: (String?) ?{ (AnyMethod) -> bool } -> AnyMethod?
      def find_named(name, &predicate)
        candidates = methods_named(name)
        predicate ? candidates.find(&predicate) : candidates.first
      end

      #: (String?) -> Array[AnyMethod]
      def methods_named(name)
        indexed = @name_index && @name_index_token[0]
        if !indexed || @indexed_length < length
          index = indexed ? @name_index : {}
          token = indexed ? @name_index_token : [true]
          mutable_names = indexed && @mutable_names

          # Parsing aliases interleaves lookups with additions. Index just the
          # appended tail rather than repeatedly rebuilding the whole list.
          (indexed ? @indexed_length : 0).upto(length - 1) do |i|
            method = self[i]
            method_name = method.name
            if method_name.frozen?
              (index[method_name] ||= []) << method
            else
              mutable_names = true
            end
            method.track_name_index token unless method.frozen?
          end

          @name_index_token = token
          @name_index = index
          @indexed_length = length
          @mutable_names = mutable_names
        end

        # Names are retained by reference. Mutable strings can change without
        # name=, so only use the index when every name is already frozen.
        return select { |method| method.name == name } if @mutable_names

        @name_index[name] || EMPTY
      end
      private :methods_named

      #: () -> void
      def invalidate_name_index
        @name_index_token[0] = false if @name_index_token
        @name_index = nil
      end

    end
  end
end
