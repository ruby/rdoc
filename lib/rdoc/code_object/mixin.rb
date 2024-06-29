# frozen_string_literal: true
##
# A Mixin adds features from a module into another context.  RDoc::Include and
# RDoc::Extend are both mixins.

class RDoc::Mixin < RDoc::CodeObject

  ##
  # Name of included module

  attr_accessor :name

  ##
  # Creates a new Mixin for +name+ with +comment+

  def initialize(name, comment)
    super()
    @name = name
    self.comment = comment
    @module = nil # cache for module if found
  end

  ##
  # Mixins are sorted by name

  def <=> other
    return unless self.class === other

    name <=> other.name
  end

  def == other # :nodoc:
    self.class === other and @name == other.name
  end

  alias eql? == # :nodoc:

  ##
  # Full name based on #module

  def full_name
    m = self.module
    RDoc::ClassModule === m ? m.full_name : @name
  end

  def hash # :nodoc:
    [@name, self.module].hash
  end

  def inspect # :nodoc:
    "#<%s:0x%x %s.%s %s>" % [
      self.class,
      object_id,
      parent_name, self.class.name.downcase, @name,
    ]
  end

  ##
  # Attempts to locate the included module object.  Returns the name if not
  # known.
  #
  # Avoid calling #module until after all the files are parsed.
  # This behavior is due to ruby's constant lookup behavior.

  def module
    return @module if @module
    return @module = @name unless parent
    return @module = @name if @name.start_with?('::')

    # search the includes before this one
    @module = parent.lookup_module(@name, before: self) || @name
  end

  ##
  # Sets the store for this class or module and its contained code objects.

  def store= store
    super

    @file = @store.add_file @file.full_name if @file
  end

  def to_s # :nodoc:
    "#{self.class.name.downcase} #@name in: #{parent}"
  end

end
