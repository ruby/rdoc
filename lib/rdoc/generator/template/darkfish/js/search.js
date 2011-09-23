Search = function(data, input, result) {
  this.data = data;
  this.$input = $(input);
  this.$result = $(result);

  this.$current = null;
  this.$view = this.$result.parent();
  this.searcher = new Searcher(data.index);
  this.init();
}

Search.prototype = new function() {
  var suid = 1;

  this.init = function() {
    var _this = this;
    var observer = function() {
      _this.search(_this.$input[0].value);
    };
    this.$input.keyup(observer);
    this.$input.click(observer); // mac's clear field

    this.searcher.ready(function(results, isLast) {
      _this.addResults(results, isLast);
    })
  }

  this.search = function(value, selectFirstMatch) {
    value = jQuery.trim(value).toLowerCase();
    if (value == '') {
      this.lastQuery = value;
      this.$result.empty();
    } else if (value != this.lastQuery) {
      this.lastQuery = value;
      this.firstRun = true;
      this.searcher.find(value);
    }
  }

  this.addResults = function(results, isLast) {
    var target = this.$result.get(0);
    if (this.firstRun && (results.length > 0 || isLast)) {
      this.$current = null;
      this.$result.empty();
    }

    for (var i=0, l = results.length; i < l; i++) {
      target.appendChild(renderItem.call(this, results[i]));
    };

    if (this.firstRun && results.length > 0) {
      this.firstRun = false;
      this.$current = $(target.firstChild);
      this.$current.addClass('current');
      if (this.selectFirstMatch) this.select();
      scrollIntoView(this.$current[0], this.$view[0])
    }
  }

  function renderItem(result) {
    var li = document.createElement('li');
    var html = '';

    // TODO add relative path to <script> per-page
    html += '<p class="search-match"><a href="' + rdoc_rel_prefix + result.path + '">' + hlt(result.title);
    if (result.params)
      html += '<span class="params">' + result.params + '</span>';

    html += '</a>';
    html += '<p class="search-namespace">' + hlt(result.namespace);

    if (result.snippet)
      html += '<div class="search-snippet">' + result.snippet + '</div>';

    li.innerHTML = html;

    return li;
  }

  function hlt(html) {
    return escapeHTML(html).replace(/\u0001/g, '<em>').replace(/\u0002/g, '</em>')
  }

  function escapeHTML(html) {
    return html.replace(/[&<>]/g, function(c) {
      return '&#' + c.charCodeAt(0) + ';';
    });
  }

}
