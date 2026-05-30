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

  def util_parser(content)
    RDoc::Parser::RBS.new @top_level, content, @options, @stats
  end
end
