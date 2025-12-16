/**
 * Aliki Search Implementation
 *
 * Search algorithm with the following priorities:
 * 1. Exact full_name match always wins (for namespace/method queries)
 * 2. Exact name match gets high priority
 * 3. Match types:
 *    - Namespace queries (::) and method queries (# or .) match against full_name
 *    - Regular queries match against unqualified name
 *    - Prefix matches rank higher than substring matches
 * 4. First character determines type priority:
 *    - Starts with lowercase: methods first
 *    - Starts with uppercase: classes/modules/constants first
 * 5. Within same type priority:
 *    - Unqualified match > qualified match
 *    - Shorter name > longer name
 * 6. Class methods > instance methods
 * 7. Result limit: 30
 * 8. Minimum query length: 1 character
 */

var MAX_RESULTS = 30;
var MIN_QUERY_LENGTH = 1;

/**
 * Parse and normalize a search query
 * @param {string} query - The raw search query
 * @returns {Object} Parsed query with normalized form and flags
 */
function parseQuery(query) {
  // Lowercase for case-insensitive matching (so "hash" finds both Hash class and #hash methods)
  var normalized = query.toLowerCase();
  var isNamespaceQuery = query.includes('::');
  var isMethodQuery = query.includes('#') || query.includes('.');

  // Normalize . to :: (RDoc uses :: for class methods in full_name)
  if (query.includes('.')) {
    normalized = normalized.replace(/\./g, '::');
  }

  return {
    original: query,
    normalized: normalized,
    isNamespaceQuery: isNamespaceQuery,
    isMethodQuery: isMethodQuery,
    // Namespace and method queries match against full_name instead of name
    matchesFullName: isNamespaceQuery || isMethodQuery,
    // If query starts with lowercase, prioritize methods; otherwise prioritize classes/modules/constants
    prioritizeMethod: !/^[A-Z]/.test(query)
  };
}

/**
 * Main search function
 * @param {string} query - The search query
 * @param {Array} index - The search index to search in
 * @returns {Array} Array of matching entries, sorted by relevance
 */
function search(query, index) {
  if (!query || query.length < MIN_QUERY_LENGTH) {
    return [];
  }

  var q = parseQuery(query);
  var results = [];

  for (var i = 0; i < index.length; i++) {
    var entry = index[i];
    var score = computeScore(entry, q);

    if (score !== null) {
      results.push({ entry: entry, score: score });
    }
  }

  results.sort(function(a, b) {
    return b.score - a.score;
  });

  return results.slice(0, MAX_RESULTS).map(function(r) {
    return r.entry;
  });
}

/**
 * Compute the relevance score for an entry
 * @param {Object} entry - The search index entry
 * @param {Object} q - Parsed query from parseQuery()
 * @returns {number|null} Score or null if no match
 */
function computeScore(entry, q) {
  var name = entry.name;
  var fullName = entry.full_name;
  var type = entry.type;

  var nameLower = name.toLowerCase();
  var fullNameLower = fullName.toLowerCase();

  // Exact full_name match (e.g., "Array#filter" matches Array#filter)
  if (q.matchesFullName && fullNameLower === q.normalized) {
    return 1000000;
  }

  var matchScore = 0;

  if (q.matchesFullName) {
    // For namespace queries like "Foo::Bar" or method queries like "Array#filter",
    // match against full_name
    if (fullNameLower.startsWith(q.normalized)) {
      matchScore = 1000; // Prefix match on full_name
    } else if (fullNameLower.includes(q.normalized)) {
      matchScore = 100; // Substring match on full_name
    } else {
      return null;
    }
  } else {
    // For regular queries, match against unqualified name
    if (nameLower.startsWith(q.normalized)) {
      matchScore = 1000;
    } else if (nameLower.includes(q.normalized)) {
      matchScore = 100;
    } else {
      return null;
    }
  }

  var score = matchScore;
  var isMethod = (type === 'instance_method' || type === 'class_method');

  if (q.prioritizeMethod) {
    if (isMethod) score += 10000;
  } else {
    if (!isMethod) score += 10000;
  }

  // Class method > instance method
  if (type === 'class_method') {
    score += 500;
  }

  // Top-level (Hash) > namespaced (Foo::Hash)
  if (name === fullName) {
    score += 5000;
  }

  // Exact name match (e.g., "Hash" matches Hash over Hashable)
  if (nameLower === q.normalized) {
    score += 50000;
  }

  // Shorter name is better (subtract name length)
  score -= name.length;

  return score;
}

/**
 * SearchRanker class for compatibility with the Search UI
 * Provides ready() and find() interface
 */
function SearchRanker(index) {
  this.index = index;
  this.handlers = [];
}

SearchRanker.prototype.ready = function(fn) {
  this.handlers.push(fn);
};

SearchRanker.prototype.find = function(query) {
  var q = parseQuery(query);
  var rawResults = search(query, this.index);
  var results = rawResults.map(function(entry) {
    return formatResult(entry, q);
  });

  var _this = this;
  this.handlers.forEach(function(fn) {
    fn.call(_this, results, true);
  });
};

/**
 * Format a search result entry for display
 */
function formatResult(entry, q) {
  var result = {
    title: highlightMatch(entry.full_name, q),
    path: entry.path,
    type: entry.type
  };

  if (entry.snippet) {
    result.snippet = entry.snippet;
  }

  return result;
}

/**
 * Add highlight markers (\u0001 and \u0002) to matching portions of text
 * @param {string} text - The text to highlight
 * @param {Object} q - Parsed query from parseQuery()
 */
function highlightMatch(text, q) {
  if (!text || !q) return text;

  var textLower = text.toLowerCase();
  var queryLen = q.normalized.length;
  var result = '';
  var lastIndex = 0;
  var matchIndex = textLower.indexOf(q.normalized);

  while (matchIndex !== -1) {
    // Add text before match
    result += text.substring(lastIndex, matchIndex);
    // Add highlighted match
    result += '\u0001' + text.substring(matchIndex, matchIndex + queryLen) + '\u0002';
    lastIndex = matchIndex + queryLen;
    // Find next match
    matchIndex = textLower.indexOf(q.normalized, lastIndex);
  }

  // Add remaining text after last match
  result += text.substring(lastIndex);

  return result;
}
