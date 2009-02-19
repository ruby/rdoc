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
    @xref_data = RDoc::TopLevel.new @file_name

    @options = RDoc::Options.new
    @options.quiet = true

    stats = RDoc::Stats.new 0

    parser = RDoc::Parser::Ruby.new @xref_data, @file_name, XREF_DATA, @options,
                                    stats
    @top_levels = []
    @top_levels.push parser.scan

    @c1    = @xref_data.find_module_named 'C1'
    @c2    = @xref_data.find_module_named 'C2'
    @c2_c3 = @xref_data.find_module_named 'C2::C3'
    @c3    = @xref_data.find_module_named 'C3'
    @c4    = @xref_data.find_module_named 'C4'
    @c4_c4 = @xref_data.find_module_named 'C4::C4'

    @m1    = @xref_data.find_module_named 'M1'
  end

end

MiniTest::Unit.autorun

