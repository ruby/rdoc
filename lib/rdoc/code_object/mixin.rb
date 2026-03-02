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

  def <=>(other)
    return unless self.class === other

    name <=> other.name
  end

  def ==(other) # :nodoc:
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
  # The scoping rules of Ruby to resolve the name of an included module are:
  # - first look into the children of the current context;
  # - if not found, look into the children of included modules,
  #   in reverse inclusion order;
  # - if still not found, go up the hierarchy of names.
  #
  # This method has <code>O(n!)</code> behavior when the module calling
  # include is referencing nonexistent modules.  Avoid calling #module until
  # after all the files are parsed.  This behavior is due to ruby's constant
  # lookup behavior.
  #
  # As of the beginning of October, 2011, no gem includes nonexistent modules.
  #
  # When mixin is created from RDoc::Parser::PrismRuby, module name is already a resolved full-path name.
  #

  def module
    return @module if @module
    return @name unless parent

    @module = @store&.resolve_mixin(@name, parent, self) || @name
  end

  def to_s # :nodoc:
    "#{self.class.name.downcase} #@name in: #{parent}"
  end

end
