'use strict';

const { test } = require('node:test');
const { assert, loadScripts } = require('../helper');

function stripHighlights(str) {
  return str.replace(/[\u0001\u0002]/g, '');
}

// The data sets here are small enough that Searcher#find delivers every
// result before it returns, so the test needs no timers.
function runSearch({ query, data }) {
  const context = loadScripts(['json_index/js/searcher.js']);
  const searcher = new context.Searcher(data);
  let results = [];
  searcher.ready((res) => {
    results = results.concat(res);
  });
  searcher.find(query);
  return results;
}

test('exact match prioritized', () => {
  const results = runSearch({
    query: 'string',
    data: {
      searchIndex: ['string', 'string', 'strings'],
      longSearchIndex: ['gem::safemarshal::elements::string', 'string', 'strings'],
      info: [
        ['String', 'Gem::SafeMarshal::Elements', 'Gem/SafeMarshal/Elements/String.html', '', 'Nested String class', '', 'class'],
        ['String', '', 'String.html', '', 'Top-level String class', '', 'class'],
        ['Strings', '', 'Strings.html', '', 'Strings class', '', 'class'],
      ],
    },
  });

  assert.equal(results.length, 3);
  // Top-level String should come first despite being second in the array
  assert.equal(stripHighlights(results[0].title), 'String');
  assert.equal(results[0].namespace, '', 'Top-level String should be prioritized over nested String');
  assert.equal(results[0].path, 'String.html');

  // Nested String should come second
  assert.equal(stripHighlights(results[1].title), 'String');
  assert.equal(stripHighlights(results[1].namespace), 'Gem::SafeMarshal::Elements');
});

test('exact method match', () => {
  const results = runSearch({
    query: 'attribute',
    data: {
      searchIndex: ['attributemanager', 'attributes', 'attribute()'],
      longSearchIndex: ['rdoc::markup::attributemanager', 'rdoc::markup::attributes', 'rdoc::markup::attributemanager#attribute()'],
      info: [
        ['AttributeManager', 'RDoc::Markup', 'RDoc/Markup/AttributeManager.html', '', 'AttributeManager class', '', 'class'],
        ['Attributes', 'RDoc::Markup', 'RDoc/Markup/Attributes.html', '', 'Attributes class', '', 'class'],
        ['attribute', 'RDoc::Markup::AttributeManager', 'RDoc/Markup/AttributeManager.html#method-i-attribute', '()', 'Attribute method', '', 'method'],
      ],
    },
  });

  assert.equal(results.length, 3);
  // attribute() method should come first despite being last in the array
  assert.equal(stripHighlights(results[0].title), 'attribute');
  assert.equal(stripHighlights(results[0].namespace), 'RDoc::Markup::AttributeManager');
});

test('capitalized query prioritizes exact class', () => {
  const results = runSearch({
    query: 'String',
    data: {
      searchIndex: ['string', 'string()'],
      longSearchIndex: ['string', 'object#string()'],
      info: [
        ['String', '', 'String.html', '', 'String class', '', 'class'],
        ['string', 'Object', 'Object.html#method-i-string', '()', 'String method', '', 'method'],
      ],
    },
  });

  assert.equal(results.length, 2);
  // Capitalized query: exact class (Pass 0) beats exact method (Pass 1)
  assert.equal(stripHighlights(results[0].title), 'String');
  assert.equal(results[0].namespace, '');
  assert.equal(results[0].path, 'String.html');

  // Method comes second
  assert.equal(stripHighlights(results[1].title), 'string');
  assert.equal(stripHighlights(results[1].namespace), 'Object');
});

test('lowercase query prioritizes method', () => {
  const results = runSearch({
    query: 'options',
    data: {
      searchIndex: ['options', 'options()'],
      longSearchIndex: ['rdoc::options', 'rdoc::codeobject#options()'],
      info: [
        ['Options', 'RDoc', 'RDoc/Options.html', '', 'Options class', '', 'class'],
        ['options', 'RDoc::CodeObject', 'RDoc/CodeObject.html#method-i-options', '()', 'Options method', '', 'method'],
      ],
    },
  });

  assert.equal(results.length, 2);
  // Lowercase query should prioritize method over class
  assert.equal(stripHighlights(results[0].title), 'options');
  assert.equal(stripHighlights(results[0].namespace), 'RDoc::CodeObject');
  assert.equal(results[0].path, 'RDoc/CodeObject.html#method-i-options');

  // Class comes second
  assert.equal(stripHighlights(results[1].title), 'Options');
  assert.equal(stripHighlights(results[1].namespace), 'RDoc');
});

test('beginning match', () => {
  const results = runSearch({
    query: 'attr',
    data: {
      searchIndex: ['attribute()', 'attributemanager', 'generator'],
      longSearchIndex: ['rdoc::markup#attribute()', 'rdoc::markup::attributemanager', 'rdoc::generator'],
      info: [
        ['attribute', 'RDoc::Markup', 'RDoc/Markup.html#method-i-attribute', '()', 'Attribute method', '', 'method'],
        ['AttributeManager', 'RDoc::Markup', 'RDoc/Markup/AttributeManager.html', '', 'Manager class', '', 'class'],
        ['Generator', 'RDoc', 'RDoc/Generator.html', '', 'Generator class', '', 'class'],
      ],
    },
  });

  assert.equal(results.length, 2);
  assert.equal(stripHighlights(results[0].title), 'attribute');
  assert.equal(stripHighlights(results[1].title), 'AttributeManager');
});

