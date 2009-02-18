require 'rubygems'
require 'minitest/unit'
require 'rdoc/stats'
require 'rdoc/options'
require 'rdoc/code_objects'
require 'rdoc/parser/ruby'
require 'test/xref_data'

class XrefTestCase < MiniTest::Unit::TestCase

  def setup
    RDoc::TopLevel.reset

    @file_name = 'xref_data.rb'
    @top_level = RDoc::TopLevel.new @file_name

    @options = RDoc::Options.new
    @options.quiet = true

    stats = RDoc::Stats.new 0

    parser = RDoc::Parser::Ruby.new @top_level, @file_name, XREF_DATA, @options,
                                    stats
    @top_levels = []
    @top_levels.push parser.scan

    @c1    = @top_level.find_module_named 'C1'
    @c2    = @top_level.find_module_named 'C2'
    @c2_c3 = @top_level.find_module_named 'C2::C3'
    @c3    = @top_level.find_module_named 'C3'
    @c4    = @top_level.find_module_named 'C4'
    @c4_c4 = @top_level.find_module_named 'C4::C4'
  end

end

MiniTest::Unit.autorun

