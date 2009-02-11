require 'rubygems'
require 'minitest/unit'
require 'rdoc/generator'
require 'rdoc/stats'
require 'rdoc/code_objects'
require 'rdoc/parser/ruby'

class TestRDocGeneratorContext < MiniTest::Unit::TestCase

  DATA = <<-DATA
class Foo # :nodoc:
end

class Bar
end
  DATA

  def setup
    RDoc::TopLevel.reset
    RDoc::Generator::Method.reset

    top_level = RDoc::TopLevel.new 'data.rb'

    @options = RDoc::Options.new
    @options.quiet = true
    @options.inline_source = true

    stats = RDoc::Stats.new 0

    parser = RDoc::Parser::Ruby.new top_level, 'data.rb', DATA, @options, stats

    @top_levels = []
    @top_levels.push parser.scan
  end

  def test_class_build_indices
    files, classes = RDoc::Generator::Context.build_indices @top_levels, @options

    assert_equal 1, classes.length

    assert_equal 'Bar', classes.first.name

    # HACK complete
  end

end

