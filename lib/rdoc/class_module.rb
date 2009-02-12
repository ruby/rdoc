require 'rdoc/context'

##
# ClassModule is the base class for objects representing either a class or a
# module.

class RDoc::ClassModule < RDoc::Context

  attr_accessor :diagram

  ##
  # Creates a new ClassModule with +name+ with optional +superclass+

  def initialize(name, superclass = nil)
    @name       = name
    @diagram    = nil
    @superclass = superclass
    @comment    = ""
    super()
  end

  ##
  # Finds a class or module with +name+ in this namespace or its descendents

  def find_class_named(name)
    return self if full_name == name
    @classes.each_value {|c| return c if c.find_class_named(name) }
    nil
  end

  ##
  # Return the fully qualified name of this class or module

  def full_name
    if @parent && @parent.full_name
      @parent.full_name + "::" + @name
    else
      @name
    end
  end

  ##
  # URL for this with a +prefix+

  def http_url(prefix)
    path = full_name.split("::")
    File.join(prefix, *path) + ".html"
  end

  ##
  # Does this object represent a module?

  def module?
    false
  end

  ##
  # Get the superclass of this class.  Attempts to retrieve the superclass'
  # real name by following module nesting.

  def superclass
    raise NoMethodError, "#{full_name} is a module" if module?

    scope = self

    begin
      superclass = scope.classes.find { |c| c.name == @superclass }

      return superclass.full_name if superclass
      scope = scope.parent
    end until scope.nil? or RDoc::TopLevel === scope

    @superclass
  end

  ##
  # Set the superclass of this class to +superclass+

  def superclass=(superclass)
    raise NoMethodError, "#{full_name} is a module" if module?

    @superclass = superclass if @superclass.nil? or @superclass == 'Object'
  end

  def to_s # :nodoc:
    "#{self.class}: #{full_name} #{@comment} #{super}"
  end

end

