require 'rdoc/code_object'

##
# An attribute created by \#attr, \#attr_reader, \#attr_writer or
# \#attr_accessor

class RDoc::Attr < RDoc::CodeObject

  ##
  # Name of the attribute

  attr_accessor :name

  ##
  # Is the attribute readable, writable or both?

  attr_accessor :rw

  attr_accessor :text

  ##
  # public, protected, private

  attr_accessor :visibility

  def initialize(text, name, rw, comment)
    super()
    @text = text
    @name = name
    @rw = rw
    @visibility = :public
    self.comment = comment
  end
  ##
  # Attributes are ordered by name

  def <=>(other)
    self.name <=> other.name
  end

  def inspect # :nodoc:
    attr = case rw
           when 'RW' then :attr_accessor
           when 'R'  then :attr_reader
           when 'W'  then :attr_writer
           else
               " (#{rw})"
           end

      "#<%s:0x%x %s.%s :%s>" % [
        self.class, object_id,
        parent_name, attr, @name,
      ]
  end

  def to_s # :nodoc:
    "attr: #{self.name} #{self.rw}\n#{self.comment}"
  end

end

