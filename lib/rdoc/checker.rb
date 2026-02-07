# frozen_string_literal: true

##
# RDoc::Checker collects documentation quality check warnings during RDoc
# execution. Warnings are reported at the end and cause a non-zero exit status.
#
# Example usage:
#   RDoc::Checker.add("Missing reference", file: "lib/foo.rb", line: 42)
#
# At the end of rdoc execution, if any warnings were added, they will be
# printed and the process will exit with status 1.

class RDoc::Checker

  ##
  # Represents a single check warning with optional file and line information.

  class Warning
    attr_reader :message, :file, :line

    def initialize(message, file: nil, line: nil)
      @message = message
      @file = file
      @line = line
    end

    def to_s
      if file && line
        "#{file}:#{line}: #{message}"
      elsif file
        "#{file}: #{message}"
      else
        message
      end
    end
  end

  @warnings = []

  class << self
    ##
    # Add a warning to the checker.
    #
    # message - The warning message
    # file - Optional file path where the issue was found
    # line - Optional line number where the issue was found

    def add(message, file: nil, line: nil)
      @warnings << Warning.new(message, file: file, line: line)
    end

    ##
    # Returns all collected warnings.

    def warnings
      @warnings
    end

    ##
    # Clear all warnings. Used between test runs.

    def clear
      @warnings = []
    end

    ##
    # Returns true if any warnings have been collected.

    def any?
      @warnings.any?
    end

    ##
    # Print all collected warnings to stdout.
    # Returns early if no warnings exist.

    def report
      return if @warnings.empty?

      puts
      puts "Documentation check failures:"
      @warnings.each do |warning|
        puts "  #{warning}"
      end
      puts
      puts "#{@warnings.size} check(s) failed"
    end
  end
end
