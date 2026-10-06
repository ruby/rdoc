# frozen_string_literal: true
module RDoc
  class Context
    ##
    # An Array with a lazy, methods-only name index. Keeping the index on the
    # list lets shallow-copied class/module aliases share its invalidation.

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
        # Block-based mutations can expose a partially changed list to a lookup.
        return select { |method| method.name == name } if @mutating

        indexed = @name_index && @name_index_token[0]
        if !indexed || @indexed_length < length
          # A frozen list can still be searched, including after a method rename.
          return select { |method| method.name == name } if frozen?

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

      #: (MethodList) -> void
      def initialize_copy(other)
        super
        @name_index = nil
        @name_index_token = nil
        @indexed_length = nil
        @mutable_names = nil
        @mutating = nil
      end

      # Persist only collection contents, never derived index state or tokens.

      #: () -> Array[AnyMethod]
      def marshal_dump
        to_a
      end

      #: (Array[AnyMethod]) -> void
      def marshal_load(methods)
        replace(methods)
      end

      # Intercept public Array mutations as well as RDoc's own additions,
      # filtering, store loading and live-preview removals. Appends leave the
      # indexed prefix intact; other mutations invalidate on both sides because
      # a block can perform lookups before the mutation finishes.
      %i[
        << []= append clear collect! compact! concat delete delete_at delete_if
        fill filter! flatten! insert keep_if map! pop prepend push reject!
        replace reverse! rotate! select! shift shuffle! slice! sort! sort_by!
        uniq! unshift
      ].each do |mutation|
        appending = %i[<< append concat push].include? mutation

        define_method(mutation) do |*args, **kwargs, &block|
          # Preserve Array's no-op behavior, e.g. deleting a missing item.
          return super(*args, **kwargs, &block) if frozen?

          invalidate_name_index unless appending
          mutating = @mutating
          @mutating = true
          begin
            super(*args, **kwargs, &block)
          ensure
            @mutating = mutating
            invalidate_name_index unless appending
          end
        end
      end
    end
  end
end
