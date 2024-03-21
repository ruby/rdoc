module RDoc
  class TypeParameter < CodeObject
    attr_reader :name, :variance, :unchecked, :upper_bound

    MARSHAL_VERSION = 0 # :nodoc:

    def initialize(name, variance, unchecked = false, upper_bound = nil)
      @name = name
      @variance = variance
      @unchecked = unchecked
      @upper_bound = upper_bound
    end

    def marshal_load(array)
      @name = array[1]
      @variance = array[2]
      @unchecked = array[3]
      @upper_bound = array[4]
    end

    def marshal_dump
      [
        MARSHAL_VERSION,
        @name,
        @variance,
        @unchecked,
        @upper_bound
      ]
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
