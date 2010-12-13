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

  ##
  # Stats printer that prints nothing

  class Quiet

    def initialize num_files
      @num_files = num_files
    end

    ##
    # Prints a message at the beginning of parsing

    def begin_adding(*) end

    ##
    # Prints when an alias is added

    def print_alias(*) end

    ##
    # Prints when a class is added

    def print_class(*) end

    ##
    # Prints when a constant is added

    def print_constant(*) end

    ##
    # Prints when a file is added

    def print_file(*) end

    ##
    # Prints when a method is added

    def print_method(*) end

    ##
    # Prints when a module is added

    def print_module(*) end

    ##
    # Prints when RDoc is done

    def done_adding(*) end

  end

  ##
  # Stats printer that prints just the files being documented with a progress
  # bar

  class Normal < Quiet

    def begin_adding # :nodoc:
      puts "Parsing sources..."
    end

    ##
    # Prints a file with a progress bar

    def print_file(files_so_far, filename)
      progress_bar = sprintf("%3d%% [%2d/%2d]  ",
                             100 * files_so_far / @num_files,
                             files_so_far,
                             @num_files)

      if $stdout.tty?
        # Print a progress bar, but make sure it fits on a single line. Filename
        # will be truncated if necessary.
        terminal_width = (ENV['COLUMNS'] || 80).to_i
        max_filename_size = terminal_width - progress_bar.size
        if filename.size > max_filename_size
          # Turn "some_long_filename.rb" to "...ong_filename.rb"
          filename = filename[(filename.size - max_filename_size) .. -1]
          filename[0..2] = "..."
        end

        # Pad the line with whitespaces so that leftover output from the
        # previous line doesn't show up.
        line = "#{progress_bar}#{filename}"
        padding = terminal_width - line.size
        line << (" " * padding) if padding > 0

        $stdout.print("#{line}\r")
      else
        $stdout.puts "#{progress_bar} #{filename}"
      end
      $stdout.flush
    end

    def done_adding # :nodoc:
      puts
    end

  end

  ##
  # Stats printer that prints everything documented, including the documented
  # status

  class Verbose < Normal

    ##
    # Returns a marker for RDoc::CodeObject +co+ being undocumented

    def nodoc co
      " (undocumented)" unless co.documented?
    end

    def print_alias as # :nodoc:
      puts "    alias #{as.new_name} #{as.old_name}#{nodoc as}"
    end

    def print_class(klass) # :nodoc:
      puts "  class #{klass.full_name}#{nodoc klass}"
    end

    def print_constant(constant) # :nodoc:
      puts "    #{constant.name}#{nodoc constant}"
    end

    def print_file(files_so_far, file) # :nodoc:
      super
      puts
    end

    def print_method(method) # :nodoc:
      puts "    #{method.singleton ? '::' : '#'}#{method.name}#{nodoc method}"
    end

    def print_module(mod) # :nodoc:
      puts "  module #{mod.full_name}#{nodoc mod}"
    end

  end

end

