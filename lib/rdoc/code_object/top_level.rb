# frozen_string_literal: true

require_relative "file"

##
# RDoc::TopLevel is deprecated and will be removed in a future version.
# Use RDoc::File instead.

module RDoc
  TopLevel = File # :nodoc:
  deprecate_constant :TopLevel
end
