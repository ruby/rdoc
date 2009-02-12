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
    @options.inline_source = true # don't build HTML files

    stats = RDoc::Stats.new 0

    parser = RDoc::Parser::Ruby.new @top_level, @file_name, XREF_DATA, @options,
                                    stats
    @top_levels = []
    @top_levels.push parser.scan
  end

end

