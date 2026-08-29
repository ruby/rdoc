# frozen_string_literal: true
module RDoc
  ##
  # Allows an ERB template to be rendered in the context (binding) of an
  # existing ERB template evaluation.

  class ERBPartial < ERB

    ##
    # Overrides +compiler+ startup to set the +eoutvar+ to an empty string only
    # if it isn't already set.

    def set_eoutvar(compiler, eoutvar = '_erbout')
      super

      compiler.pre_cmd = ["#{eoutvar} ||= +''"]
    end

  end
end
