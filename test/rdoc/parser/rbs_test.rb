# frozen_string_literal: true

require_relative '../helper'
require 'rdoc/parser'
require 'rdoc/generator/markup'

class RDocParserRBSTest < RDoc::TestCase
  def setup
    super

    @filename = 'sample.rbs'
    @top_level = @store.add_file @filename

    @options = RDoc::Options.new
    @options.quiet = true
    @stats = RDoc::Stats.new @store, 0
  end

  def test_can_parse
    assert_equal RDoc::Parser::RBS, RDoc::Parser.can_parse_by_name(@filename)
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

    markup_code = greet.markup_code
    assert_equal 1, markup_code.scan('# File sample.rbs, line 6').size
    refute_match(/line\(s\)/, markup_code)

    name = sample.find_attribute 'name', false
    assert_equal ['String'], name.type_signature_lines

    salutation = sample.find_method 'salutation', false
    assert_equal greet, salutation.is_alias_for
    assert_equal [@top_level], [version, greet, name, salutation].map(&:file).uniq
  end

  def test_scan_omits_class_and_module_alias_declarations
    util_parser(<<~RBS).scan
      class OldClass
      end

      class NewClass = OldClass

      module OldModule
      end

      module NewModule = OldModule
    RBS

    assert @store.find_class_named('OldClass')
    assert @store.find_module_named('OldModule')

    # TODO: RBS class and module aliases should be added to the store.
    assert_nil @store.find_class_named('NewClass')
    assert_nil @store.find_module_named('NewModule')
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

  def test_scan_standalone_visibility_sections_leave_members_public
    util_parser(<<~RBS).scan
      class Sample
        private

        attr_reader token: String
        def authenticate: () -> String
      end
    RBS

    sample = @store.find_class_named 'Sample'
    token = sample.find_attribute 'token', false
    authenticate = sample.find_method 'authenticate', false

    # TODO: Standalone RBS visibility sections should apply to later members.
    assert_equal :public, token.visibility
    assert_equal :public, authenticate.visibility
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

  def test_scan_reparsing_keeps_existing_rbs_method_overlay
    ruby_top_level = @store.add_file 'sample.rb'
    sample = ruby_top_level.add_class RDoc::NormalClass, 'Sample'

    greet = RDoc::AnyMethod.new 'greet'
    greet.comment = 'Ruby method docs.'
    sample.add_method greet

    util_parser(<<~RBS).scan
      class Sample
        # RBS v1 docs.
        def greet: () -> String
      end
    RBS

    @store.clear_file_contributions @filename, keep_position: true

    util_parser(<<~RBS).scan
      class Sample
        # RBS v2 docs.
        def greet: () -> Integer
      end
    RBS

    # TODO: Incremental RBS reparsing should replace the previous RBS overlay.
    assert_equal "Ruby method docs.\n---\nRBS v1 docs.\n---\nRBS v2 docs.",
                 greet.comment.to_s.strip
    assert_equal ['() -> String'], greet.type_signature_lines
  end

  def test_scan_self_question_method_definitions_add_singleton_method_only
    util_parser(<<~RBS).scan
      class Greeter
        def self?.shout: (String text) -> String
      end
    RBS

    greeter = @store.find_class_named 'Greeter'
    shout = greeter.find_method 'shout', true

    assert_equal ['(String text) -> String'], shout.type_signature_lines

    # TODO: RBS self? methods should also create a private instance method.
    assert_nil greeter.find_method('shout', false)
  end

  def test_scan_maps_initialize_to_singleton_new
    util_parser(<<~RBS).scan
      class Sample
        # Build a sample.
        def initialize: (String name) -> void
      end
    RBS

    sample = @store.find_class_named 'Sample'
    constructor = sample.find_method 'new', true

    assert_not_nil constructor
    assert_equal ['(String name) -> void'], constructor.type_signature_lines
    assert_equal 'Build a sample.', constructor.comment.text.strip
    assert_equal :public, constructor.visibility
    assert_nil sample.find_method('initialize', false)
  end

  def test_scan_maps_private_initialize_to_public_singleton_new
    util_parser(<<~RBS).scan
      class Sample
        private def initialize: () -> void
      end
    RBS

    sample = @store.find_class_named 'Sample'
    constructor = sample.find_method 'new', true

    assert_equal :public, constructor.visibility
  end

  def util_parser(content)
    RDoc::Parser::RBS.new @top_level, content, @options, @stats
  end
end
