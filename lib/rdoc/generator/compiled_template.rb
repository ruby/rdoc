# frozen_string_literal: true

module RDoc
  module Generator
    # Caches executable renderers for the bundled HTML templates.  Extended onto
    # ERB objects so the renderer cache has the same lifetime as the template.
    module CompiledTemplate # :nodoc:

      attr_writer :generator

      #: (?Binding?) -> untyped
      def result(context = nil)
        return super unless context && context.receiver.equal?(@generator) && @generator.compiled_template_context?(context)

        variables = context.local_variables.sort
        @compiled_renderers ||= {}
        renderer = @compiled_renderers[variables] ||= compile_renderer(variables)
        renderer.call(*variables.map { |name| context.local_variable_get(name) })
      end

      private

      #: (Array[Symbol]) -> Method
      def compile_renderer(variables)
        def_module("render(#{variables.join(', ')})").instance_method(:render).bind(@generator)
      end
    end
  end
end
