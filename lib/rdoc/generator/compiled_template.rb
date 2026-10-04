# frozen_string_literal: true

module RDoc
  module Generator
    # Caches an executable renderer with declared inputs for a bundled HTML
    # template.  ERB#result remains available for binding-based evaluation.
    module CompiledTemplate # :nodoc:

      attr_writer :generator, :render_inputs

      #: (Hash[Symbol, untyped]) -> untyped
      def render(inputs)
        @compiled_renderer ||= def_module("render(#{@render_inputs.join(', ')})").instance_method(:render).bind(@generator)
        @compiled_renderer.call(*@render_inputs.map { |name| inputs.fetch(name) })
      end
    end
  end
end
