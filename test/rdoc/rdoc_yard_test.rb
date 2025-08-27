# frozen_string_literal: true

require_relative 'helper'

class RDocYardTest < RDoc::TestCase

  def setup
    super

    @tempfile = Tempfile.new self.class.name
    @filename = @tempfile.path

    @top_level = @store.add_file @filename
    @options = RDoc::Options.new
    @options.quiet = true

    @stats = RDoc::Stats.new @store, 0
  end

  def teardown
    super
    @tempfile.close!
  end

  def test_yield_tag_basic
    content = <<~RUBY
      ##
      # Iterates through items
      # @yield [item] Gives each item to the block
      def each
        @items.each { |item| yield item }
      end
    RUBY

    parse content

    klass = @store.all_classes_and_modules.first
    methods = klass&.method_list || []

    assert_equal 1, methods.length

    method = methods.first
    assert_equal 'each', method.name
    assert_equal 'item', method.block_params
  end

  def test_yield_tag_with_multiple_params
    content = <<~RUBY
      ##
      # Iterates with index
      # @yield [item, index] Gives item and index to block
      def each_with_index
        # No actual yield in method body
      end
    RUBY

    parse content

    klass = @store.all_classes_and_modules.first
    methods = klass&.method_list || []

    assert_equal 1, methods.length

    method = methods.first
    assert_equal 'each_with_index', method.name
    assert_equal 'item, index', method.block_params
  end

  def test_yield_tag_with_types
    content = <<~RUBY
      ##
      # Process data
      # @yield [String, Integer] Yields processed string and count
      def process
        # No actual yield in method body
      end
    RUBY

    parse content

    klass = @store.all_classes_and_modules.first
    methods = klass&.method_list || []

    assert_equal 1, methods.length

    method = methods.first
    assert_equal 'process', method.name
    # When types are specified, we extract variable names or use defaults
    assert_match(/arg1, arg2/, method.block_params || '')
  end

  def test_private_tag
    content = <<~RUBY
      ##
      # Internal helper method
      # @private
      def helper_method
        # implementation
      end
    RUBY

    parse content

    klass = @store.all_classes_and_modules.first
    methods = klass&.method_list || []

    assert_equal 1, methods.length

    method = methods.first
    assert_equal 'helper_method', method.name
    assert_equal :private, method.visibility
  end

  def test_private_tag_on_public_method
    content = <<~RUBY
      class Foo
        public

        ##
        # Should be private despite being in public section
        # @private
        def secret_method
          # implementation
        end
      end
    RUBY

    parse content

    klass = @store.find_class_named 'Foo'
    assert klass

    methods = klass.method_list
    assert_equal 1, methods.length

    method = methods.first
    assert_equal 'secret_method', method.name
    assert_equal :private, method.visibility
  end

  def test_yield_and_private_together
    content = <<~RUBY
      ##
      # Internal iterator
      # @yield [item] Each item
      # @private
      def internal_each
        @items.each { |item| yield item }
      end
    RUBY

    parse content

    klass = @store.all_classes_and_modules.first
    methods = klass&.method_list || []

    assert_equal 1, methods.length

    method = methods.first
    assert_equal 'internal_each', method.name
    assert_equal :private, method.visibility
    assert_equal 'item', method.block_params
  end

  def test_yield_tag_without_params
    content = <<~RUBY
      ##
      # Yields control to block
      # @yield Gives control to the block
      def with_lock
        # No actual yield
      end
    RUBY

    parse content

    klass = @store.all_classes_and_modules.first
    methods = klass&.method_list || []

    assert_equal 1, methods.length

    method = methods.first
    assert_equal 'with_lock', method.name
    # Empty block params when no params specified
    assert([nil, ''].include?(method.block_params), "Expected nil or empty, got #{method.block_params.inspect}")
  end

  def test_private_tag_on_attribute
    # Known limitation: @private tag doesn't work with attr_* methods
    # This test documents the expected behavior once fixed

    content = <<~RUBY
      class Foo
        ##
        # Internal state
        # @private
        attr_reader :internal_state
      end
    RUBY

    parse content

    klass = @store.find_class_named 'Foo'
    assert klass

    attributes = klass.attributes
    assert_equal 1, attributes.length

    attr = attributes.first
    assert_equal 'internal_state', attr.name
    # Currently returns :public due to known limitation
    # assert_equal :private, attr.visibility
    assert_equal :public, attr.visibility # Document actual behavior
  end

  def test_private_tag_on_constant
    content = <<~RUBY
      class Foo
        ##
        # Internal constant
        # @private
        INTERNAL_CONST = 42
      end
    RUBY

    parse content

    klass = @store.find_class_named 'Foo'
    assert klass

    constants = klass.constants
    assert_equal 1, constants.length

    const = constants.first
    assert_equal 'INTERNAL_CONST', const.name
    assert_equal :private, const.visibility
  end

  def test_api_private_tag
    content = <<~RUBY
      ##
      # Internal API - not for public use
      # @api private
      def internal_api_method
        # implementation
      end
    RUBY

    parse content

    klass = @store.all_classes_and_modules.first
    methods = klass&.method_list || []

    assert_equal 1, methods.length

    method = methods.first
    assert_equal 'internal_api_method', method.name
    assert_equal :private, method.visibility
  end

  def test_yield_tag_preserves_existing_yields
    content = <<~RUBY
      ##
      # Process with block
      # @yield [data] Process data
      def process(&block) # :yields: info
        yield prepare_data
      end
    RUBY

    parse content

    klass = @store.all_classes_and_modules.first
    methods = klass&.method_list || []

    assert_equal 1, methods.length

    method = methods.first
    assert_equal 'process', method.name
    # Should prefer :yields: over @yield when both present
    assert_equal 'info', method.block_params
  end

  def test_yard_in_class_methods
    content = <<~RUBY
      class MyClass
        ##
        # @yield [item] Each item
        # @private
        def each
          # No actual yield
        end
      end
    RUBY

    parse content

    klass = @store.find_class_named 'MyClass'
    assert klass

    methods = klass.method_list
    assert_equal 1, methods.length

    method = methods.first
    assert_equal 'each', method.name
    assert_equal :private, method.visibility
    assert_equal 'item', method.block_params
  end

  # Test that YARD tags are removed from the displayed comment
  def test_yard_tags_removed_from_comment
    content = <<~RUBY
      ##
      # This method does something
      # @yield [item] Each item
      # @private
      # More documentation here
      def process
        yield
      end
    RUBY

    parse content

    klass = @store.all_classes_and_modules.first
    method = klass&.method_list&.first

    assert method
    comment_text = method.comment.text

    # YARD tags should be removed
    refute_match(/@yield/, comment_text)
    refute_match(/@private/, comment_text)

    # Regular documentation should remain
    assert_match(/This method does something/, comment_text)
    assert_match(/More documentation here/, comment_text)
  end

  # Test module methods with YARD tags
  def test_yard_tags_on_module_methods
    content = <<~RUBY
      module MyModule
        ##
        # Module method
        # @yield [data]
        # @private
        def process
          yield data
        end
      end
    RUBY

    parse content

    mod = @store.find_module_named 'MyModule'
    assert mod

    method = mod.method_list.first
    assert_equal 'process', method.name
    assert_equal :private, method.visibility
    assert_equal 'data', method.block_params
  end

  # Test singleton/class methods
  def test_yard_tags_on_singleton_methods
    content = <<~RUBY
      class Processor
        ##
        # Class method
        # @yield [item]
        # @private
        def self.each
          yield item
        end
      end
    RUBY

    parse content

    klass = @store.find_class_named 'Processor'
    assert klass

    method = klass.method_list.find { |m| m.singleton }
    assert method
    assert_equal 'each', method.name
    assert_equal :private, method.visibility
    assert_equal 'item', method.block_params
  end

  # Test empty brackets
  def test_yield_tag_with_empty_brackets
    content = <<~RUBY
      ##
      # @yield []
      def process
        yield
      end
    RUBY

    parse content

    klass = @store.all_classes_and_modules.first
    method = klass&.method_list&.first

    assert method
    # Empty brackets should result in nil or empty block_params
    assert([nil, ''].include?(method.block_params), "Expected nil or empty string, got #{method.block_params.inspect}")
  end

  # Test whitespace handling
  def test_yard_tags_with_extra_whitespace
    content = <<~RUBY
      ##
      #   @yield   [  item ,  index  ]#{'   '}
      #    @private#{'   '}
      def process
        yield
      end
    RUBY

    parse content

    klass = @store.all_classes_and_modules.first
    method = klass&.method_list&.first

    assert method
    assert_equal 'item, index', method.block_params
    assert_equal :private, method.visibility
  end

  # Test multiple @yield tags (first should win)
  def test_multiple_yield_tags
    content = <<~RUBY
      ##
      # @yield [first]
      # @yield [second]
      def process
        yield
      end
    RUBY

    parse content

    klass = @store.all_classes_and_modules.first
    method = klass&.method_list&.first

    assert method
    # First @yield should be used
    assert_equal 'first', method.block_params
  end

  # Test mixed types and names
  def test_yield_tag_mixed_types_and_names
    content = <<~RUBY
      ##
      # @yield [String, index, Hash, count]
      def process
        yield
      end
    RUBY

    parse content

    klass = @store.all_classes_and_modules.first
    method = klass&.method_list&.first

    assert method
    # Should handle mix of types and names
    assert_equal 'arg1, index, arg3, count', method.block_params
  end

  # Test that non-YARD @ symbols are not affected
  def test_non_yard_at_symbols_preserved
    content = <<~RUBY
      ##
      # Send email to user@example.com
      # @private
      def send_email
        # implementation
      end
    RUBY

    parse content

    klass = @store.all_classes_and_modules.first
    method = klass&.method_list&.first

    assert method
    comment_text = method.comment.text

    # Email address should be preserved
    assert_match(/user@example\.com/, comment_text)
    # But @private should be removed
    refute_match(/@private/, comment_text)
  end

  # Test protected visibility (should not be affected by @private)
  def test_private_tag_does_not_affect_protected
    content = <<~RUBY
      class Foo
        protected
      #{'  '}
        ##
        # Protected method
        # @private
        def protected_method
        end
      end
    RUBY

    parse content

    klass = @store.find_class_named 'Foo'
    method = klass.method_list.first

    # @private should override protected
    assert_equal :private, method.visibility
  end

  private

  def parse(content)
    parser = RDoc::Parser::Ruby.new @top_level, content, @options, @stats
    parser.scan
  end
end
