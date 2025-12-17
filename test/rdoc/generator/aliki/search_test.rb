# frozen_string_literal: true

require_relative '../../support/test_case'

return if RUBY_DESCRIPTION =~ /truffleruby/ || RUBY_DESCRIPTION =~ /jruby/

begin
  require 'mini_racer'
rescue LoadError
  return
end

class RDocGeneratorAlikiSearchRankerTest < Test::Unit::TestCase
  def setup
    @context = MiniRacer::Context.new

    search_ranker_js_path = File.expand_path(
      '../../../../lib/rdoc/generator/template/aliki/js/search_ranker.js',
      __dir__
    )
    search_ranker_js = File.read(search_ranker_js_path)
    @context.eval(search_ranker_js)
  end

  def teardown
    @context.dispose
  end

  # Minimum query length requirement (1 character)
  def test_minimum_query_length_works_for_single_char
    results = run_search(
      query: 'H',
      data: [
        { name: 'Hash', full_name: 'Hash', type: 'class', path: 'Hash.html' },
        { name: 'Help', full_name: 'Help', type: 'class', path: 'Help.html' }
      ]
    )

    assert_equal 2, results.length
  end

  def test_minimum_query_length_works_for_two_chars
    results = run_search(
      query: 'Ha',
      data: [
        { name: 'Hash', full_name: 'Hash', type: 'class', path: 'Hash.html' },
        { name: 'Help', full_name: 'Help', type: 'class', path: 'Help.html' }
      ]
    )

    assert_equal 1, results.length
    assert_equal 'Hash', results[0]['name']
  end

  # Prefix matching ranks higher than substring matching
  def test_prefix_match_ranks_higher_than_substring_match
    results = run_search(
      query: 'Ha',
      data: [
        { name: 'Hash', full_name: 'Hash', type: 'class', path: 'Hash.html' },
        { name: 'Aha', full_name: 'Aha', type: 'class', path: 'Aha.html' }
      ]
    )

    assert_equal 2, results.length
    assert_equal 'Hash', results[0]['name'], "Prefix match should rank first"
    assert_equal 'Aha', results[1]['name'], "Substring match should rank second"
  end

  # Substring matching support
  def test_substring_match_finds_suffix_matches
    results = run_search(
      query: 'ter',
      data: [
        { name: 'filter', full_name: 'Array#filter', type: 'instance_method', path: 'Array.html#filter' },
        { name: 'Hash', full_name: 'Hash', type: 'class', path: 'Hash.html' }
      ]
    )

    assert_equal 1, results.length
    assert_equal 'filter', results[0]['name']
  end

  # Fuzzy matching support (characters in order)
  def test_fuzzy_match_finds_non_contiguous_matches
    results = run_search(
      query: 'addalias',
      data: [
        { name: 'add_foo_alias', full_name: 'RDoc::Context#add_foo_alias', type: 'instance_method', path: 'x' },
        { name: 'add_alias', full_name: 'RDoc::Context#add_alias', type: 'instance_method', path: 'x' },
        { name: 'Hash', full_name: 'Hash', type: 'class', path: 'x' }
      ]
    )

    assert_equal 2, results.length
    # Both are fuzzy matches; shorter name wins
    assert_equal 'add_alias', results[0]['name']
    assert_equal 'add_foo_alias', results[1]['name']
  end

  # Case-based type priority: uppercase query prioritizes classes/modules
  def test_uppercase_query_prioritizes_class_over_method
    results = run_search(
      query: 'Hash',
      data: [
        { name: 'hash', full_name: 'Object#hash', type: 'instance_method', path: 'Object.html#hash' },
        { name: 'Hash', full_name: 'Hash', type: 'class', path: 'Hash.html' }
      ]
    )

    assert_equal 2, results.length
    assert_equal 'Hash', results[0]['name']
    assert_equal 'class', results[0]['type']
    assert_equal 'hash', results[1]['name']
  end

  # Case-based type priority: lowercase query prioritizes methods
  def test_lowercase_query_prioritizes_method_over_class
    results = run_search(
      query: 'hash',
      data: [
        { name: 'Hash', full_name: 'Hash', type: 'class', path: 'Hash.html' },
        { name: 'hash', full_name: 'Object#hash', type: 'instance_method', path: 'Object.html#hash' }
      ]
    )

    assert_equal 2, results.length
    assert_equal 'hash', results[0]['name']
    assert_equal 'instance_method', results[0]['type']
    assert_equal 'Hash', results[1]['name']
  end

  # Unqualified match > qualified match
  def test_unqualified_match_prioritized_over_qualified
    results = run_search(
      query: 'Foo',
      data: [
        { name: 'Foo', full_name: 'Bar::Foo', type: 'class', path: 'Bar/Foo.html' },
        { name: 'Foo', full_name: 'Foo', type: 'class', path: 'Foo.html' }
      ]
    )

    assert_equal 2, results.length
    assert_equal 'Foo', results[0]['full_name']
    assert_equal 'Bar::Foo', results[1]['full_name']
  end

  # Shorter name > longer name
  def test_shorter_name_prioritized
    results = run_search(
      query: 'Hash',
      data: [
        { name: 'Hashable', full_name: 'Hashable', type: 'module', path: 'Hashable.html' },
        { name: 'Hash', full_name: 'Hash', type: 'class', path: 'Hash.html' },
        { name: 'HashWithIndifferentAccess', full_name: 'HashWithIndifferentAccess', type: 'class', path: 'HashWithIndifferentAccess.html' }
      ]
    )

    assert_equal 3, results.length
    assert_equal 'Hash', results[0]['name']
    assert_equal 'Hashable', results[1]['name']
    assert_equal 'HashWithIndifferentAccess', results[2]['name']
  end

  # Class method > instance method
  def test_class_method_prioritized_over_instance_method
    results = run_search(
      query: 'hash',
      data: [
        { name: 'hash', full_name: 'Object#hash', type: 'instance_method', path: 'Object.html#hash' },
        { name: 'hash', full_name: 'Digest::Base::hash', type: 'class_method', path: 'Digest/Base.html#hash' }
      ]
    )

    assert_equal 2, results.length
    assert_equal 'class_method', results[0]['type']
    assert_equal 'instance_method', results[1]['type']
  end

  # Exact full match wins
  def test_exact_full_name_match_wins
    results = run_search(
      query: 'Bar::Foo',
      data: [
        { name: 'Foo', full_name: 'Foo', type: 'class', path: 'Foo.html' },
        { name: 'Foo', full_name: 'Bar::Foo', type: 'class', path: 'Bar/Foo.html' },
        { name: 'Baz', full_name: 'Foo::Baz', type: 'class', path: 'Foo/Baz.html' }
      ]
    )

    assert_equal 1, results.length
    assert_equal 'Bar::Foo', results[0]['full_name']
  end

  # Namespace query matches within namespace
  def test_namespace_query_matches_namespace
    results = run_search(
      query: 'Foo::B',
      data: [
        { name: 'Bar', full_name: 'Bar', type: 'class', path: 'Bar.html' },
        { name: 'Bar', full_name: 'Foo::Bar', type: 'class', path: 'Foo/Bar.html' },
        { name: 'Baz', full_name: 'Foo::Baz', type: 'class', path: 'Foo/Baz.html' }
      ]
    )

    assert_equal 2, results.length
    names = results.map { |r| r['full_name'] }
    assert_includes names, 'Foo::Bar'
    assert_includes names, 'Foo::Baz'
  end

  # Method query with # matches against full_name
  def test_instance_method_query_matches_full_name
    results = run_search(
      query: 'Array#filter',
      data: [
        { name: 'filter', full_name: 'Array#filter', type: 'instance_method', path: 'Array.html#filter' },
        { name: 'filter', full_name: 'Enumerable#filter', type: 'instance_method', path: 'Enumerable.html#filter' },
        { name: 'filter', full_name: 'Hash#filter', type: 'instance_method', path: 'Hash.html#filter' }
      ]
    )

    assert_equal 1, results.length
    assert_equal 'Array#filter', results[0]['full_name']
  end

  # Method query with . matches against full_name (class methods)
  # Note: RDoc uses :: for class methods in full_name, but users may type . (Ruby convention)
  # The search normalizes . to :: so "Array.try_convert" matches "Array::try_convert"
  def test_class_method_query_matches_full_name
    results = run_search(
      query: 'Array.try_convert',
      data: [
        { name: 'try_convert', full_name: 'Array::try_convert', type: 'class_method', path: 'Array.html#try_convert' },
        { name: 'try_convert', full_name: 'Hash::try_convert', type: 'class_method', path: 'Hash.html#try_convert' },
        { name: 'try_convert', full_name: 'String::try_convert', type: 'class_method', path: 'String.html#try_convert' }
      ]
    )

    assert_equal 1, results.length
    assert_equal 'Array::try_convert', results[0]['full_name']
  end

  # Method query prefix matching against full_name
  def test_method_query_prefix_matching
    results = run_search(
      query: 'Array#fi',
      data: [
        { name: 'filter', full_name: 'Array#filter', type: 'instance_method', path: 'Array.html#filter' },
        { name: 'find', full_name: 'Array#find', type: 'instance_method', path: 'Array.html#find' },
        { name: 'first', full_name: 'Array#first', type: 'instance_method', path: 'Array.html#first' },
        { name: 'filter', full_name: 'Hash#filter', type: 'instance_method', path: 'Hash.html#filter' }
      ]
    )

    assert_equal 3, results.length
    full_names = results.map { |r| r['full_name'] }
    assert_includes full_names, 'Array#filter'
    assert_includes full_names, 'Array#find'
    assert_includes full_names, 'Array#first'
    refute_includes full_names, 'Hash#filter'
  end

  # Method query substring matching against full_name
  def test_method_query_substring_matching
    results = run_search(
      query: '#filter',
      data: [
        { name: 'filter', full_name: 'Array#filter', type: 'instance_method', path: 'Array.html#filter' },
        { name: 'filter', full_name: 'Hash#filter', type: 'instance_method', path: 'Hash.html#filter' },
        { name: 'filter_map', full_name: 'Array#filter_map', type: 'instance_method', path: 'Array.html#filter_map' }
      ]
    )

    assert_equal 3, results.length
    # All entries contain #filter in their full_name
    results.each do |r|
      assert_match(/#filter/, r['full_name'])
    end
  end

  # Special characters
  def test_special_characters_searchable
    results = run_search(
      query: '<<',
      data: [
        { name: '<<', full_name: 'Array#<<', type: 'instance_method', path: 'Array.html#<<' },
        { name: 'Array', full_name: 'Array', type: 'class', path: 'Array.html' }
      ]
    )

    assert_equal 1, results.length
    assert_equal '<<', results[0]['name']
  end

  def test_bracket_method_searchable
    results = run_search(
      query: '[]',
      data: [
        { name: '[]', full_name: 'Hash#[]', type: 'instance_method', path: 'Hash.html#[]' },
        { name: 'Hash', full_name: 'Hash', type: 'class', path: 'Hash.html' }
      ]
    )

    assert_equal 1, results.length
    assert_equal '[]', results[0]['name']
  end

  # Result limit
  def test_result_limit_30
    data = 50.times.map do |i|
      { name: "Test#{i}", full_name: "Test#{i}", type: 'class', path: "Test#{i}.html" }
    end

    results = run_search(query: 'Test', data: data)

    assert_equal 30, results.length
  end

  # Empty query
  def test_empty_query_returns_empty
    results = run_search(
      query: '',
      data: [
        { name: 'Hash', full_name: 'Hash', type: 'class', path: 'Hash.html' }
      ]
    )

    assert_equal [], results
  end

  # No matches
  def test_no_matches_returns_empty
    results = run_search(
      query: 'xyz',
      data: [
        { name: 'Hash', full_name: 'Hash', type: 'class', path: 'Hash.html' },
        { name: 'Array', full_name: 'Array', type: 'class', path: 'Array.html' }
      ]
    )

    assert_equal [], results
  end

  # Case insensitive matching
  def test_case_insensitive_matching
    results = run_search(
      query: 'HASH',
      data: [
        { name: 'Hash', full_name: 'Hash', type: 'class', path: 'Hash.html' }
      ]
    )

    assert_equal 1, results.length
    assert_equal 'Hash', results[0]['name']
  end

  # Constant search
  def test_constant_search
    results = run_search(
      query: 'VER',
      data: [
        { name: 'VERSION', full_name: 'RDoc::VERSION', type: 'constant', path: 'RDoc.html' },
        { name: 'Verifier', full_name: 'Verifier', type: 'class', path: 'Verifier.html' }
      ]
    )

    assert_equal 2, results.length
    # Verifier is unqualified (name == full_name), VERSION is qualified (RDoc::VERSION)
    # Unqualified wins over qualified, then shorter wins within same qualification
    assert_equal 'Verifier', results[0]['name']
    assert_equal 'VERSION', results[1]['name']
  end

  # Exact name match should win over prefix match
  def test_exact_name_match_beats_prefix_match
    results = run_search(
      query: 'RDoc',
      data: [
        { name: 'rdoc_version', full_name: 'RDoc::RubygemsHook#rdoc_version', type: 'instance_method', path: 'RDoc/RubygemsHook.html#rdoc_version' },
        { name: 'RDoc', full_name: 'RDoc', type: 'module', path: 'RDoc.html' },
        { name: 'RDoc', full_name: 'RDoc::RDoc', type: 'class', path: 'RDoc/RDoc.html' }
      ]
    )

    assert_equal 3, results.length
    # Exact name matches should come first
    assert_equal 'RDoc', results[0]['full_name'], "Expected top-level RDoc module first"
    assert_equal 'RDoc::RDoc', results[1]['full_name'], "Expected RDoc::RDoc class second"
    assert_equal 'RDoc::RubygemsHook#rdoc_version', results[2]['full_name'], "Expected rdoc_version method last"
  end

  # Hash class should rank higher than #hash methods when searching "Hash"
  # This replicates the bug where methods appear before the class
  def test_hash_class_ranks_higher_than_hash_methods
    results = run_search(
      query: 'Hash',
      data: [
        { name: 'hash', full_name: 'Gem::Resolver::IndexSpecification#hash', type: 'instance_method', path: 'Gem/Resolver/IndexSpecification.html#hash' },
        { name: 'hash', full_name: 'URI::Generic#hash', type: 'instance_method', path: 'URI/Generic.html#hash' },
        { name: 'hash', full_name: 'Struct#hash', type: 'instance_method', path: 'Struct.html#hash' },
        { name: 'hash', full_name: 'Regexp#hash', type: 'instance_method', path: 'Regexp.html#hash' },
        { name: 'hash', full_name: 'Object#hash', type: 'instance_method', path: 'Object.html#hash' },
        { name: 'hash', full_name: 'Time#hash', type: 'instance_method', path: 'Time.html#hash' },
        { name: 'Hash', full_name: 'Hash', type: 'class', path: 'Hash.html' },
        { name: 'Hash', full_name: 'Gem::SafeMarshal::Elements::Hash', type: 'class', path: 'Gem/SafeMarshal/Elements/Hash.html' }
      ]
    )

    assert_equal 8, results.length
    # Hash class should come first (uppercase query + exact name match + unqualified)
    assert_equal 'Hash', results[0]['full_name'], "Expected Hash class first"
    # Nested Hash class second (uppercase query + exact name match, but qualified)
    assert_equal 'Gem::SafeMarshal::Elements::Hash', results[1]['full_name'], "Expected nested Hash class second"
    # Methods should come after classes
    assert_equal 'instance_method', results[2]['type'], "Expected methods after classes"
  end

  # Combined priority test matching user's expectation
  # User query: "Ha"
  # Expected order: Hash, Hashable, HashWithIndifferentAccess, Foo::Hash, #hash
  def test_combined_priority_matching_user_expectation
    results = run_search(
      query: 'Ha',
      data: [
        { name: 'hash', full_name: 'Object#hash', type: 'instance_method', path: 'Object.html#hash' },
        { name: 'HashWithIndifferentAccess', full_name: 'HashWithIndifferentAccess', type: 'class', path: 'HashWithIndifferentAccess.html' },
        { name: 'Hashable', full_name: 'Hashable', type: 'module', path: 'Hashable.html' },
        { name: 'Hash', full_name: 'Foo::Hash', type: 'class', path: 'Foo/Hash.html' },
        { name: 'Hash', full_name: 'Hash', type: 'class', path: 'Hash.html' }
      ]
    )

    assert_equal 5, results.length
    # Order: class/module first, unqualified before qualified, shorter before longer, methods last
    assert_equal 'Hash', results[0]['full_name'], "Expected top-level Hash first"
    assert_equal 'Hashable', results[1]['full_name'], "Expected Hashable second (shorter unqualified)"
    assert_equal 'HashWithIndifferentAccess', results[2]['full_name'], "Expected HashWithIndifferentAccess third"
    assert_equal 'Foo::Hash', results[3]['full_name'], "Expected Foo::Hash fourth (qualified)"
    assert_equal 'Object#hash', results[4]['full_name'], "Expected method last"
  end

  private

  def run_search(query:, data:)
    @context.eval("search(#{query.to_json}, #{data.to_json})")
  end
end

# Integration test that goes through SearchController to catch bugs like
# the query being lowercased before reaching the ranker
class RDocGeneratorAlikiSearchControllerTest < Test::Unit::TestCase
  def setup
    @context = MiniRacer::Context.new

    # Mock DOM elements and document BEFORE loading JS files
    @context.eval(<<~JS)
      var document = {
        addEventListener: function() {}
      };
      var mockInput = {
        value: '',
        addEventListener: function() {},
        setAttribute: function() {},
        select: function() {}
      };
      var mockResult = {
        innerHTML: '',
        parentNode: { scrollTop: 0, offsetHeight: 100 },
        childElementCount: 0,
        firstChild: null,
        setAttribute: function() {},
        appendChild: function(item) {
          this.childElementCount++;
          if (!this.firstChild) this.firstChild = item;
        }
      };
    JS

    # Load all search-related JS files in order
    js_dir = File.expand_path('../../../../lib/rdoc/generator/template/aliki/js', __dir__)

    @context.eval(File.read(File.join(js_dir, 'search_navigation.js')))
    @context.eval(File.read(File.join(js_dir, 'search_ranker.js')))
    @context.eval(File.read(File.join(js_dir, 'search_controller.js')))
  end

  def teardown
    @context.dispose
  end

  # This test catches the bug where SearchController.search() was lowercasing
  # the query before passing it to the ranker, breaking case-based type priority
  def test_uppercase_query_preserves_case_for_type_priority
    results = run_search_through_controller(
      query: 'Hash',
      data: [
        { name: 'hash', full_name: 'Object#hash', type: 'instance_method', path: 'Object.html#hash' },
        { name: 'Hash', full_name: 'Hash', type: 'class', path: 'Hash.html' }
      ]
    )

    assert_equal 2, results.length
    # With uppercase "Hash" query, class should come first due to type priority
    assert_equal 'Hash', results[0]['full_name'], "Expected Hash class first with uppercase query"
    assert_equal 'Object#hash', results[1]['full_name'], "Expected hash method second"
  end

  def test_lowercase_query_prioritizes_methods
    results = run_search_through_controller(
      query: 'hash',
      data: [
        { name: 'Hash', full_name: 'Hash', type: 'class', path: 'Hash.html' },
        { name: 'hash', full_name: 'Object#hash', type: 'instance_method', path: 'Object.html#hash' }
      ]
    )

    assert_equal 2, results.length
    # With lowercase "hash" query, method should come first due to type priority
    assert_equal 'Object#hash', results[0]['full_name'], "Expected hash method first with lowercase query"
    assert_equal 'Hash', results[1]['full_name'], "Expected Hash class second"
  end

  private

  def run_search_through_controller(query:, data:)
    # Set up search data
    @context.eval("var search_data = { index: #{data.to_json} };")

    # Create SearchController and intercept ranker to capture raw results
    @context.eval(<<~JS)
      var capturedRawResults = [];
      var controller = new SearchController(search_data, mockInput, mockResult);

      // Override ranker.find to capture raw results before formatting
      var originalFind = controller.ranker.find.bind(controller.ranker);
      controller.ranker.find = function(query) {
        var rawResults = search(query, this.index);
        capturedRawResults = rawResults;
        // Call original to continue normal flow
        originalFind(query);
      };

      controller.renderItem = function(result) {
        return { classList: { add: function() {} }, setAttribute: function() {} };
      };
    JS

    # Simulate search
    @context.eval("controller.search(#{query.to_json})")

    # Return captured raw results (entries with full_name, type, etc.)
    @context.eval("capturedRawResults")
  end
end
