Searcher = function(data) {
  this.data = data;
  this.handlers = [];
}

Searcher.prototype = new function() {
  // search is performed in chunks of 1000 for non-blocking user input
  var CHUNK_SIZE = 1000;
  // do not try to find more than 100 results
  var MAX_RESULTS = 100;
  var huid = 1;
  var suid = 1;
  var runs = 0;

  this.find = function(query) {
    var queries = splitQuery(query),
        regexps = buildRegexps(queries),
        highlighters = buildHilighters(queries),
        state = { from: 0, pass: 0, limit: MAX_RESULTS, n: suid++},
        _this = this;
    this.currentSuid = state.n;

    if (!query) return;

    var run = function() {
      // stop current search thread if new search started
      if (state.n != _this.currentSuid) return;

      var results = performSearch(_this.data, regexps, queries, highlighters, state),
          hasMore = (state.limit > 0 && state.pass < 3);

      triggerResults.call(_this, results, !hasMore);
      if (hasMore) {
        setTimeout(run, 2);
      }
      runs++;
    };
    runs = 0;

    // start search thread
    run();
  }

  /*  ----- Events ------  */
  this.ready = function(fn) {
    fn.huid = huid;
    this.handlers.push(fn);
  }

  /*  ----- Utilities ------  */
  function splitQuery(query) {
    return jQuery.grep(query.split(/(\s+|\(\)?)/), function(string) {
      return string.match(/\S/)
    });
  }

  function buildRegexps(queries) {
    return jQuery.map(queries, function(query) {
      return new RegExp(query.replace(/(.)/g, '([$1])([^$1]*?)'), 'i')
    });
  }

  function buildHilighters(queries) {
    return jQuery.map(queries, function(query) {
      return jQuery.map(query.split(''), function(l, i) {
        return '\u0001$' + (i*2+1) + '\u0002$' + (i*2+2)
      }).join('')
    });
  }

  // function longMatchRegexp(index, longIndex, regexps) {
  //     for (var i = regexps.length - 1; i >= 0; i--){
  //         if (!index.match(regexps[i]) && !longIndex.match(regexps[i])) return false;
  //     };
  //     return true;
  // }


  /*  ----- Mathchers ------  */
  function matchPass1(index, longIndex, queries, regexps) {
    if (index.indexOf(queries[0]) != 0) return false;
    for (var i=1, l = regexps.length; i < l; i++) {
      if (!index.match(regexps[i]) && !longIndex.match(regexps[i]))
        return false;
    };
    return true;
  }

  function matchPass2(index, longIndex, queries, regexps) {
    if (index.indexOf(queries[0]) == -1) return false;
    for (var i=1, l = regexps.length; i < l; i++) {
      if (!index.match(regexps[i]) && !longIndex.match(regexps[i]))
        return false;
    };
    return true;
  }

  function matchPassRegexp(index, longIndex, queries, regexps) {
    if (!index.match(regexps[0])) return false;
    for (var i=1, l = regexps.length; i < l; i++) {
      if (!index.match(regexps[i]) && !longIndex.match(regexps[i]))
        return false;
    };
    return true;
  }


  /*  ----- Highlighters ------  */
  function highlightRegexp(info, queries, regexps, highlighters) {
    var result = createResult(info);
    for (var i=0, l = regexps.length; i < l; i++) {
      result.title = result.title.replace(regexps[i], highlighters[i]);
      if (i > 0)
        result.namespace = result.namespace.replace(regexps[i], highlighters[i]);
    };
    return result;
  }

  function hltSubstring(string, pos, length) {
    return string.substring(0, pos) + '\u0001' + string.substring(pos, pos + length) + '\u0002' + string.substring(pos + length);
  }

  function highlightQuery(info, queries, regexps, highlighters) {
    var result = createResult(info), pos = 0, lcTitle = result.title.toLowerCase();
    pos = lcTitle.indexOf(queries[0]);
    if (pos != -1) {
      result.title = hltSubstring(result.title, pos, queries[0].length);
    }
    for (var i=1, l = regexps.length; i < l; i++) {
      result.title = result.title.replace(regexps[i], highlighters[i]);
      result.namespace = result.namespace.replace(regexps[i], highlighters[i]);
    };
    return result;
  }

  function createResult(info) {
    var result = {};
    result.title = info[0];
    result.namespace = info[1];
    result.path = info[2];
    result.params = info[3];
    result.snippet = info[4];
    return result;
  }

  /*  ----- Searching ------  */
  function performSearch(data, regexps, queries, highlighters, state) {
    var searchIndex = data.searchIndex, // search by title first and then by source
        longSearchIndex = data.longSearchIndex,
        info = data.info,
        result = [],
        i = state.from,
        l = searchIndex.length,
        togo = CHUNK_SIZE,
        matchFunc, hltFunc;

    while (state.pass < 3 && state.limit > 0 && togo > 0) {
      if (state.pass == 0) {
        matchFunc = matchPass1;
        hltFunc = highlightQuery;
      } else if (state.pass == 1) {
        matchFunc = matchPass2;
        hltFunc = highlightQuery;
      } else if (state.pass == 2) {
        matchFunc = matchPassRegexp;
        hltFunc = highlightRegexp;
      }

      for (; togo > 0 && i < l && state.limit > 0; i++, togo--) {
        if (info[i].n == state.n) continue;
        if (matchFunc(searchIndex[i], longSearchIndex[i], queries, regexps)) {
          info[i].n = state.n;
          result.push(hltFunc(info[i], queries, regexps, highlighters));
          state.limit--;
        }
      };
      if (searchIndex.length <= i) {
        state.pass++;
        i = state.from = 0;
      } else {
        state.from = i;
      }
    }
    return result;
  }

  function triggerResults(results, isLast) {
    jQuery.each(this.handlers, function(i, fn) {
      fn.call(this, results, isLast)
    })
  }
}

