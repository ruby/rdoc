# frozen_string_literal: true

require_relative 'helper'
require 'rdoc/rbs_support'

class RDocRbsSupportTest < RDoc::TestCase
  def test_validate_method_type_valid
    assert_nil RDoc::RbsSupport.validate_method_type('(String) -> void')
    assert_nil RDoc::RbsSupport.validate_method_type('(Integer, ?String) -> bool')
    assert_nil RDoc::RbsSupport.validate_method_type('() -> Array[String]')
  end

  def test_validate_method_type_invalid
    error = RDoc::RbsSupport.validate_method_type('(String ->')
    assert_kind_of String, error
  end

  def test_validate_type_valid
    assert_nil RDoc::RbsSupport.validate_type('String')
    assert_nil RDoc::RbsSupport.validate_type('Array[Integer]')
    assert_nil RDoc::RbsSupport.validate_type('String?')
  end

  def test_validate_type_invalid
    error = RDoc::RbsSupport.validate_type('String[')
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

      sigs = RDoc::RbsSupport.load_signatures(dir)
      assert_equal '(String name) -> void', sigs['Greeter#greet']
      assert_equal 'String', sigs['Greeter.language']
    end
  end

  def test_merge_into_store
    top_level = @store.add_file 'test.rb'
    cm = top_level.add_class RDoc::NormalClass, 'Greeter'

    m = RDoc::AnyMethod.new(nil, 'greet')
    m.params = '(name)'
    cm.add_method m

    a = RDoc::Attr.new(nil, 'language', 'R', '')
    cm.add_attribute a

    signatures = {
      'Greeter#greet' => '(String name) -> void',
      'Greeter.language' => 'String'
    }

    RDoc::RbsSupport.merge_into_store(@store, signatures)

    assert_equal '(String name) -> void', m.type_signature
    assert_equal 'String', a.type_signature
  end

  def test_merge_does_not_overwrite_inline_annotations
    top_level = @store.add_file 'test.rb'
    cm = top_level.add_class RDoc::NormalClass, 'Greeter'

    m = RDoc::AnyMethod.new(nil, 'greet')
    m.params = '(name)'
    m.type_signature = '(String) -> void'
    cm.add_method m

    signatures = {
      'Greeter#greet' => '(String name, ?Integer count) -> void'
    }

    RDoc::RbsSupport.merge_into_store(@store, signatures)

    assert_equal '(String) -> void', m.type_signature
  end
end
