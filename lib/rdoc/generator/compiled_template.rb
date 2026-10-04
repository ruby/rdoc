# frozen_string_literal: true

module RDoc
  module Generator
    # Caches a renderer with declared inputs for an Aliki template.  Ordinary
    # bindings still use ERB's original evaluation and shared-local semantics.
    module CompiledTemplate # :nodoc:

      Inputs = Struct.new(
        :io, :rel_prefix, :asset_rel_prefix, :current, :klass, :file,
        :breadcrumb, :message, :installed, keyword_init: true
      )

      attr_writer :generator, :render_inputs

      #: (?(Binding | Inputs)?) -> untyped
      def result(context = nil)
        return super unless context.is_a?(Inputs)

        @compiled_renderer ||= def_module("render(#{@render_inputs.join(', ')})").instance_method(:render).bind(@generator)
        @compiled_renderer.call(*@render_inputs.map { |name| context[name] })
      end
    end
  end
end
