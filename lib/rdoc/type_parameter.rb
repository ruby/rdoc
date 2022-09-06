module RDoc
  class TypeParameter < CodeObject
    attr_reader :name, :variance, :unchecked, :upper_bound

    def initialize(name, variance, unchecked = false, upper_bound = nil)
      @name = name
      @variance = variance
      @unchecked = unchecked
      @upper_bound = upper_bound
    end

    def ==(other)
      other.is_a?(TypeParameter) &&
        self.name == other.name &&
        self.variance == other.variance &&
        self.unchecked == other.unchecked &&
        self.upper_bound == other.upper_bound
    end

    alias eql? ==

    def unchecked?
      unchecked
    end

    def to_s
      s = ""

      if unchecked?
        s << "unchecked "
      end

      case variance
      when :invariant
        # nop
      when :covariant
        s << "out "
      when :contravariant
        s << "in "
      end

      s << name.to_s

      if type = upper_bound
        s << " < #{type}"
      end

      s
    end
  end
end
