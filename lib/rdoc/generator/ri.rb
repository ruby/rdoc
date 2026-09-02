# frozen_string_literal: true
module RDoc
  module Generator
    ##
    # Generates ri data files

    class RI

      RDoc.add_generator self

      ##
      # Description of this generator

      DESCRIPTION = 'creates ri data files'

      ##
      # Set up a new ri generator

      def initialize(store, options) #:not-new:
        @options    = options
        @store      = store
        @store.path = '.'
      end

      ##
      # Writes the parsed data store to disk for use by ri.

      def generate
        @store.save
      end

    end
  end
end
