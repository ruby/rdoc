##
# A normal module, like NormalClass

class RDoc::NormalModule < RDoc::ClassModule

  def inspect # :nodoc:
    "#<%s:0x%x module %s includes: %p attributes: %p methods: %p aliases: %p>" % [
      self.class, object_id,
      full_name, @includes, @attributes, @method_list, @aliases
    ]
  end

  ##
  # The definition of this module, <tt>module MyModuleName</tt>

  def definition
    "module #{full_name}"
  end

  ##
  # This is a module, returns true

  def module?
    true
  end

  def pretty_print q # :nodoc:
    q.group 2, "[module #{full_name}: ", "]" do
      q.breakable
      q.text "includes:"
      q.breakable
      q.seplist @includes do |inc| q.pp inc end
      q.breakable

      q.text "attributes:"
      q.breakable
      q.seplist @attributes do |inc| q.pp inc end
      q.breakable

      q.text "methods:"
      q.breakable
      q.seplist @method_list do |inc| q.pp inc end
      q.breakable

      q.text "aliases:"
      q.breakable
      q.seplist @aliases do |inc| q.pp inc end
      q.breakable

      q.text "comment:"
      q.breakable
      q.pp comment
    end
  end

  ##
  # Modules don't have one, raises NoMethodError

  def superclass
    raise NoMethodError, "#{full_name} is a module"
  end

  ##
  # Search record used by RDoc::Generator::JsonIndex

  def search_record
    # TODO squashing the file list seems simplistic
    files = @in_files.map { |file| file.absolute_name }
    file = files.include?(@parent.full_name) ? files.first : @parent.full_name

    [
      name,
      full_name,
      path,
      '',
      snippet(@comment),
    ]
  end

end

