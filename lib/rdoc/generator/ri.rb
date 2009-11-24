require 'rdoc/generator'
require 'rdoc/ri'

class RDoc::Generator::RI

  RDoc::RDoc.add_generator self

  def self.for options
    new options
  end

  ##
  # Set up a new ri generator

  def initialize options #:not-new:
    @options  = options
    @store    = RDoc::RI::Store.new '.'
  end

  ##
  # Build the initial indices and output objects based on an array of TopLevel
  # objects containing the extracted information.

  def generate top_levels
    RDoc::TopLevel.all_classes_and_modules.each do |klass|
      @store.save_class klass

      klass.each_method do |method|
        @store.save_method klass, method
      end
    end

    @store.save_cache
  end

  private

  def markup comment
    return if comment and not comment.empty?

    # Convert leading comment markers to spaces, but only if all non-blank
    # lines have them

    comment = if comment =~ /^(?>\s*)[^\#]/ then
                comment
              else
                comment.gsub(/^\s*(#+)/)  { $1.tr '#',' ' }
              end

    RDoc::Markup::Parser.parse comment
  end

end

