##
# A Module extend in a class with \#extend

class RDoc::Extend < RDoc::CodeObject

  ##
  # Name of extension module

  attr_accessor :name

  ##
  # Creates a new Extend for +name+ with +comment+

  def initialize(name, comment)
    super()
    @name = name
    self.comment = comment
    @module = nil # cache for module if found
  end

  ##
  # Extends are sorted by name

  def <=> other
    return unless self.class === other

    name <=> other.name
  end

  def == other # :nodoc:
    self.class === other and @name == other.name
  end

  alias eql? ==

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
    "#<%s:0x%x %s.extend %s>" % [
      self.class,
      object_id,
      parent_name, @name,
    ]
  end

  ##
  # Attempts to locate the extension module object.  Returns the name if not
  # known.
  #
  # The scoping rules of Ruby to resolve the name of an extension module are:
  # - first look into the children of the current context;
  # - if not found, look into the children of extension modules,
  #   in reverse extension order;
  # - if still not found, go up the hierarchy of names.
  #
  # This method has <code>O(n!)</code> behavior when the module calling
  # extend is referencing nonexistent modules.  Avoid calling #module until
  # after all the files are parsed.  This behavior is due to ruby's constant
  # lookup behavior.

  def module
    return @module if @module

    # search the current context
    return @name unless parent
    full_name = parent.child_name(@name)
    @module = RDoc::TopLevel.modules_hash[full_name]
    return @module if @module
    return @name if @name =~ /^::/

    # search the includes before this one, in reverse order
    searched = parent.extensions.take_while { |i| i != self }.reverse
    searched.each do |i|
      ext = i.module
      next if String === ext
      full_name = ext.child_name(@name)
      @module = RDoc::TopLevel.modules_hash[full_name]
      return @module if @module
    end

    # go up the hierarchy of names
    up = parent.parent
    while up
      full_name = up.child_name(@name)
      @module = RDoc::TopLevel.modules_hash[full_name]
      return @module if @module
      up = up.parent
    end

    @name
  end

  def to_s # :nodoc:
    "extend #@name in: #{parent}"
  end

end

