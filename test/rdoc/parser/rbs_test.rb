# frozen_string_literal: true

require_relative '../helper'
require 'rdoc/parser'
require 'rdoc/generator/markup'
require 'rdoc/markup/to_html'

class RDocParserRBSTest < RDoc::TestCase
  def setup
    super

    @filename = 'sample.rbs'
    @top_level = @store.add_file @filename

    @options = RDoc::Options.new
    @options.quiet = true
    @stats = RDoc::Stats.new @store, 0
  end

  def test_scan_adds_rbs_declarations_with_locations_and_signatures
    util_parser(<<~RBS).scan
      # Sample class
      class Sample
        VERSION: String

        # Greets by name.
        def greet: (String) -> Integer
                 | (Symbol) -> String

        # Display name.
        attr_reader name: String

        alias salutation greet
      end
    RBS

    sample = @store.find_class_named 'Sample'
    assert_equal 'Sample class', sample.comment.text.strip

    version = sample.constants.first
    assert_equal 'VERSION', version.name
    assert_equal 'String', version.value

    greet = sample.find_method 'greet', false
    assert_equal ['(String) -> Integer', '(Symbol) -> String'], greet.type_signature_lines
    assert_equal 'Greets by name.', greet.comment.text.strip
    assert_same @top_level, greet.comment.location
    assert_equal 'sample.rbs', greet.comment.parse.file

    markup_code = greet.markup_code
    assert_equal 1, markup_code.scan('# File sample.rbs, line 6').size
    refute_match(/line\(s\)/, markup_code)

    name = sample.find_attribute 'name', false
    assert_equal ['String'], name.type_signature_lines
    assert_same @top_level, name.comment.location
    assert_equal 'sample.rbs', name.comment.parse.file

    salutation = sample.find_method 'salutation', false
    assert_equal greet, salutation.is_alias_for
    assert_equal [@top_level], [version, greet, name, salutation].map(&:file).uniq
  end

  def test_scan_splits_qualified_class_and_module_names
    util_parser(<<~RBS).scan
      module Foo::Bar
      end

      class Foo::Baz
      end
    RBS

    foo = @store.find_module_named 'Foo'
    bar = @store.find_module_named 'Foo::Bar'
    baz = @store.find_class_named 'Foo::Baz'

    assert_not_nil foo
    assert_same bar, foo.modules_hash['Bar']
    assert_same baz, foo.classes_hash['Baz']
  end

  def test_scan_qualifies_nested_mixins
    util_parser(<<~RBS).scan
      module Sample
        module Enumerable
        end

        module Nested
          module Enumerable
          end

          module Extension
          end

          class Collection
            include Enumerable
            extend Extension
          end
        end
      end
    RBS

    collection = @store.find_class_named 'Sample::Nested::Collection'
    assert_equal ['Sample::Nested::Enumerable'], collection.includes.map(&:name)
    assert_equal ['Sample::Nested::Extension'], collection.extends.map(&:name)
  end

  def test_scan_preserves_inline_visibility_modifiers
    util_parser(<<~RBS).scan
      class Sample
        private attr_reader name: String
        private def greet: () -> String
      end
    RBS

    sample = @store.find_class_named 'Sample'
    name = sample.find_attribute 'name', false
    greet = sample.find_method 'greet', false

    assert_equal :private, name.visibility
    assert_equal :private, greet.visibility
  end

  def test_scan_extends_existing_method_documentation
    ruby_top_level = @store.add_file 'sample.rb'
    sample = ruby_top_level.add_class RDoc::NormalClass, 'Sample'
    sample.add_comment 'Ruby class docs.', ruby_top_level

    greet = RDoc::AnyMethod.new 'greet'
    greet.comment = 'Ruby method docs.'
    sample.add_method greet

    util_parser(<<~RBS).scan
      # RBS class docs.
      class Sample
        # RBS method docs.
        def greet: () -> String
      end
    RBS

    assert_equal "Ruby class docs.\n---\nRBS class docs.", sample.comment.to_s.strip
    assert_equal "Ruby method docs.\n---\nRBS method docs.", greet.comment.to_s.strip
    assert_equal ['() -> String'], greet.type_signature_lines
  end

  def test_scan_preserves_rbs_markdown_when_extending_method_documentation
    ruby_top_level = @store.add_file 'sample.rb'
    sample = ruby_top_level.add_class RDoc::NormalClass, 'Sample'

    greet = RDoc::AnyMethod.new 'greet'
    greet.comment = 'Ruby method docs.'
    sample.add_method greet

    util_parser(<<~RBS).scan
      class Sample
        # [RBS method docs](https://example.com/rbs-docs).
        def greet: () -> String
      end
    RBS

    html = RDoc::Markup::ToHtml.new.convert greet.parse(greet.comment)

    assert_include html, '<p>Ruby method docs.</p>'
    assert_include html, '<a href="https://example.com/rbs-docs">RBS method docs</a>'
  end

  def test_scan_extends_existing_attribute_documentation
    ruby_top_level = @store.add_file 'sample.rb'
    sample = ruby_top_level.add_class RDoc::NormalClass, 'Sample'

    name = RDoc::Attr.new 'name', 'R', 'Ruby attribute docs.'
    sample.add_attribute name

    util_parser(<<~RBS).scan
      class Sample
        # RBS attribute docs.
        attr_reader name: String
      end
    RBS

    assert_equal "Ruby attribute docs.\n---\nRBS attribute docs.", name.comment.to_s.strip
    assert_equal ['String'], name.type_signature_lines
  end

  def test_scan_does_not_widen_existing_attribute_reader_with_rbs_writer
    ruby_top_level = @store.add_file 'sample.rb'
    sample = ruby_top_level.add_class RDoc::NormalClass, 'Sample'

    name = RDoc::Attr.new 'name', 'R', 'Ruby attribute docs.'
    sample.add_attribute name

    util_parser(<<~RBS).scan
      class Sample
        # RBS attribute docs.
        attr_writer name: String
      end
    RBS

    assert_equal 'R', name.rw
    assert_equal 'Ruby attribute docs.', name.comment.to_s.strip
    assert_nil name.type_signature_lines
  end

  def test_scan_merges_attr_reader_signature_into_existing_reader_method
    ruby_top_level = @store.add_file 'sample.rb'
    sample = ruby_top_level.add_class RDoc::NormalClass, 'Sample'

    name = RDoc::AnyMethod.new 'name'
    name.comment = 'Ruby method docs.'
    sample.add_method name

    util_parser(<<~RBS).scan
      class Sample
        # RBS attribute docs.
        attr_reader name: String
      end
    RBS

    assert_equal "Ruby method docs.\n---\nRBS attribute docs.", name.comment.to_s.strip
    assert_equal ['String'], name.type_signature_lines
  end

  def test_scan_merges_attr_accessor_into_existing_writer_method_only
    ruby_top_level = @store.add_file 'sample.rb'
    sample = ruby_top_level.add_class RDoc::NormalClass, 'Sample'

    name_writer = RDoc::AnyMethod.new 'name='
    name_writer.comment = 'Ruby writer docs.'
    sample.add_method name_writer

    util_parser(<<~RBS).scan
      class Sample
        # RBS attribute docs.
        attr_accessor name: String
      end
    RBS

    assert_equal "Ruby writer docs.\n---\nRBS attribute docs.", name_writer.comment.to_s.strip
    assert_equal ['String'], name_writer.type_signature_lines
    assert_nil sample.find_attribute('name', false)
  end

  def test_scan_maps_initialize_to_singleton_new
    util_parser(<<~RBS).scan
      class Sample
        # Build a sample.
        def initialize: (String name) -> void
      end

      class PrivateSample
        private def initialize: () -> void
      end
    RBS

    sample = @store.find_class_named 'Sample'
    constructor = sample.find_method 'new', true

    assert_not_nil constructor
    assert_equal ['(String name) -> void'], constructor.type_signature_lines
    assert_equal 'Build a sample.', constructor.comment.text.strip
    assert_equal :public, constructor.visibility
    assert_nil sample.find_method('initialize', false)

    private_sample = @store.find_class_named 'PrivateSample'
    private_constructor = private_sample.find_method 'new', true
    assert_equal :public, private_constructor.visibility
  end

  def util_parser(content)
    RDoc::Parser::RBS.new @top_level, content, @options, @stats
  end
end
