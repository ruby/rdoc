# frozen_string_literal: true

require_relative 'helper'
require 'rdoc/rbs_helper'
require 'rdoc/markup/formatter'

class RDocRbsHelperTest < RDoc::TestCase
  def test_validate_method_type_valid
    assert_nil RDoc::RbsHelper.validate_method_type('(String) -> void')
    assert_nil RDoc::RbsHelper.validate_method_type('(Integer, ?String) -> bool')
    assert_nil RDoc::RbsHelper.validate_method_type('() -> Array[String]')
  end

  def test_validate_method_type_invalid
    error = RDoc::RbsHelper.validate_method_type('(String ->')
    assert_kind_of String, error
  end

  def test_validate_type_valid
    assert_nil RDoc::RbsHelper.validate_type('String')
    assert_nil RDoc::RbsHelper.validate_type('Array[Integer]')
    assert_nil RDoc::RbsHelper.validate_type('String?')
  end

  def test_validate_type_invalid
    error = RDoc::RbsHelper.validate_type('String[')
    assert_kind_of String, error
  end

  def test_load_signatures_from_directory
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, 'test.rbs'), <<~RBS)
        class Greeter
          def greet: (String name) -> void
          attr_reader language: String
        end
      RBS

      sigs = RDoc::RbsHelper.load_signatures(dir)
      assert_equal '(String name) -> void', sigs['Greeter#greet']
      assert_equal 'String', sigs['Greeter.language']
    end
  end

  def test_signature_to_html_links_known_types
    lookup = { 'String' => 'String.html', 'Integer' => 'Integer.html' }
    result = RDoc::RbsHelper.signature_to_html(["(String) -> Integer"], lookup: lookup, from_path: 'Test.html')

    assert_includes result, '<a href="String.html" class="rbs-type">String</a>'
    assert_includes result, '<a href="Integer.html" class="rbs-type">Integer</a>'
    assert_includes result, '&rarr;'
  end

  def test_signature_to_html_leaves_unknown_types_plain
    result = RDoc::RbsHelper.signature_to_html(["(UnknownType) -> void"], lookup: {}, from_path: 'Test.html')

    refute_includes result, '<a'
    assert_includes result, 'UnknownType'
    assert_includes result, 'void'
  end

  def test_signature_to_html_handles_qualified_names
    lookup = { 'Foo::Bar' => 'Foo/Bar.html' }
    result = RDoc::RbsHelper.signature_to_html(["(::Foo::Bar) -> void"], lookup: lookup, from_path: 'Test.html')

    assert_includes result, '<a href="Foo/Bar.html" class="rbs-type">Foo::Bar</a>'
  end

  def test_signature_to_html_multiline
    lookup = { 'String' => 'String.html', 'Integer' => 'Integer.html' }
    result = RDoc::RbsHelper.signature_to_html(["(String) -> Integer", "(Integer) -> String"], lookup: lookup, from_path: 'Test.html')

    assert_includes result, '<a href="String.html" class="rbs-type">String</a>'
    assert_includes result, '<a href="Integer.html" class="rbs-type">Integer</a>'
    assert_includes result, "\n"
  end

  def test_signature_to_html_union_type
    lookup = { 'String' => 'String.html', 'Integer' => 'Integer.html' }
    result = RDoc::RbsHelper.signature_to_html(["(String | Integer) -> void"], lookup: lookup, from_path: 'Test.html')

    assert_includes result, '<a href="String.html" class="rbs-type">String</a>'
    assert_includes result, '<a href="Integer.html" class="rbs-type">Integer</a>'
  end

  def test_signature_to_html_optional_type
    lookup = { 'String' => 'String.html' }
    result = RDoc::RbsHelper.signature_to_html(["String?"], lookup: lookup, from_path: 'Test.html')

    assert_includes result, '<a href="String.html" class="rbs-type">String</a>'
  end

  def test_signature_to_html_tuple_type
    lookup = { 'String' => 'String.html', 'Integer' => 'Integer.html' }
    result = RDoc::RbsHelper.signature_to_html(["[String, Integer]"], lookup: lookup, from_path: 'Test.html')

    assert_includes result, '<a href="String.html" class="rbs-type">String</a>'
    assert_includes result, '<a href="Integer.html" class="rbs-type">Integer</a>'
  end

  def test_signature_to_html_intersection_type
    lookup = { 'String' => 'String.html', 'Comparable' => 'Comparable.html' }
    result = RDoc::RbsHelper.signature_to_html(["(String & Comparable) -> void"], lookup: lookup, from_path: 'Test.html')

    assert_includes result, '<a href="String.html" class="rbs-type">String</a>'
    assert_includes result, '<a href="Comparable.html" class="rbs-type">Comparable</a>'
  end

  def test_signature_to_html_proc_type
    lookup = { 'String' => 'String.html', 'Integer' => 'Integer.html' }
    result = RDoc::RbsHelper.signature_to_html(["^(String) -> Integer"], lookup: lookup, from_path: 'Test.html')

    assert_includes result, '<a href="String.html" class="rbs-type">String</a>'
    assert_includes result, '<a href="Integer.html" class="rbs-type">Integer</a>'
  end

  def test_signature_to_html_links_block_return_type
    lookup = { 'String' => 'String.html', 'Integer' => 'Integer.html' }
    result = RDoc::RbsHelper.signature_to_html(["() { (String) -> Integer } -> void"], lookup: lookup, from_path: 'Test.html')

    assert_includes result, '<a href="String.html" class="rbs-type">String</a>'
    assert_includes result, '<a href="Integer.html" class="rbs-type">Integer</a>'
  end
end
