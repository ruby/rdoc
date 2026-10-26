'use strict';

const { describe, test } = require('node:test');
const { assert, assertIncludes, refuteIncludes, loadScripts } = require('../helper');

function runSearch({ query, data }) {
  const context = loadScripts(['aliki/js/search_ranker.js']);
  // Copy the results out of the script context so deepEqual compares plain arrays.
  return structuredClone(context.search(query, data));
}

// Goes through SearchController to catch bugs like the query being
// lowercased before it reaches the ranker.
function runSearchThroughController({ query, data }) {
  const context = loadScripts(
    ['aliki/js/search_navigation.js', 'aliki/js/search_ranker.js', 'aliki/js/search_controller.js'],
    { document: { addEventListener() {} } }
  );
  const input = {
    value: '',
    addEventListener() {},
    setAttribute() {},
    select() {}
  };
  const result = {
    innerHTML: '',
    parentNode: { scrollTop: 0, offsetHeight: 100 },
    childElementCount: 0,
    firstChild: null,
    setAttribute() {},
    appendChild(item) {
      this.childElementCount++;
      if (!this.firstChild) this.firstChild = item;
    }
  };
  const controller = new context.SearchController({ index: data }, input, result);

  // Capture the ranked entries before SearchController formats them.
  let rawResults = [];
  const originalFind = controller.ranker.find.bind(controller.ranker);
  controller.ranker.find = function(q) {
    rawResults = context.search(q, this.index);
    originalFind(q);
  };
  controller.renderItem = () => ({ classList: { add() {} }, setAttribute() {} });

  controller.search(query);
  return rawResults;
}

