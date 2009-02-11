# We represent the various high-level code constructs that appear
# in Ruby programs: classes, modules, methods, and so on.

require 'thread'

require 'rdoc/tokenstream'

module RDoc

  ##
  # We contain the common stuff for contexts (which are containers) and other
  # elements (methods, attributes and so on)

  class CodeObject

    ##
    # Our comment

    attr_reader :comment

    ##
    # Do we document our children?

    attr_reader :document_children

    ##
    # Do we document ourselves?

    attr_reader :document_self

    ##
    # Are we done documenting (ie, did we come across a :enddoc:)?

    attr_accessor :done_documenting

    ##
    # Our parent CodeObject

    attr_accessor :parent

    ##
    # Which section are we in

    attr_accessor :section

    ##
    # We are the model of the code, but we know that at some point we will be
    # worked on by viewers. By implementing the Viewable protocol, viewers can
    # associated themselves with these objects.

    attr_accessor :viewer

    ##
    # Creates a new CodeObject that will document itself and its children

    def initialize
      @document_self = true
      @document_children = true
      @force_documentation = false
      @done_documenting = false
    end

    ##
    # Enables or disables documentation of this CodeObject.  Calls
    # remove_methods_etc when disabling.

    def document_self=(document_self)
      @document_self = document_self
      remove_methods_etc unless document_self
    end

    ##
    # Enable capture of documentation

    def start_doc
      @document_self = true
      @document_children = true
    end

    ##
    # Disable capture of documentation

    def stop_doc
      @document_self = false
      @document_children = false
    end

    ##
    # Enables or disables documentation of this CodeObject's children.  Calls
    # remove_classes_and_modules when disabling.

    def document_children=(document_children)
      @document_children = document_children
      remove_classes_and_modules unless document_children
    end

    ##
    # Force documentation of this CodeObject

    attr_accessor :force_documentation

    ##
    # File name of our parent

    def parent_file_name
      @parent ? @parent.file_base_name : '(unknown)'
    end

    ##
    # Name of our parent

    def parent_name
      @parent ? @parent.name : '(unknown)'
    end

    ##
    # Callback called upon disabling documentation of children.  See
    # #document_children=

    def remove_classes_and_modules
    end

    ##
    # Callback called upon disabling documentation of ourself.  See
    # #document_self=

    def remove_methods_etc
    end

    ##
    # Replaces our comment with +comment+, unless it is empty.

    def comment=(comment)
      @comment = comment unless comment.empty?
    end

    ##
    # There's a wee trick we pull. Comment blocks can have directives that
    # override the stuff we extract during the parse. So, we have a special
    # class method, attr_overridable, that lets code objects list those
    # directives. When a comment is assigned, we then extract out any matching
    # directives and update our object

    def self.attr_overridable(name, *aliases)
      @overridables ||= {}

      attr_accessor name

      aliases.unshift name

      aliases.each do |directive_name|
        @overridables[directive_name.to_s] = name
      end
    end

  end

  ##
  # A Context is something that can hold modules, classes, methods,
  # attributes, aliases, requires, and includes. Classes, modules, and files
  # are all Contexts.

  class Context < CodeObject

    ##
    # Aliased methods

    attr_reader :aliases

    ##
    # attr* methods

    attr_reader :attributes

    ##
    # Constants defined

    attr_reader :constants

    ##
    # Current section of documentation

    attr_reader :current_section

    ##
    # Files this context is found in

    attr_reader :in_files

    ##
    # Modules this context includes

    attr_reader :includes

    ##
    # Methods defined in this context

    attr_reader :method_list

    ##
    # Name

    attr_reader :name

    ##
    # Files this context requires

    attr_reader :requires

    ##
    # Sections in this context

    attr_reader :sections

    ##
    # Current visibility of this context

    attr_reader :visibility

    ##
    # A per-comment section of documentation like:
    #
    #   # :SECTION: The title
    #   # The body

    class Section

      ##
      # Section comment

      attr_reader :comment

      ##
      # Section sequence number (for linking)

      attr_reader :sequence

      ##
      # Section title

      attr_reader :title

      @@sequence = "SEC00000"
      @@sequence_lock = Mutex.new

      ##
      # Creates a new section with +title+ and +comment+

      def initialize(title, comment)
        @title = title
        @@sequence_lock.synchronize do
          @@sequence.succ!
          @sequence = @@sequence.dup
        end
        @comment = nil
        set_comment(comment)
      end

      ##
      # Sections are equal when they have the same #sequence

      def ==(other)
        self.class === other and @sequence == other.sequence
      end

      def inspect # :nodoc:
        "#<%s:0x%x %s %p>" % [
          self.class, object_id,
          @sequence, title
        ]
      end

      ##
      # Set the comment for this section from the original comment block If
      # the first line contains :section:, strip it and use the rest.
      # Otherwise remove lines up to the line containing :section:, and look
      # for those lines again at the end and remove them. This lets us write
      #
      #   # blah blah blah
      #   #
      #   # :SECTION: The title
      #   # The body

      def set_comment(comment)
        return unless comment

        if comment =~ /^#[ \t]*:section:.*\n/
          start = $`
          rest = $'

          if start.empty?
            @comment = rest
          else
            @comment = rest.sub(/#{start.chomp}\Z/, '')
          end
        else
          @comment = comment
        end
        @comment = nil if @comment.empty?
      end

    end

    ##
    # Creates an unnamed empty context with public visibility

    def initialize
      super

      @in_files = []

      @name    ||= "unknown"
      @comment ||= ""
      @parent  = nil
      @visibility = :public

      @current_section = Section.new nil, nil
      @sections = [@current_section]

      initialize_methods_etc
      initialize_classes_and_modules
    end

    ##
    # Sets the defaults for classes and modules

    def initialize_classes_and_modules
      @classes = {}
      @modules = {}
    end

    ##
    # Sets the defaults for methods and so-forth

    def initialize_methods_etc
      @method_list = []
      @attributes  = []
      @aliases     = []
      @requires    = []
      @includes    = []
      @constants   = []

      # This Hash maps a method name to a list of unmatched
      # aliases (aliases of a method not yet encountered).
      @unmatched_alias_lists = {}
    end

    ##
    # Adds +an_alias+ that is automatically resolved

    def add_alias(an_alias)
      meth = find_instance_method_named(an_alias.old_name)

      if meth then
        add_alias_impl(an_alias, meth)
      else
        add_to(@aliases, an_alias)
        unmatched_alias_list = @unmatched_alias_lists[an_alias.old_name] ||= []
        unmatched_alias_list.push(an_alias)
      end

      an_alias
    end

    ##
    # Adds +an_alias+ pointing to +meth+

    def add_alias_impl(an_alias, meth)
      new_meth = AnyMethod.new an_alias.text, an_alias.new_name
      new_meth.is_alias_for = meth
      new_meth.singleton    = meth.singleton
      new_meth.params       = meth.params
      new_meth.comment = "Alias for \##{meth.name}"
      meth.add_alias new_meth
      add_method new_meth
    end

    ##
    # Adds +attribute+

    def add_attribute(attribute)
      add_to @attributes, attribute
    end

    ##
    # Adds a class named +name+ with +superclass+

    def add_class(class_type, name, superclass)
      klass = add_class_or_module @classes, class_type, name, superclass

      # If the parser encounters Container::Item before encountering
      # Container, then it assumes that Container is a module.  This may not
      # be the case, so remove Container from the module list if present and
      # transfer any contained classes and modules to the new class.

      TopLevel.lock.synchronize do
        mod = TopLevel.modules_hash.delete name

        if mod then
          klass.classes_hash.update mod.classes_hash
          klass.modules_hash.update mod.modules_hash
          klass.method_list.concat mod.method_list
        end
      end

      return klass
    end

    ##
    # Instantiates a +class_type+ named +name+ and adds it the modules or
    # classes Hash +collection+.

    def add_class_or_module(collection, class_type, name, superclass = nil)
      klass = collection[name]

      if klass then
        klass.superclass = superclass unless klass.module?
        puts "Reusing class/module #{name}" if $DEBUG_RDOC
      else
        klass = class_type.new name, superclass
        collection[name] = klass unless @done_documenting
        klass.parent = self
        klass.section = @current_section
      end

      klass
    end

    ##
    # Adds +constant+

    def add_constant(constant)
      add_to @constants, constant
    end

    ##
    # Adds included module +include+

    def add_include(include)
      add_to @includes, include
    end

    ##
    # Adds +method+

    def add_method(method)
      method.visibility = @visibility
      add_to(@method_list, method)

      unmatched_alias_list = @unmatched_alias_lists[method.name]
      if unmatched_alias_list then
        unmatched_alias_list.each do |unmatched_alias|
          add_alias_impl unmatched_alias, method
          @aliases.delete unmatched_alias
        end

        @unmatched_alias_lists.delete method.name
      end
    end

    ##
    # Adds a module named +name+

    def add_module(class_type, name)
      add_class_or_module @modules, class_type, name, nil
    end

    ##
    # Adds +require+ to this context's top level

    def add_require(require)
      if TopLevel === self then
        add_to @requires, require
      else
        parent.add_require require
      end
    end

    ##
    # Adds +thing+ to the collection +array+

    def add_to(array, thing)
      array << thing if @document_self and not @done_documenting
      thing.parent = self
      thing.section = @current_section
    end

    ##
    # Array of classes in this context

    def classes
      @classes.values
    end

    ##
    # Hash of classes keyed by class name

    def classes_hash
      @classes
    end
    protected :classes_hash

    ##
    # Is part of this thing was defined in +file+?

    def defined_in?(file)
      @in_files.include?(file)
    end

    ##
    # Iterator for attributes

    def each_attribute 
      @attributes.each {|a| yield a}
    end

    ##
    # Iterator for classes and modules

    def each_classmodule
      @modules.each_value {|m| yield m}
      @classes.each_value {|c| yield c}
    end

    ##
    # Iterator for constants

    def each_constant
      @constants.each {|c| yield c}
    end

    ##
    # Iterator for methods

    def each_method
      @method_list.each {|m| yield m}
    end

    ##
    # Finds an attribute with +name+ in this context

    def find_attribute_named(name)
      @attributes.find {|m| m.name == name}
    end

    ##
    # Finds a constant with +name+ in this context

    def find_constant_named(name)
      @constants.find {|m| m.name == name}
    end

    ##
    # Find a module at a higher scope

    def find_enclosing_module_named(name)
      parent && parent.find_module_named(name)
    end

    ##
    # Finds a file with +name+ in this context

    def find_file_named(name)
      toplevel.class.find_file_named(name)
    end

    ##
    # Finds an instance method with +name+ in this context

    def find_instance_method_named(name)
      @method_list.find {|meth| meth.name == name && !meth.singleton}
    end

    ##
    # Finds a method, constant, attribute, module or files named +symbol+ in
    # this context

    def find_local_symbol(symbol)
      res = find_method_named(symbol) ||
            find_constant_named(symbol) ||
            find_attribute_named(symbol) ||
            find_module_named(symbol) ||
            find_file_named(symbol)
    end

    ##
    # Finds a instance or module method with +name+ in this context

    def find_method_named(name)
      @method_list.find {|meth| meth.name == name}
    end

    ##
    # Find a module with +name+ using ruby's constant scoping rules

    def find_module_named(name)
      # First check the enclosed modules, then check the module itself,
      # then check the enclosing modules (this mirrors the check done by
      # the Ruby parser)
      res = @modules[name] || @classes[name]
      return res if res
      return self if self.name == name
      find_enclosing_module_named(name)
    end

    ##
    # Look up +symbol+.  If +method+ is non-nil, then we assume the symbol
    # references a module that contains that method.

    def find_symbol(symbol, method = nil)
      result = nil

      case symbol
      when /^::(.*)/ then
        result = toplevel.find_symbol($1)
      when /::/ then
        modules = symbol.split(/::/)

        unless modules.empty? then
          module_name = modules.shift
          result = find_module_named(module_name)

          if result then
            modules.each do |name|
              result = result.find_module_named(name)
              break unless result
            end
          end
        end

      else
        # if a method is specified, then we're definitely looking for
        # a module, otherwise it could be any symbol
        if method
          result = find_module_named(symbol)
        else
          result = find_local_symbol(symbol)
          if result.nil?
            if symbol =~ /^[A-Z]/
              result = parent
              while result && result.name != symbol
                result = result.parent
              end
            end
          end
        end
      end

      if result and method then
        fail unless result.respond_to? :find_local_symbol
        result = result.find_local_symbol(method)
      end

      result
    end

    ##
    # Yields Method and Attr entries matching the list of names in +methods+.
    # Attributes are only returned when +singleton+ is false.

    def methods_matching(methods, singleton = false)
      count = 0

      @method_list.each do |m|
        if methods.include? m.name and m.singleton == singleton then
          yield m
          count += 1
        end
      end

      return if count == methods.size || singleton

      @attributes.each do |a|
        yield a if methods.include? a.name
      end
    end

    ##
    # Array of modules in this context

    def modules
      @modules.values
    end

    ##
    # Hash of modules keyed by module name

    def modules_hash
      @modules
    end
    protected :modules_hash

    ##
    # Changes the visibility for new methods to +visibility+

    def ongoing_visibility=(visibility)
      @visibility = visibility
    end

    ##
    # Record which file +toplevel+ is in

    def record_location(toplevel)
      @in_files << toplevel unless @in_files.include?(toplevel)
    end

    ##
    # If a class's documentation is turned off after we've started collecting
    # methods etc., we need to remove the ones we have

    def remove_methods_etc
      initialize_methods_etc
    end

    ##
    # Given an array +methods+ of method names, set the visibility of each to
    # +visibility+

    def set_visibility_for(methods, visibility, singleton = false)
      methods_matching methods, singleton do |m|
        m.visibility = visibility
      end
    end

    ##
    # Removes classes and modules when we see a :nodoc: all

    def remove_classes_and_modules
      initialize_classes_and_modules
    end

    ##
    # Creates a new section with +title+ and +comment+

    def set_current_section(title, comment)
      @current_section = Section.new(title, comment)
      @sections << @current_section
    end

    ##
    # Return the toplevel that owns us

    def toplevel
      return @toplevel if defined? @toplevel
      @toplevel = self
      @toplevel = @toplevel.parent until TopLevel === @toplevel
      @toplevel
    end

    ##
    # Contexts are sorted by name

    def <=>(other)
      name <=> other.name
    end

  end

  ##
  # A TopLevel context is a representation of the contents of a single file

  class TopLevel < Context

    ##
    # This TopLevel's File::Stat struct

    attr_accessor :file_stat

    ##
    # Relative name of this file

    attr_accessor :file_relative_name

    ##
    # Absolute name of this file

    attr_accessor :file_absolute_name

    attr_accessor :diagram

    ##
    # The parser that processed this file

    attr_accessor :parser

    ##
    # Returns all classes and modules discovered by RDoc

    def self.all_classes_and_modules
      @@lock.synchronize do
        @@all_classes.values + @@all_modules.values
      end
    end

    ##
    # Hash of all classes known to RDoc

    def self.classes_hash
      @@all_classes
    end

    ##
    # Finds the class with +name+ in all discovered classes

    def self.find_class_named(name)
      @@lock.synchronize do
        @@all_classes.each_value do |c|
          res = c.find_class_named(name)
          return res if res
        end
      end
      nil
    end

    ##
    # Finds the file with +name+ in all discovered files

    def self.find_file_named(name)
      @@lock.synchronize do
        @@all_files[name]
      end
    end

    @@lock = Mutex.new

    ##
    # Lock for global class, module and file stores

    def self.lock
      @@lock
    end

    ##
    # Hash of all modules known to RDoc

    def self.modules_hash
      @@all_modules
    end

    ##
    # Empties RDoc of stored class, module and file information

    def self.reset
      @@lock.synchronize do
        @@all_classes = {}
        @@all_modules = {}
        @@all_files   = {}
      end
    end

    reset

    ##
    # Creates a new TopLevel for +file_name+

    def initialize(file_name)
      super()
      @name = "TopLevel"
      @file_relative_name = file_name
      @file_absolute_name = file_name
      @file_stat          = File.stat(file_name) rescue nil # HACK for testing
      @diagram            = nil
      @parser             = nil

      @@lock.synchronize do
        @@all_files[file_name] = self
      end
    end

    ##
    # Adding a class or module to a TopLevel is special, as we only want one
    # copy of a particular top-level class. For example, if both file A and
    # file B implement class C, we only want one ClassModule object for C.
    # This code arranges to share classes and modules between files.

    def add_class_or_module(collection, class_type, name, superclass)
      cls = collection[name]

      if cls then
        cls.superclass = superclass unless cls.module?
        puts "Reusing class/module #{cls.full_name}" if $DEBUG_RDOC
      else
        all = nil

        @@lock.synchronize do
          if class_type == NormalModule then
            all = @@all_modules
          else
            all = @@all_classes
          end

          cls = all[name]
        end

        if !cls then
          cls = class_type.new name, superclass
          unless @done_documenting
            @@lock.synchronize do
              all[name] = cls
            end
          end
        else
          # If the class has been encountered already, check that its
          # superclass has been set (it may not have been, depending on
          # the context in which it was encountered).
          if class_type == NormalClass
            if !cls.superclass then
              cls.superclass = superclass
            end
          end
        end

        collection[name] = cls unless @done_documenting

        cls.parent = self
      end

      cls
    end

    ##
    # Base name of this file

    def file_base_name
      File.basename @file_absolute_name
    end

    ##
    # Find class or module named +symbol+ in all discovered classes and
    # modules

    def find_class_or_module_named(symbol)
      @@lock.synchronize do
        @@all_classes.each_value {|c| return c if c.name == symbol}
        @@all_modules.each_value {|m| return m if m.name == symbol}
      end
      nil
    end

    ##
    # Finds a class or module named +symbol+

    def find_local_symbol(symbol)
      find_class_or_module_named(symbol) || super
    end

    ##
    # Finds a module or class with +name+

    def find_module_named(name)
      find_class_or_module_named(name) || find_enclosing_module_named(name)
    end

    ##
    # TopLevel's don't have full names

    def full_name
      nil
    end

    def inspect # :nodoc:
      "#<%s:0x%x %p modules: %p classes: %p>" % [
        self.class, object_id,
        file_base_name,
        @modules.map { |n,m| m },
        @classes.map { |n,c| c }
      ]
    end

  end

  ##
  # ClassModule is the base class for objects representing either a class or a
  # module.

  class ClassModule < Context

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
      end until scope.nil? or TopLevel === scope

      @superclass
    end

    ##
    # Set the superclass of this class to +superclass+

    def superclass=(superclass)
      raise NoMethodError, "#{full_name} is a module" if module?

      @superclass = superclass if @superclass.nil? or @superclass == 'Object'
    end

    def to_s # :nodoc:
      "#{self.class}: #{@name} #{@comment} #{super}"
    end

  end

  ##
  # An anonymous class like:
  #
  #   c = Class.new do end

  class AnonClass < ClassModule
  end

  ##
  # A normal class, neither singleton nor anonymous

  class NormalClass < ClassModule

    def inspect # :nodoc:
      superclass = @superclass ? " < #{@superclass}" : nil
      "<%s:0x%x class %s%s includes: %p attributes: %p methods: %p aliases: %p>" % [
        self.class, object_id,
        @name, superclass, @includes, @attributes, @method_list, @aliases
      ]
    end

  end

  ##
  # A singleton class

  class SingleClass < ClassModule
  end

  ##
  # A normal module, like NormalClass

  class NormalModule < ClassModule

    def comment=(comment)
      return if comment.empty?
      comment = @comment << "# ---\n" << comment unless @comment.empty?

      super
    end

    def inspect
      "#<%s:0x%x module %s includes: %p attributes: %p methods: %p aliases: %p>" % [
        self.class, object_id,
        @name, @includes, @attributes, @method_list, @aliases
      ]
    end

    def module?
      true
    end

  end

  ##
  # AnyMethod is the base class for objects representing methods

  class AnyMethod < CodeObject

    ##
    # Method name

    attr_accessor :name

    ##
    # public, protected, private

    attr_accessor :visibility

    ##
    # Parameters yielded by the called block

    attr_accessor :block_params

    ##
    # Don't rename \#initialize to \::new

    attr_accessor :dont_rename_initialize

    ##
    # Is this a singleton method?

    attr_accessor :singleton

    attr_reader :text

    ##
    # Array of other names for this method

    attr_reader   :aliases

    ##
    # The method we're aliasing

    attr_accessor :is_alias_for

    ##
    # Parameters for this method

    attr_overridable :params, :param, :parameters, :parameter

    ##
    # Different ways to call this method

    attr_accessor :call_seq

    include TokenStream

    def initialize(text, name)
      super()
      @text = text
      @name = name
      @token_stream  = nil
      @visibility    = :public
      @dont_rename_initialize = false
      @block_params  = nil
      @aliases       = []
      @is_alias_for  = nil
      @comment = ""
      @call_seq = nil
    end

    ##
    # Order by #name

    def <=>(other)
      @name <=> other.name
    end

    ##
    # Adds +method+ as an alias for this method

    def add_alias(method)
      @aliases << method
    end

    def inspect # :nodoc:
      alias_for = @is_alias_for ? " (alias for #{@is_alias_for.name})" : nil
      "#<%s:0x%x %s%s%s (%s)%s>" % [
        self.class, object_id,
        parent_name,
        singleton ? '::' : '#',
        name,
        visibility,
        alias_for,
      ]
    end

    ##
    # Pretty parameter list for this method

    def param_seq
      params = params.gsub(/\s*\#.*/, '')
      params = params.tr("\n", " ").squeeze(" ")
      params = "(#{params})" unless p[0] == ?(

      if block = block_params then # yes, =
        # If this method has explicit block parameters, remove any explicit
        # &block
        params.sub!(/,?\s*&\w+/)

        block.gsub!(/\s*\#.*/, '')
        block = block.tr("\n", " ").squeeze(" ")
        if block[0] == ?(
          block.sub!(/^\(/, '').sub!(/\)/, '')
        end
        params << " { |#{block}| ... }"
      end

      params
    end

    def to_s # :nodoc:
      res = self.class.name + ": " + @name + " (" + @text + ")\n"
      res << @comment.to_s
      res
    end

  end

  ##
  # GhostMethod represents a method referenced only by a comment

  class GhostMethod < AnyMethod
  end

  ##
  # MetaMethod represents a meta-programmed method

  class MetaMethod < AnyMethod
  end

  ##
  # Represent an alias, which is an old_name/new_name pair associated with a
  # particular context

  class Alias < CodeObject

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

  ##
  # A constant

  class Constant < CodeObject

    ##
    # The constant's name

    attr_accessor :name

    ##
    # The constant's value

    attr_accessor :value

    ##
    # Creates a new constant with +name+, +value+ and +comment+

    def initialize(name, value, comment)
      super()
      @name = name
      @value = value
      self.comment = comment
    end

  end

  ##
  # An attribute created by \#attr, \#attr_reader, \#attr_writer or
  # \#attr_accessor

  class Attr < CodeObject

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

  ##
  # A file loaded by \#require

  class Require < CodeObject

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

  ##
  # A Module include in a class with \#include

  class Include < CodeObject

    ##
    # Name of included module

    attr_accessor :name

    def initialize(name, comment)
      super()
      @name = name
      self.comment = comment
    end

    def inspect # :nodoc:
      "#<%s:0x%x %s.include %s>" % [
        self.class,
        object_id,
        parent_name, @name,
      ]
    end

  end

end