test('long index match', () => {
  const results = runSearch({
    query: 'rdoc::markup',
    data: {
      searchIndex: ['attributes', 'parser'],
      longSearchIndex: ['rdoc::markup::attributes', 'rdoc::parser'],
      info: [
        ['Attributes', 'RDoc::Markup', 'RDoc/Markup/Attributes.html', '', 'Attributes class', '', 'class'],
        ['Parser', 'RDoc', 'RDoc/Parser.html', '', 'Parser class', '', 'class'],
      ],
    },
  });

  assert.equal(results.length, 1);
  assert.equal(stripHighlights(results[0].title), 'Attributes');
  assert.equal(stripHighlights(results[0].namespace), 'RDoc::Markup');
});

test('contains match', () => {
  const results = runSearch({
    query: 'manager',
    data: {
      searchIndex: ['attributemanager', 'parser'],
      longSearchIndex: ['rdoc::markup::attributemanager', 'rdoc::parser'],
      info: [
        ['AttributeManager', 'RDoc::Markup', 'RDoc/Markup/AttributeManager.html', '', 'Manager class', '', 'class'],
        ['Parser', 'RDoc', 'RDoc/Parser.html', '', 'Parser class', '', 'class'],
      ],
    },
  });

  assert.equal(results.length, 1);
  assert.equal(stripHighlights(results[0].title), 'AttributeManager');
});

test('regexp match', () => {
  const results = runSearch({
    query: 'atrbt',
    data: {
      searchIndex: ['attribute()', 'generator'],
      longSearchIndex: ['rdoc::markup#attribute()', 'rdoc::generator'],
      info: [
        ['attribute', 'RDoc::Markup', 'RDoc/Markup.html#method-i-attribute', '()', 'Attribute method', '', 'method'],
        ['Generator', 'RDoc', 'RDoc/Generator.html', '', 'Generator class', '', 'class'],
      ],
    },
  });

  assert.equal(results.length, 1);
  assert.equal(stripHighlights(results[0].title), 'attribute');
});

test('empty query', () => {
  const results = runSearch({
    query: '',
    data: {
      searchIndex: ['string'],
      longSearchIndex: ['string'],
      info: [['String', '', 'String.html', '', 'String class', '', 'class']],
    },
  });

  assert.equal(results.length, 0);
});

test('no matches', () => {
  const results = runSearch({
    query: 'nonexistent',
    data: {
      searchIndex: ['string', 'attribute()'],
      longSearchIndex: ['string', 'rdoc#attribute()'],
      info: [
        ['String', '', 'String.html', '', 'String class', '', 'class'],
        ['attribute', 'RDoc', 'RDoc.html#attribute', '()', 'Attribute method', '', 'method'],
      ],
    },
  });

  assert.equal(results.length, 0);
});

test('multiple exact matches', () => {
  const results = runSearch({
    query: 'test',
    data: {
      searchIndex: ['test', 'test', 'testing'],
      longSearchIndex: ['test', 'rdoc::test', 'testing'],
      info: [
        ['Test', '', 'Test.html', '', 'Top-level Test', '', 'class'],
        ['Test', 'RDoc', 'RDoc/Test.html', '', 'RDoc Test', '', 'class'],
        ['Testing', '', 'Testing.html', '', 'Testing class', '', 'class'],
      ],
    },
  });

  assert.equal(results.length, 3);
  // First result should be the exact match with both indexes matching
  assert.equal(stripHighlights(results[0].title), 'Test');
  assert.equal(results[0].namespace, '');
});

// Test case insensitive search
test('case insensitive', () => {
  const results = runSearch({
    query: 'STRING',
    data: {
      searchIndex: ['string'],
      longSearchIndex: ['string'],
      info: [['String', '', 'String.html', '', 'String class', '', 'class']],
    },
  });

  assert.equal(results.length, 1);
  assert.equal(stripHighlights(results[0].title), 'String');
});

test('multi word query', () => {
  const results = runSearch({
    query: 'rdoc markup',
    data: {
      searchIndex: ['attributemanager'],
      longSearchIndex: ['rdoc::markup::attributemanager'],
      info: [['AttributeManager', 'RDoc::Markup', 'RDoc/Markup/AttributeManager.html', '', 'Manager', '', 'class']],
    },
  });

  assert.equal(results.length, 1);
  assert.equal(results[0].title, 'AttributeManager');
});

test('highlighting', () => {
  const results = runSearch({
    query: 'string',
    data: {
      searchIndex: ['string'],
      longSearchIndex: ['string'],
      info: [['String', '', 'String.html', '', 'String class', '', 'class']],
    },
  });

  assert.equal(results.length, 1);
  // Check that highlighting markers (unicode \u0001 and \u0002) are present
  assert.match(results[0].title, /[\u0001\u0002]/);
});

test('max results limit', () => {
  // Create 150 entries (more than MAX_RESULTS = 100)
  const searchIndex = [];
  const longSearchIndex = [];
  const info = [];

  for (let i = 0; i < 150; i++) {
    searchIndex.push(`test${i}`);
    longSearchIndex.push(`test${i}`);
    info.push([`Test${i}`, '', `Test${i}.html`, '', `Test class ${i}`, '', 'class']);
  }

  const results = runSearch({
    query: 'test',
    data: {
      searchIndex: searchIndex,
      longSearchIndex: longSearchIndex,
      info: info,
    },
  });

  // Should return at most 100 results
  assert.ok(results.length <= 100);
});
