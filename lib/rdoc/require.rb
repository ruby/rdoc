require 'rdoc/code_object'

##
# A file loaded by \#require

class RDoc::Require < RDoc::CodeObject

  ##
  # Name of the required file

  attr_accessor :name

  def initialize(name, comment)
    super()
    @name = name.gsub(/'|"/, "") #'
    self.comment = comment
  end

  def inspect # :nodoc:
    "#<%s:0x%x require '%s' in %s>" % [
      self.class,
      object_id,
      @name,
      parent_file_name,
    ]
  end

end

