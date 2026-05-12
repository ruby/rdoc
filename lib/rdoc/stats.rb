# frozen_string_literal: true
##
# RDoc statistics collector which prints a summary and report of a project's
# documentation totals.

class RDoc::Stats

  include RDoc::Text

  ##
  # Display order for item types in the coverage report

  TYPE_ORDER = %w[Class Module Constant Attribute Method].freeze

  ##
  # Message displayed when all items are documented

  GREAT_JOB_MESSAGE = <<~MSG
    100% documentation!
    Great Job!
  MSG

  ##
  # Output level for the coverage report

  attr_reader :coverage_level

  ##
  # Count of files parsed during parsing

  attr_reader :files_so_far

  ##
  # Total number of files found

  attr_reader :num_files

  ##
  # Creates a new Stats that will have +num_files+.  +verbosity+ defaults to 1
  # which will create an RDoc::Stats::Normal outputter.

  def initialize(store, num_files, verbosity = 1)
    @num_files = num_files
    @store     = store

    @coverage_level   = 0
    @doc_items        = nil
    @files_so_far     = 0
    @fully_documented = false
    @num_params       = 0
    @percent_doc      = nil
    @start            = Time.now
    @undoc_params     = 0

    self.verbosity = verbosity
  end

  ##
  # Sets the verbosity level, rebuilding the display outputter.

  def verbosity=(verbosity)
    @display = case verbosity
               when 0 then Quiet.new   @num_files
               when 1 then Normal.new  @num_files
               else        Verbose.new @num_files
               end
  end

  ##
  # Records the parsing of an alias +as+.

  def add_alias(as)
    @display.print_alias as
  end

  ##
  # Records the parsing of an attribute +attribute+

  def add_attribute(attribute)
    @display.print_attribute attribute
  end

  ##
  # Records the parsing of a class +klass+

  def add_class(klass)
    @display.print_class klass
  end

  ##
  # Records the parsing of +constant+

  def add_constant(constant)
    @display.print_constant constant
  end

  ##
  # Records the parsing of +file+

  def add_file(file)
    @files_so_far += 1
    @display.print_file @files_so_far, file
  end

  ##
  # Records the parsing of +method+

  def add_method(method)
    @display.print_method method
  end

  ##
  # Records the parsing of a module +mod+

  def add_module(mod)
    @display.print_module mod
  end

  ##
  # Call this to mark the beginning of parsing for display purposes

  def begin_adding
    @display.begin_adding
  end

  ##
  # Calculates documentation totals and percentages for classes, modules,
  # constants, attributes and methods.

  def calculate
    return if @doc_items

    ucm = @store.unique_classes_and_modules

    classes = @store.unique_classes.reject { |cm| cm.full_name == 'Object' }

    constants = []
    ucm.each { |cm| constants.concat cm.constants }

    methods = []
    ucm.each { |cm| methods.concat cm.method_list }

    attributes = []
    ucm.each { |cm| attributes.concat cm.attributes }

    @num_attributes, @undoc_attributes = doc_stats attributes
    @num_classes,    @undoc_classes    = doc_stats classes
    @num_constants,  @undoc_constants  = doc_stats constants
    @num_methods,    @undoc_methods    = doc_stats methods
    @num_modules,    @undoc_modules    = doc_stats @store.unique_modules

    @num_items =
      @num_attributes +
      @num_classes +
      @num_constants +
      @num_methods +
      @num_modules +
      @num_params

    @undoc_items =
      @undoc_attributes +
      @undoc_classes +
      @undoc_constants +
      @undoc_methods +
      @undoc_modules +
      @undoc_params

    @doc_items = @num_items - @undoc_items
  end

  ##
  # Sets coverage report level.  Accepted values are:
  #
  # false or nil:: No report
  # 0:: Classes, modules, constants, attributes, methods
  # 1:: Level 0 + method parameters

  def coverage_level=(level)
    level = -1 unless level

    @coverage_level = level
  end

  ##
  # Returns the length and number of undocumented items in +collection+.

  def doc_stats(collection)
    visible = collection.select { |item| item.display? }
    [visible.length, visible.count { |item| not item.documented? }]
  end

  ##
  # Call this to mark the end of parsing for display purposes

  def done_adding
    @display.done_adding
  end

  ##
  # The documentation status of this project.  +true+ when 100%, +false+ when
  # less than 100% and +nil+ when unknown.
  #
  # Set by calling #calculate

  def fully_documented?
    @fully_documented
  end

  ##
  # Calculates the percentage of items documented.

  def percent_doc
    return @percent_doc if @percent_doc

    @fully_documented = (@num_items - @doc_items) == 0

    @percent_doc = @doc_items.to_f / @num_items * 100 if @num_items.nonzero?
    @percent_doc ||= 0

    @percent_doc
  end

  ##
  # Returns a report on which items are not documented

  def report
    if @coverage_level > 0 then
      extend RDoc::Text
    end

    if @coverage_level.zero? then
      calculate

      return GREAT_JOB_MESSAGE if @num_items == @doc_items
    end

    items, empty_classes = collect_undocumented_items

    if @coverage_level > 0 then
      calculate

      return GREAT_JOB_MESSAGE if @num_items == @doc_items
    end

    report = +""
    report << "The following items are not documented:\n\n"

    # Referenced-but-empty classes
    empty_classes.each do |cm|
      report << "#{cm.full_name} is referenced but empty.\n"
      report << "It probably came from another project.  I'm sorry I'm holding it against you.\n\n"
    end

    # Group items by file, then by type
    by_file = items.group_by { |item| item[:file] }

    by_file.sort_by { |file, _| file }.each do |file, file_items|
      report << "#{file}:\n"

      by_type = file_items.group_by { |item| item[:type] }

      TYPE_ORDER.each do |type|
        next unless by_type[type]

        report << "  #{type}:\n"

        sorted = by_type[type].sort_by { |item| [item[:line] || 0, item[:name]] }
        name_width = sorted.reduce(0) { |max, item| item[:line] && item[:name].length > max ? item[:name].length : max }

        sorted.each do |item|
          if item[:line]
            report << "    %-*s %s:%d\n" % [name_width, item[:name], item[:file], item[:line]]
          else
            report << "    #{item[:name]}\n"
          end

          if item[:undoc_params]
            report << "      Undocumented params: #{item[:undoc_params].join(', ')}\n"
          end
        end
      end

      report << "\n"
    end

    report
  end

  ##
  # Collects all undocumented items across all classes and modules.
  # Returns [items, empty_classes] where items is an Array of Hashes
  # with keys :type, :name, :file, :line, and empty_classes is an
  # Array of ClassModule objects that are referenced but have no files.

  def collect_undocumented_items
    empty_classes = []
    items = []

    @store.unique_classes_and_modules.each do |class_module|
      next unless class_module.display?

      if class_module.in_files.empty?
        empty_classes << class_module
        next
      end

      unless class_module.documented? || class_module.full_name == 'Object'
        collect_undocumented_class_module(class_module, items)
      end

      collect_undocumented_constants(class_module, items)
      collect_undocumented_attributes(class_module, items)
      collect_undocumented_methods(class_module, items)
    end

    [items, empty_classes]
  end

  ##
  # Collects undocumented classes or modules from +class_module+ into +items+.
  # Reopened classes/modules are reported in every file they appear in.

  def collect_undocumented_class_module(class_module, items)
    class_module.in_files.map(&:full_name).uniq.each do |file|
      items << {
        type: class_module.type.capitalize,
        name: class_module.full_name,
        file: file,
        line: nil,
      }
    end
  end

  ##
  # Collects undocumented constants from +class_module+ into +items+.

  def collect_undocumented_constants(class_module, items)
    class_module.constants.each do |constant|
      next unless constant.display?
      next if constant.documented? || constant.is_alias_for

      file = constant.file&.full_name
      next unless file

      items << {
        type: "Constant",
        name: constant.full_name,
        file: file,
        line: constant.line,
      }
    end
  end

  ##
  # Collects undocumented attributes from +class_module+ into +items+.

  def collect_undocumented_attributes(class_module, items)
    class_module.attributes.each do |attr|
      next unless attr.display?
      next if attr.documented?

      file = attr.file&.full_name
      next unless file

      scope = attr.singleton ? "." : "#"
      items << {
        type: "Attribute",
        name: "#{class_module.full_name}#{scope}#{attr.name}",
        file: file,
        line: attr.line,
      }
    end
  end

  ##
  # Collects undocumented methods from +class_module+ into +items+.
  # At coverage level > 0, also counts undocumented parameters.

  def collect_undocumented_methods(class_module, items)
    class_module.each_method do |method|
      next unless method.display?
      next if method.documented? && @coverage_level.zero?

      undoc_param_names = nil

      if @coverage_level > 0
        params, undoc = undoc_params method
        @num_params += params

        unless undoc.empty?
          @undoc_params += undoc.length
          undoc_param_names = undoc
        end
      end

      next if method.documented? && !undoc_param_names

      file = method.file&.full_name
      next unless file

      scope = method.singleton ? "." : "#"
      item = {
        type: "Method",
        name: "#{class_module.full_name}#{scope}#{method.name}",
        file: file,
        line: method.line,
      }
      item[:undoc_params] = undoc_param_names if undoc_param_names

      items << item
    end
  end

  ##
  # Returns a summary of the collected statistics.

  def summary
    calculate

    num_width = [@num_files, @num_items].max.to_s.length
    undoc_width = [
      @undoc_attributes,
      @undoc_classes,
      @undoc_constants,
      @undoc_items,
      @undoc_methods,
      @undoc_modules,
      @undoc_params,
    ].max.to_s.length

    report = +""

    report << "Files:      %*d\n" % [num_width, @num_files]
    report << "\n"
    report << "Classes:    %*d (%*d undocumented)\n" % [
      num_width, @num_classes, undoc_width, @undoc_classes]
    report << "Modules:    %*d (%*d undocumented)\n" % [
      num_width, @num_modules, undoc_width, @undoc_modules]
    report << "Constants:  %*d (%*d undocumented)\n" % [
      num_width, @num_constants, undoc_width, @undoc_constants]
    report << "Attributes: %*d (%*d undocumented)\n" % [
      num_width, @num_attributes, undoc_width, @undoc_attributes]
    report << "Methods:    %*d (%*d undocumented)\n" % [
      num_width, @num_methods, undoc_width, @undoc_methods]
    report << "Parameters: %*d (%*d undocumented)\n" % [
      num_width, @num_params, undoc_width, @undoc_params] if
        @coverage_level > 0
    report << "\n"
    report << "Total:      %*d (%*d undocumented)\n" % [
      num_width, @num_items, undoc_width, @undoc_items]
    report << "%6.2f%% documented\n" % percent_doc
    report << "\n"
    report << "Elapsed: %0.1fs\n" % (Time.now - @start)

    report
  end

  ##
  # Determines which parameters in +method+ were not documented.  Returns a
  # total parameter count and an Array of undocumented methods.

  def undoc_params(method)
    @formatter ||= RDoc::Markup::ToTtOnly.new

    params = method.param_list

    params = params.map { |param| param.gsub(/^\*\*?/, '') }

    return 0, [] if params.empty?

    document = parse method.comment

    tts = document.accept @formatter

    undoc = params - tts

    [params.length, undoc]
  end

  autoload :Quiet,   "#{__dir__}/stats/quiet"
  autoload :Normal,  "#{__dir__}/stats/normal"
  autoload :Verbose, "#{__dir__}/stats/verbose"

end
