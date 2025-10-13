# frozen_string_literal: true

require_relative 'helper'

return if RUBY_DESCRIPTION =~ /truffleruby/ || RUBY_DESCRIPTION =~ /jruby/

begin
  require 'mini_racer'
rescue LoadError
  return
end

# This test is a simpler setup for testing the searcher.js file without pulling all the JS dependencies.
# If there are more JS functionalities to test in the future, we can move to use JS test frameworks.
class RDocGeneratorJsonIndexSearcherTest < Test::Unit::TestCase
  def setup
    @context = MiniRacer::Context.new

    # Add RegExp.escape polyfill to avoid `RegExp.escape is not a function` error
    @context.eval(<<~JS)
      RegExp.escape = function(string) {
        return string.replace(/[.*+?^${}()|[\\]\\\\]/g, '\\\\$&');
      };
    JS

    searcher_js_path = File.expand_path(
      '../../lib/rdoc/generator/template/json_index/js/searcher.js',
      __dir__
    )
    searcher_js = File.read(searcher_js_path)
    @context.eval(searcher_js)
  end

  def teardown
    @context.dispose
  end

  def test_exact_match_prioritized
    results = run_search(
      query: 'string',
      data: {
        searchIndex: ['string', 'string', 'strings'],
        longSearchIndex: ['gem::safemarshal::elements::string', 'string', 'strings'],
        info: [
          ['String', 'Gem::SafeMarshal::Elements', 'Gem/SafeMarshal/Elements/String.html', '', 'Nested String class', '', 'class'],
          ['String', '', 'String.html', '', 'Top-level String class', '', 'class'],
          ['Strings', '', 'Strings.html', '', 'Strings class', '', 'class']
        ]
      }
    )

    assert_equal 3, results.length
    # Top-level String should come first despite being second in the array
    assert_equal 'String', strip_highlights(results[0]['title'])
    assert_equal '', results[0]['namespace'], 'Top-level String should be prioritized over nested String'
    assert_equal 'String.html', results[0]['path']

    # Nested String should come second
    assert_equal 'String', strip_highlights(results[1]['title'])
    assert_equal 'Gem::SafeMarshal::Elements', strip_highlights(results[1]['namespace'])
  end

  def test_exact_method_match
    results = run_search(
      query: 'attribute',
      data: {
        searchIndex: ['attributemanager', 'attributes', 'attribute()'],
        longSearchIndex: ['rdoc::markup::attributemanager', 'rdoc::markup::attributes', 'rdoc::markup::attributemanager#attribute()'],
        info: [
          ['AttributeManager', 'RDoc::Markup', 'RDoc/Markup/AttributeManager.html', '', 'AttributeManager class', '', 'class'],
          ['Attributes', 'RDoc::Markup', 'RDoc/Markup/Attributes.html', '', 'Attributes class', '', 'class'],
          ['attribute', 'RDoc::Markup::AttributeManager', 'RDoc/Markup/AttributeManager.html#method-i-attribute', '()', 'Attribute method', '', 'method']
        ]
      }
    )

    assert_equal 3, results.length
    # attribute() method should come first despite being last in the array
    assert_equal 'attribute', strip_highlights(results[0]['title'])
    assert_equal 'RDoc::Markup::AttributeManager', strip_highlights(results[0]['namespace'])
  end

  def test_exact_class_beats_exact_method
    results = run_search(
      query: 'attribute',
      data: {
        searchIndex: ['attribute()', 'attribute'],
        longSearchIndex: ['rdoc::markup#attribute()', 'attribute'],
        info: [
          ['attribute', 'RDoc::Markup', 'RDoc/Markup.html#method-i-attribute', '()', 'Attribute method', '', 'method'],
          ['Attribute', '', 'Attribute.html', '', 'Attribute class (hypothetical)', '', 'class']
        ]
      }
    )

    assert_equal 2, results.length
    # Exact class match (Pass 0) should beat exact method match (Pass 1)
    assert_equal 'Attribute', strip_highlights(results[0]['title'])
    assert_equal '', results[0]['namespace']
    assert_equal 'Attribute.html', results[0]['path']

    # Method comes second
    assert_equal 'attribute', strip_highlights(results[1]['title'])
    assert_equal 'RDoc::Markup', strip_highlights(results[1]['namespace'])
  end

  def test_beginning_match
    results = run_search(
      query: 'attr',
      data: {
        searchIndex: ['attribute()', 'attributemanager', 'generator'],
        longSearchIndex: ['rdoc::markup#attribute()', 'rdoc::markup::attributemanager', 'rdoc::generator'],
        info: [
          ['attribute', 'RDoc::Markup', 'RDoc/Markup.html#method-i-attribute', '()', 'Attribute method', '', 'method'],
          ['AttributeManager', 'RDoc::Markup', 'RDoc/Markup/AttributeManager.html', '', 'Manager class', '', 'class'],
          ['Generator', 'RDoc', 'RDoc/Generator.html', '', 'Generator class', '', 'class']
        ]
      }
    )

    assert_equal 2, results.length
    assert_equal 'attribute', strip_highlights(results[0]['title'])
    assert_equal 'AttributeManager', strip_highlights(results[1]['title'])
  end

  def test_long_index_match
    results = run_search(
      query: 'rdoc::markup',
      data: {
        searchIndex: ['attributes', 'parser'],
        longSearchIndex: ['rdoc::markup::attributes', 'rdoc::parser'],
        info: [
          ['Attributes', 'RDoc::Markup', 'RDoc/Markup/Attributes.html', '', 'Attributes class', '', 'class'],
          ['Parser', 'RDoc', 'RDoc/Parser.html', '', 'Parser class', '', 'class']
        ]
      }
    )

    assert_equal 1, results.length
    assert_equal 'Attributes', strip_highlights(results[0]['title'])
    assert_equal 'RDoc::Markup', strip_highlights(results[0]['namespace'])
  end

  def test_contains_match
    results = run_search(
      query: 'manager',
      data: {
        searchIndex: ['attributemanager', 'parser'],
        longSearchIndex: ['rdoc::markup::attributemanager', 'rdoc::parser'],
        info: [
          ['AttributeManager', 'RDoc::Markup', 'RDoc/Markup/AttributeManager.html', '', 'Manager class', '', 'class'],
          ['Parser', 'RDoc', 'RDoc/Parser.html', '', 'Parser class', '', 'class']
        ]
      }
    )

    assert_equal 1, results.length
    assert_equal 'AttributeManager', strip_highlights(results[0]['title'])
  end

  def test_regexp_match
    results = run_search(
      query: 'atrbt',
      data: {
        searchIndex: ['attribute()', 'generator'],
        longSearchIndex: ['rdoc::markup#attribute()', 'rdoc::generator'],
        info: [
          ['attribute', 'RDoc::Markup', 'RDoc/Markup.html#method-i-attribute', '()', 'Attribute method', '', 'method'],
          ['Generator', 'RDoc', 'RDoc/Generator.html', '', 'Generator class', '', 'class']
        ]
      }
    )

    assert_equal 1, results.length
    assert_equal 'attribute', strip_highlights(results[0]['title'])
  end

  def test_empty_query
    results = run_search(
      query: '',
      data: {
        searchIndex: ['string'],
        longSearchIndex: ['string'],
        info: [['String', '', 'String.html', '', 'String class', '', 'class']]
      }
    )

    assert_equal 0, results.length
  end

  def test_no_matches
    results = run_search(
      query: 'nonexistent',
      data: {
        searchIndex: ['string', 'attribute()'],
        longSearchIndex: ['string', 'rdoc#attribute()'],
        info: [
          ['String', '', 'String.html', '', 'String class', '', 'class'],
          ['attribute', 'RDoc', 'RDoc.html#attribute', '()', 'Attribute method', '', 'method']
        ]
      }
    )

    assert_equal 0, results.length
  end

  def test_multiple_exact_matches
    results = run_search(
      query: 'test',
      data: {
        searchIndex: ['test', 'test', 'testing'],
        longSearchIndex: ['test', 'rdoc::test', 'testing'],
        info: [
          ['Test', '', 'Test.html', '', 'Top-level Test', '', 'class'],
          ['Test', 'RDoc', 'RDoc/Test.html', '', 'RDoc Test', '', 'class'],
          ['Testing', '', 'Testing.html', '', 'Testing class', '', 'class']
        ]
      }
    )

    assert_equal 3, results.length
    # First result should be the exact match with both indexes matching
    assert_equal 'Test', strip_highlights(results[0]['title'])
    assert_equal '', results[0]['namespace']
  end

  # Test case insensitive search
  def test_case_insensitive
    results = run_search(
      query: 'STRING',
      data: {
        searchIndex: ['string'],
        longSearchIndex: ['string'],
        info: [['String', '', 'String.html', '', 'String class', '', 'class']]
      }
    )

    assert_equal 1, results.length
    assert_equal 'String', strip_highlights(results[0]['title'])
  end

  def test_multi_word_query
    results = run_search(
      query: 'rdoc markup',
      data: {
        searchIndex: ['attributemanager'],
        longSearchIndex: ['rdoc::markup::attributemanager'],
        info: [['AttributeManager', 'RDoc::Markup', 'RDoc/Markup/AttributeManager.html', '', 'Manager', '', 'class']]
      }
    )

    assert_equal 1, results.length
    assert_equal 'AttributeManager', results[0]['title']
  end

  def test_highlighting
    results = run_search(
      query: 'string',
      data: {
        searchIndex: ['string'],
        longSearchIndex: ['string'],
        info: [['String', '', 'String.html', '', 'String class', '', 'class']]
      }
    )

    assert_equal 1, results.length
    # Check that highlighting markers (unicode \u0001 and \u0002) are present
    assert_match(/[\u0001\u0002]/, results[0]['title'])
  end

  def test_max_results_limit
    # Create 150 entries (more than MAX_RESULTS = 100)
    search_index = []
    long_search_index = []
    info = []

    150.times do |i|
      search_index << "test#{i}"
      long_search_index << "test#{i}"
      info << ["Test#{i}", '', "Test#{i}.html", '', "Test class #{i}", '', 'class']
    end

    results = run_search(
      query: 'test',
      data: {
        searchIndex: search_index,
        longSearchIndex: long_search_index,
        info: info
      }
    )

    # Should return at most 100 results
    assert_operator results.length, :<=, 100
  end

  private

  def run_search(query:, data:)
    @context.eval("var testResults = [];")
    @context.eval(<<~JS)
      var data = #{data.to_json};
      var searcher = new Searcher(data);
      searcher.ready(function(res, isLast) {
        testResults = testResults.concat(res);
      });
      searcher.find(#{query.to_json});
    JS

    # Give some time for async operations
    sleep 0.01

    @context.eval('testResults')
  end

  # Helper to strip highlighting markers from a string
  def strip_highlights(str)
    str.gsub(/[\u0001\u0002]/, '')
  end
end
