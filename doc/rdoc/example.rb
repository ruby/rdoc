# frozen_string_literal: true

require 'rdoc'

##
# RDoc::Example provides example Ruby code objects for demonstrating
# RDoc's documentation capabilities.
#
# This class is used by:
# - bin/console for interactive exploration of RDoc objects
# - Testing cross-reference link generation
# - Demonstrating Ruby-specific directives like :call-seq:, :args:, :yields:
#
# For comprehensive RDoc markup documentation, see doc/markup_reference/rdoc.rdoc.

class RDoc::Example

  # Example class for demonstrating cross-reference links.
  class ExampleClass; end

  # Example module for demonstrating cross-reference links.
  module ExampleModule; end

  # Example singleton method.
  def self.singleton_method_example(foo, bar); end

  # Example instance method.
  #
  # This method demonstrates how RDoc documents instance methods,
  # including arguments and yield parameters.
  def instance_method_example(foo, bar)
    yield 'baz'
  end

  alias aliased_method instance_method_example

  # Example attribute.
  attr_accessor :example_attribute

  alias aliased_attribute example_attribute

  # Example constant.
  EXAMPLE_CONSTANT = ''

  # :call-seq:
  #   call_seq_example(foo, bar)
  #   Can be anything -> bar
  #   Also anything more -> baz or bat
  #
  # The <tt>:call-seq:</tt> directive overrides the actual calling sequence
  # found in the Ruby code.
  #
  # - It can specify anything at all.
  # - It can have multiple calling sequences.
  #
  # Note that the "arrow" is two characters, hyphen and right angle-bracket,
  # which is made into a single character in the HTML.
  #
  # Here is the <tt>:call-seq:</tt> directive given for this method:
  #
  #   :call-seq:
  #     call_seq_example(foo, bar)
  #     Can be anything -> bar
  #     Also anything more -> baz or bat
  #
  def call_seq_example
    nil
  end

  # The <tt>:args:</tt> directive overrides the actual arguments
  # found in the Ruby code.
  #
  # The actual signature is +args_example(foo, bar)+, but the directive
  # makes it appear as +args_example(baz)+.
  #
  def args_example(foo, bar) # :args: baz
    nil
  end

  # The <tt>:yields:</tt> directive overrides the actual yield
  # found in the Ruby code.
  #
  # The actual yield is +'baz'+, but the directive makes it appear
  # as +'bat'+.
  #
  def yields_example(foo, bar) # :yields: 'bat'
    yield 'baz'
  end

  # This method is documented only by RDoc's derived documentation,
  # except for these comments.
  #
  # RDoc automatically extracts:
  # - Method name
  # - Arguments
  # - Yielded values
  #
  def derived_docs_example(foo, bar)
    yield 'baz'
  end

end
