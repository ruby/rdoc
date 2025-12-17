# frozen_string_literal: true
##
# A file loaded by \#require

class RDoc::Require < RDoc::CodeObject

  ##
  # Name of the required file

  attr_accessor :name

  ##
  # Creates a new Require that loads +name+ with +comment+

  def initialize(name, comment)
    super()
    @name = name.gsub(/'|"/, "") #'
    @file_context = nil
    self.comment = comment
  end

  def inspect # :nodoc:
    "#<%s:0x%x require '%s' in %s>" % [
      self.class,
      object_id,
      @name,
      @parent ? @parent.base_name : '(unknown)'
    ]
  end

  def to_s # :nodoc:
    "require #{name} in: #{parent}"
  end

  ##
  # The RDoc::File corresponding to this require, or +nil+ if not found.

  def file_context
    @file_context ||= begin
      f = RDoc::File.all_files_hash[name + '.rb']

      if f.nil? and RDoc::File.all_files.first.full_name =~ %r(^lib/) then
        # second chance
        f = RDoc::File.all_files_hash['lib/' + name + '.rb']
      end

      f
    end
  end

  alias_method :top_level, :file_context # :nodoc:

end
