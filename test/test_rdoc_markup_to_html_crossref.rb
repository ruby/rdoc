require 'rubygems'
require 'minitest/unit'
require 'rdoc/generator'
require 'rdoc/stats'
require 'rdoc/code_objects'
require 'rdoc/markup/to_html_crossref'
require 'rdoc/parser/ruby'

require 'pathname'

class TestRDocMarkupToHtmlCrossref < MiniTest::Unit::TestCase

  XREF_DATA = <<-XREF_DATA
class C1
  def self.m
  end

  def m
  end
end

class C2
  class C3
    def m
    end

    class H1
      def m?
      end
    end
  end
end

class C3
  class H1
  end

  class H2
  end
end

class C4
  class C4
  end
end
  XREF_DATA

  def setup
    RDoc::TopLevel.reset

    RDoc::Generator::Method.reset
    top_level = RDoc::TopLevel.new 'xref_data.rb'

    options = RDoc::Options.new
    options.quiet = true
    options.inline_source = true # don't build HTML files

    stats = RDoc::Stats.new 0

    parser = RDoc::Parser::Ruby.new top_level, 'xref_data.rb', XREF_DATA,
                                    options, stats
    top_levels = []
    top_levels.push parser.scan

    files, classes = RDoc::Generator::Context.build_indices top_levels, options

    @class_hash = {}

    classes.each do |klass|
      @class_hash[klass.name] = klass
    end

    @klass = @class_hash['C1']
    @xref = RDoc::Markup::ToHtmlCrossref.new 'index.html', @klass, true
  end

  def assert_ref(path, ref)
    assert_equal "<p>\n<a href=\"#{path}\">#{ref}</a>\n</p>\n",
                 @xref.convert(ref)
  end

  def refute_ref(body, ref)
    assert_equal "<p>\n#{body}\n</p>\n", @xref.convert(ref)
  end

  def test_handle_special_CROSSREF_C2
    @klass = @class_hash['C2']
    @xref = RDoc::Markup::ToHtmlCrossref.new 'classes/C2.html', @klass, true

    refute_ref '#m', '#m'

    assert_ref 'C2/C3.html', 'C2::C3'
    assert_ref 'C2/C3.html#M000003', 'C2::C3#m'
    assert_ref 'C2/C3/H1.html', 'C3::H1'
    assert_ref 'C4.html', 'C4'

    # TODO there is a C3::H2 in the top-level namespace and RDoc should follow
    # constant scoping rules
    refute_ref 'C3::H2', 'C3::H2'
    refute_ref 'H1', 'H1'
  end

  def test_handle_special_CROSSREF_C2_C3
    @klass = @class_hash['C2::C3']
    @xref = RDoc::Markup::ToHtmlCrossref.new 'classes/C2/C3.html', @klass, true

    assert_ref 'C3.html#M000003', '#m'

    assert_ref 'C3.html', 'C3'
    assert_ref 'C3.html#M000003', 'C3#m'

    assert_ref 'C3/H1.html', 'H1'
    assert_ref 'C3/H1.html', 'C3::H1'

    assert_ref '../C4.html', 'C4'

    refute_ref 'C3::H2', 'C3::H2'
  end

  def test_handle_special_CROSSREF_C3
    @klass = @class_hash['C3']
    @xref = RDoc::Markup::ToHtmlCrossref.new 'classes/C3.html', @klass, true

    assert_ref 'C3.html', 'C3'

    refute_ref '#m',   '#m'
    refute_ref 'C3#m', 'C3#m'

    assert_ref 'C3/H1.html', 'H1'

    assert_ref 'C3/H1.html', 'C3::H1'
    assert_ref 'C3/H2.html', 'C3::H2'

    assert_ref 'C4.html', 'C4'
  end

  def test_handle_special_CROSSREF_C4
    @klass = @class_hash['C4']
    @xref = RDoc::Markup::ToHtmlCrossref.new 'classes/C4.html', @klass, true

    # C4 ref inside a C4 containing a C4 should resolve to the contained class
    assert_ref 'C4/C4.html', 'C4'
  end

  def test_handle_special_CROSSREF_C4_C4
    @klass = @class_hash['C4::C4']
    @xref = RDoc::Markup::ToHtmlCrossref.new 'classes/C4/C4.html', @klass, true

    # A C4 reference inside a C4 class contained within a C4 class should
    # resolve to the inner C4 class.
    assert_ref 'C4.html', 'C4'
  end

  def test_handle_special_CROSSREF_class
    assert_ref 'classes/C1.html', 'C1'
    refute_ref 'H1', 'H1'

    assert_ref 'classes/C2.html',       'C2'
    assert_ref 'classes/C2/C3.html',    'C2::C3'
    assert_ref 'classes/C2/C3/H1.html', 'C2::C3::H1'

    assert_ref 'classes/C3.html',    '::C3'
    assert_ref 'classes/C3/H1.html', '::C3::H1'

    assert_ref 'classes/C4/C4.html', 'C4::C4'
  end

  def test_handle_special_CROSSREF_file
    assert_ref 'files/xref_data_rb.html', 'xref_data.rb'
  end

  def test_handle_special_CROSSREF_method
    refute_ref 'm', 'm'
    assert_ref 'classes/C1.html#M000001', '#m'

    assert_ref 'classes/C1.html#M000001', 'C1#m'
    assert_ref 'classes/C1.html#M000001', 'C1#m()'
    assert_ref 'classes/C1.html#M000001', 'C1#m(*)'

    assert_ref 'classes/C1.html#M000001', 'C1.m'
    assert_ref 'classes/C1.html#M000001', 'C1.m()'
    assert_ref 'classes/C1.html#M000001', 'C1.m(*)'

    # HACK should this work
    #assert_ref 'classes/C1.html#M000001', 'C1::m'
    #assert_ref 'classes/C1.html#M000001', 'C1::m()'
    #assert_ref 'classes/C1.html#M000001', 'C1::m(*)'

    assert_ref 'classes/C2/C3.html#M000003', 'C2::C3#m'

    assert_ref 'classes/C2/C3.html#M000003', 'C2::C3.m'

    assert_ref 'classes/C2/C3/H1.html#M000004', 'C2::C3::H1#m?'

    assert_ref 'classes/C2/C3.html#M000003', '::C2::C3#m'
    assert_ref 'classes/C2/C3.html#M000003', '::C2::C3#m()'
    assert_ref 'classes/C2/C3.html#M000003', '::C2::C3#m(*)'
  end

  def test_handle_special_CROSSREF_no_ref
    assert_equal '', @xref.convert('')

    refute_ref 'bogus', 'bogus'
    refute_ref 'bogus', '\bogus'

    refute_ref '#n',    '\#n'
    refute_ref '#n()',  '\#n()'
    refute_ref '#n(*)', '\#n(*)'

    refute_ref 'C1',   '\C1'
    refute_ref '::C3', '\::C3'

    refute_ref '::C3::H1#n',    '::C3::H1#n'
    refute_ref '::C3::H1#n(*)', '::C3::H1#n(*)'
    refute_ref '::C3::H1#n',    '\::C3::H1#n'
  end

  def test_handle_special_CROSSREF_special
    assert_equal "<p>\n<a href=\"classes/C2/C3.html\">C2::C3</a>;method(*)\n</p>\n",
                 @xref.convert('C2::C3;method(*)')
  end

end

MiniTest::Unit.autorun