describe('search', () => {
  // Minimum query length requirement (1 character)
  test('minimum query length works for single char', () => {
    const results = runSearch({
      query: 'H',
      data: [
        { name: 'Hash', full_name: 'Hash', type: 'class', path: 'Hash.html' },
        { name: 'Help', full_name: 'Help', type: 'class', path: 'Help.html' },
      ],
    });

    assert.equal(results.length, 2);
  });

  test('minimum query length works for two chars', () => {
    const results = runSearch({
      query: 'Ha',
      data: [
        { name: 'Hash', full_name: 'Hash', type: 'class', path: 'Hash.html' },
        { name: 'Help', full_name: 'Help', type: 'class', path: 'Help.html' },
      ],
    });

    assert.equal(results.length, 1);
    assert.equal(results[0].name, 'Hash');
  });

  // Prefix matching ranks higher than substring matching
  test('prefix match ranks higher than substring match', () => {
    const results = runSearch({
      query: 'Ha',
      data: [
        { name: 'Hash', full_name: 'Hash', type: 'class', path: 'Hash.html' },
        { name: 'Aha', full_name: 'Aha', type: 'class', path: 'Aha.html' },
      ],
    });

    assert.equal(results.length, 2);
    assert.equal(results[0].name, 'Hash', 'Prefix match should rank first');
    assert.equal(results[1].name, 'Aha', 'Substring match should rank second');
  });

  // Substring matching support
  test('substring match finds suffix matches', () => {
    const results = runSearch({
      query: 'ter',
      data: [
        { name: 'filter', full_name: 'Array#filter', type: 'instance_method', path: 'Array.html#filter' },
        { name: 'Hash', full_name: 'Hash', type: 'class', path: 'Hash.html' },
      ],
    });

    assert.equal(results.length, 1);
    assert.equal(results[0].name, 'filter');
  });

  // Fuzzy matching support (characters in order)
  test('fuzzy match finds non contiguous matches', () => {
    const results = runSearch({
      query: 'addalias',
      data: [
        { name: 'add_foo_alias', full_name: 'RDoc::Context#add_foo_alias', type: 'instance_method', path: 'x' },
        { name: 'add_alias', full_name: 'RDoc::Context#add_alias', type: 'instance_method', path: 'x' },
        { name: 'Hash', full_name: 'Hash', type: 'class', path: 'x' },
      ],
    });

    assert.equal(results.length, 2);
    // Both are fuzzy matches; shorter name wins
    assert.equal(results[0].name, 'add_alias');
    assert.equal(results[1].name, 'add_foo_alias');
  });

  // Case-based type priority: uppercase query prioritizes classes/modules
  test('uppercase query prioritizes class over method', () => {
    const results = runSearch({
      query: 'Hash',
      data: [
        { name: 'hash', full_name: 'Object#hash', type: 'instance_method', path: 'Object.html#hash' },
        { name: 'Hash', full_name: 'Hash', type: 'class', path: 'Hash.html' },
      ],
    });

    assert.equal(results.length, 2);
    assert.equal(results[0].name, 'Hash');
    assert.equal(results[0].type, 'class');
    assert.equal(results[1].name, 'hash');
  });

  // Case-based type priority: lowercase query prioritizes methods
  test('lowercase query prioritizes method over class', () => {
    const results = runSearch({
      query: 'hash',
      data: [
        { name: 'Hash', full_name: 'Hash', type: 'class', path: 'Hash.html' },
        { name: 'hash', full_name: 'Object#hash', type: 'instance_method', path: 'Object.html#hash' },
      ],
    });

    assert.equal(results.length, 2);
    assert.equal(results[0].name, 'hash');
    assert.equal(results[0].type, 'instance_method');
    assert.equal(results[1].name, 'Hash');
  });

  // Unqualified match > qualified match
  test('unqualified match prioritized over qualified', () => {
    const results = runSearch({
      query: 'Foo',
      data: [
        { name: 'Foo', full_name: 'Bar::Foo', type: 'class', path: 'Bar/Foo.html' },
        { name: 'Foo', full_name: 'Foo', type: 'class', path: 'Foo.html' },
      ],
    });

    assert.equal(results.length, 2);
    assert.equal(results[0].full_name, 'Foo');
    assert.equal(results[1].full_name, 'Bar::Foo');
  });

  // Shorter name > longer name
  test('shorter name prioritized', () => {
    const results = runSearch({
      query: 'Hash',
      data: [
        { name: 'Hashable', full_name: 'Hashable', type: 'module', path: 'Hashable.html' },
        { name: 'Hash', full_name: 'Hash', type: 'class', path: 'Hash.html' },
        { name: 'HashWithIndifferentAccess', full_name: 'HashWithIndifferentAccess', type: 'class', path: 'HashWithIndifferentAccess.html' },
      ],
    });

    assert.equal(results.length, 3);
    assert.equal(results[0].name, 'Hash');
    assert.equal(results[1].name, 'Hashable');
    assert.equal(results[2].name, 'HashWithIndifferentAccess');
  });

  // Class method > instance method
  test('class method prioritized over instance method', () => {
    const results = runSearch({
      query: 'hash',
      data: [
        { name: 'hash', full_name: 'Object#hash', type: 'instance_method', path: 'Object.html#hash' },
        { name: 'hash', full_name: 'Digest::Base::hash', type: 'class_method', path: 'Digest/Base.html#hash' },
      ],
    });

    assert.equal(results.length, 2);
    assert.equal(results[0].type, 'class_method');
    assert.equal(results[1].type, 'instance_method');
  });

  // Exact full match wins
  test('exact full name match wins', () => {
    const results = runSearch({
      query: 'Bar::Foo',
      data: [
        { name: 'Foo', full_name: 'Foo', type: 'class', path: 'Foo.html' },
        { name: 'Foo', full_name: 'Bar::Foo', type: 'class', path: 'Bar/Foo.html' },
        { name: 'Baz', full_name: 'Foo::Baz', type: 'class', path: 'Foo/Baz.html' },
      ],
    });

    assert.equal(results.length, 1);
    assert.equal(results[0].full_name, 'Bar::Foo');
  });

  // Namespace query matches within namespace
  test('namespace query matches namespace', () => {
    const results = runSearch({
      query: 'Foo::B',
      data: [
        { name: 'Bar', full_name: 'Bar', type: 'class', path: 'Bar.html' },
        { name: 'Bar', full_name: 'Foo::Bar', type: 'class', path: 'Foo/Bar.html' },
        { name: 'Baz', full_name: 'Foo::Baz', type: 'class', path: 'Foo/Baz.html' },
      ],
    });

    assert.equal(results.length, 2);
    const names = results.map((r) => r.full_name);
    assertIncludes(names, 'Foo::Bar');
    assertIncludes(names, 'Foo::Baz');
  });

  // Method query with # matches against full_name
  test('instance method query matches full name', () => {
    const results = runSearch({
      query: 'Array#filter',
      data: [
        { name: 'filter', full_name: 'Array#filter', type: 'instance_method', path: 'Array.html#filter' },
        { name: 'filter', full_name: 'Enumerable#filter', type: 'instance_method', path: 'Enumerable.html#filter' },
        { name: 'filter', full_name: 'Hash#filter', type: 'instance_method', path: 'Hash.html#filter' },
      ],
    });

    assert.equal(results.length, 1);
    assert.equal(results[0].full_name, 'Array#filter');
  });

  // Method query with . matches against full_name (class methods)
  // Note: RDoc uses :: for class methods in full_name, but users may type . (Ruby convention)
  // The search normalizes . to :: so "Array.try_convert" matches "Array::try_convert"
  test('class method query matches full name', () => {
    const results = runSearch({
      query: 'Array.try_convert',
      data: [
        { name: 'try_convert', full_name: 'Array::try_convert', type: 'class_method', path: 'Array.html#try_convert' },
        { name: 'try_convert', full_name: 'Hash::try_convert', type: 'class_method', path: 'Hash.html#try_convert' },
        { name: 'try_convert', full_name: 'String::try_convert', type: 'class_method', path: 'String.html#try_convert' },
      ],
    });

    assert.equal(results.length, 1);
    assert.equal(results[0].full_name, 'Array::try_convert');
  });

  // Method query prefix matching against full_name
  test('method query prefix matching', () => {
    const results = runSearch({
      query: 'Array#fi',
      data: [
        { name: 'filter', full_name: 'Array#filter', type: 'instance_method', path: 'Array.html#filter' },
        { name: 'find', full_name: 'Array#find', type: 'instance_method', path: 'Array.html#find' },
        { name: 'first', full_name: 'Array#first', type: 'instance_method', path: 'Array.html#first' },
        { name: 'filter', full_name: 'Hash#filter', type: 'instance_method', path: 'Hash.html#filter' },
      ],
    });

    assert.equal(results.length, 3);
    const fullNames = results.map((r) => r.full_name);
    assertIncludes(fullNames, 'Array#filter');
    assertIncludes(fullNames, 'Array#find');
    assertIncludes(fullNames, 'Array#first');
    refuteIncludes(fullNames, 'Hash#filter');
  });

  // Method query substring matching against full_name
  test('method query substring matching', () => {
    const results = runSearch({
      query: '#filter',
      data: [
        { name: 'filter', full_name: 'Array#filter', type: 'instance_method', path: 'Array.html#filter' },
        { name: 'filter', full_name: 'Hash#filter', type: 'instance_method', path: 'Hash.html#filter' },
        { name: 'filter_map', full_name: 'Array#filter_map', type: 'instance_method', path: 'Array.html#filter_map' },
      ],
    });

    assert.equal(results.length, 3);
    // All entries contain #filter in their full_name
    for (const r of results) {
      assert.match(r.full_name, /#filter/);
    }
  });

  // Special characters
  test('special characters searchable', () => {
    const results = runSearch({
      query: '<<',
      data: [
        { name: '<<', full_name: 'Array#<<', type: 'instance_method', path: 'Array.html#<<' },
        { name: 'Array', full_name: 'Array', type: 'class', path: 'Array.html' },
      ],
    });

    assert.equal(results.length, 1);
    assert.equal(results[0].name, '<<');
  });

  test('bracket method searchable', () => {
    const results = runSearch({
      query: '[]',
      data: [
        { name: '[]', full_name: 'Hash#[]', type: 'instance_method', path: 'Hash.html#[]' },
        { name: 'Hash', full_name: 'Hash', type: 'class', path: 'Hash.html' },
      ],
    });

    assert.equal(results.length, 1);
    assert.equal(results[0].name, '[]');
  });

  // Result limit
  test('result limit 30', () => {
    const data = Array.from({ length: 50 }, (_, i) => ({ name: `Test${i}`, full_name: `Test${i}`, type: 'class', path: `Test${i}.html` }));

    const results = runSearch({ query: 'Test', data: data });

    assert.equal(results.length, 30);
  });

  // Empty query
  test('empty query returns empty', () => {
    const results = runSearch({
      query: '',
      data: [
        { name: 'Hash', full_name: 'Hash', type: 'class', path: 'Hash.html' },
      ],
    });

    assert.deepEqual(results, []);
  });

  // No matches
  test('no matches returns empty', () => {
    const results = runSearch({
      query: 'xyz',
      data: [
        { name: 'Hash', full_name: 'Hash', type: 'class', path: 'Hash.html' },
        { name: 'Array', full_name: 'Array', type: 'class', path: 'Array.html' },
      ],
    });

    assert.deepEqual(results, []);
  });

  // Case insensitive matching
  test('case insensitive matching', () => {
    const results = runSearch({
      query: 'HASH',
      data: [
        { name: 'Hash', full_name: 'Hash', type: 'class', path: 'Hash.html' },
      ],
    });

    assert.equal(results.length, 1);
    assert.equal(results[0].name, 'Hash');
  });

  // Constant search
  test('constant search', () => {
    const results = runSearch({
      query: 'VER',
      data: [
        { name: 'VERSION', full_name: 'RDoc::VERSION', type: 'constant', path: 'RDoc.html' },
        { name: 'Verifier', full_name: 'Verifier', type: 'class', path: 'Verifier.html' },
      ],
    });

    assert.equal(results.length, 2);
    // Verifier is unqualified (name == full_name), VERSION is qualified (RDoc::VERSION)
    // Unqualified wins over qualified, then shorter wins within same qualification
    assert.equal(results[0].name, 'Verifier');
    assert.equal(results[1].name, 'VERSION');
  });

  // Exact name match should win over prefix match
  test('exact name match beats prefix match', () => {
    const results = runSearch({
      query: 'RDoc',
      data: [
        { name: 'rdoc_version', full_name: 'RDoc::RubygemsHook#rdoc_version', type: 'instance_method', path: 'RDoc/RubygemsHook.html#rdoc_version' },
        { name: 'RDoc', full_name: 'RDoc', type: 'module', path: 'RDoc.html' },
        { name: 'RDoc', full_name: 'RDoc::RDoc', type: 'class', path: 'RDoc/RDoc.html' },
      ],
    });

    assert.equal(results.length, 3);
    // Exact name matches should come first
    assert.equal(results[0].full_name, 'RDoc', 'Expected top-level RDoc module first');
    assert.equal(results[1].full_name, 'RDoc::RDoc', 'Expected RDoc::RDoc class second');
    assert.equal(results[2].full_name, 'RDoc::RubygemsHook#rdoc_version', 'Expected rdoc_version method last');
  });

  // Hash class should rank higher than #hash methods when searching "Hash"
  // This replicates the bug where methods appear before the class
  test('hash class ranks higher than hash methods', () => {
    const results = runSearch({
      query: 'Hash',
      data: [
        { name: 'hash', full_name: 'Gem::Resolver::IndexSpecification#hash', type: 'instance_method', path: 'Gem/Resolver/IndexSpecification.html#hash' },
        { name: 'hash', full_name: 'URI::Generic#hash', type: 'instance_method', path: 'URI/Generic.html#hash' },
        { name: 'hash', full_name: 'Struct#hash', type: 'instance_method', path: 'Struct.html#hash' },
        { name: 'hash', full_name: 'Regexp#hash', type: 'instance_method', path: 'Regexp.html#hash' },
        { name: 'hash', full_name: 'Object#hash', type: 'instance_method', path: 'Object.html#hash' },
        { name: 'hash', full_name: 'Time#hash', type: 'instance_method', path: 'Time.html#hash' },
        { name: 'Hash', full_name: 'Hash', type: 'class', path: 'Hash.html' },
        { name: 'Hash', full_name: 'Gem::SafeMarshal::Elements::Hash', type: 'class', path: 'Gem/SafeMarshal/Elements/Hash.html' },
      ],
    });

    assert.equal(results.length, 8);
    // Hash class should come first (uppercase query + exact name match + unqualified)
    assert.equal(results[0].full_name, 'Hash', 'Expected Hash class first');
    // Nested Hash class second (uppercase query + exact name match, but qualified)
    assert.equal(results[1].full_name, 'Gem::SafeMarshal::Elements::Hash', 'Expected nested Hash class second');
    // Methods should come after classes
    assert.equal(results[2].type, 'instance_method', 'Expected methods after classes');
  });

  // Combined priority test matching user's expectation
  // User query: "Ha"
  // Expected order: Hash, Hashable, HashWithIndifferentAccess, Foo::Hash, #hash
  test('combined priority matching user expectation', () => {
    const results = runSearch({
      query: 'Ha',
      data: [
        { name: 'hash', full_name: 'Object#hash', type: 'instance_method', path: 'Object.html#hash' },
        { name: 'HashWithIndifferentAccess', full_name: 'HashWithIndifferentAccess', type: 'class', path: 'HashWithIndifferentAccess.html' },
        { name: 'Hashable', full_name: 'Hashable', type: 'module', path: 'Hashable.html' },
        { name: 'Hash', full_name: 'Foo::Hash', type: 'class', path: 'Foo/Hash.html' },
        { name: 'Hash', full_name: 'Hash', type: 'class', path: 'Hash.html' },
      ],
    });

    assert.equal(results.length, 5);
    // Order: class/module first, unqualified before qualified, shorter before longer, methods last
    assert.equal(results[0].full_name, 'Hash', 'Expected top-level Hash first');
    assert.equal(results[1].full_name, 'Hashable', 'Expected Hashable second (shorter unqualified)');
    assert.equal(results[2].full_name, 'HashWithIndifferentAccess', 'Expected HashWithIndifferentAccess third');
    assert.equal(results[3].full_name, 'Foo::Hash', 'Expected Foo::Hash fourth (qualified)');
    assert.equal(results[4].full_name, 'Object#hash', 'Expected method last');
  });
});

describe('SearchController', () => {
  // This test catches the bug where SearchController.search() was lowercasing
  // the query before passing it to the ranker, breaking case-based type priority
  test('uppercase query preserves case for type priority', () => {
    const results = runSearchThroughController({
      query: 'Hash',
      data: [
        { name: 'hash', full_name: 'Object#hash', type: 'instance_method', path: 'Object.html#hash' },
        { name: 'Hash', full_name: 'Hash', type: 'class', path: 'Hash.html' },
      ],
    });

    assert.equal(results.length, 2);
    // With uppercase "Hash" query, class should come first due to type priority
    assert.equal(results[0].full_name, 'Hash', 'Expected Hash class first with uppercase query');
    assert.equal(results[1].full_name, 'Object#hash', 'Expected hash method second');
  });

  test('lowercase query prioritizes methods', () => {
    const results = runSearchThroughController({
      query: 'hash',
      data: [
        { name: 'Hash', full_name: 'Hash', type: 'class', path: 'Hash.html' },
        { name: 'hash', full_name: 'Object#hash', type: 'instance_method', path: 'Object.html#hash' },
      ],
    });

    assert.equal(results.length, 2);
    // With lowercase "hash" query, method should come first due to type priority
    assert.equal(results[0].full_name, 'Object#hash', 'Expected hash method first with lowercase query');
    assert.equal(results[1].full_name, 'Hash', 'Expected Hash class second');
  });
});
