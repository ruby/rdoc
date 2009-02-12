require 'rdoc/code_object'

##
# Represent an alias, which is an old_name/new_name pair associated with a
# particular context

class RDoc::Alias < RDoc::CodeObject

  ##
  # Allow comments to be overridden

  attr_writer :comment

  ##
  # Aliased name

  attr_accessor :new_name

  ##
  # Aliasee's name

  attr_accessor :old_name

  attr_accessor :text

  def initialize(text, old_name, new_name, comment)
    super()
    @text = text
    @old_name = old_name
    @new_name = new_name
    self.comment = comment
  end

  def inspect # :nodoc:
    "#<%s:0x%x %s.alias_method %s, %s>" % [
      self.class, object_id,
      parent.name, @old_name, @new_name,
    ]
  end

  def to_s # :nodoc:
    "alias: #{self.old_name} ->  #{self.new_name}\n#{self.comment}"
  end

end


