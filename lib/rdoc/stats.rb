require 'rdoc'

##
# RDoc stats collector

class RDoc::Stats

  attr_reader :files_so_far
  attr_reader :num_files

  def initialize(num_files, verbosity = 1)
    @files_so_far = 0
    @num_files = num_files

    @start = Time.now

    @display = case verbosity
               when 0 then Quiet.new   num_files
               when 1 then Normal.new  num_files
               else        Verbose.new num_files
               end
  end

  def begin_adding
    @display.begin_adding
  end

  def add_alias(as)
    @display.print_alias as
  end

  def add_class(klass)
    @display.print_class klass
  end

  def add_constant(constant)
    @display.print_constant constant
  end

  def add_file(file)
    @files_so_far += 1
    @display.print_file @files_so_far, file
  end

  def add_method(method)
    @display.print_method method
  end

  def add_module(mod)
    @display.print_module mod
  end

  def done_adding
    @display.done_adding
  end

  ##
  # Prints a summary of the collected statistics.

  def summary
    ucm = RDoc::TopLevel.unique_classes_and_modules
    constants = []
    ucm.each { |cm| constants.concat cm.constants }

    methods = []
    ucm.each { |cm| methods.concat cm.method_list }

    num_classes,   undoc_classes   = doc_stats RDoc::TopLevel.unique_classes
    num_modules,   undoc_modules   = doc_stats RDoc::TopLevel.unique_modules
    num_constants, undoc_constants = doc_stats constants
    num_methods,   undoc_methods   = doc_stats methods

    items = num_classes + num_modules + num_constants + num_methods
    doc_items = items - undoc_classes - undoc_modules - undoc_constants -
                undoc_methods
    percent_doc = doc_items.to_f / items * 100

    report = []
    report << 'Files:     %5d' % @num_files
    report << 'Classes:   %5d (%5d undocumented)' % [num_classes, undoc_classes]
    report << 'Modules:   %5d (%5d undocumented)' % [num_modules, undoc_modules]
    report << 'Constants: %5d (%5d undocumented)' % [num_constants,
                                                     undoc_constants]
    report << 'Methods:   %5d (%5d undocumented)' % [num_methods, undoc_methods]
    report << '%6.2f%% documented' % percent_doc unless percent_doc.nan?
    report << nil
    report << 'Elapsed: %0.1fs' % (Time.now - @start)

    report.join "\n"
  end

  def doc_stats collection  # :nodoc:
    [collection.length, collection.select { |e| !e.documented? }.length]
  end

  autoload :Quiet,   'rdoc/stats/quiet'
  autoload :Normal,  'rdoc/stats/normal'
  autoload :Verbose, 'rdoc/stats/verbose'

end

