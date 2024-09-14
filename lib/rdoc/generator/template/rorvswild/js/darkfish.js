/**
 *
 * Darkfish Page Functions
 * $Id: darkfish.js 53 2009-01-07 02:52:03Z deveiant $
 *
 * Author: Michael Granger <mgranger@laika.com>
 *
 */

/* Provide console simulation for firebug-less environments */
/*
if (!("console" in window) || !("firebug" in console)) {
  var names = ["log", "debug", "info", "warn", "error", "assert", "dir", "dirxml",
    "group", "groupEnd", "time", "timeEnd", "count", "trace", "profile", "profileEnd"];

  window.console = {};
  for (var i = 0; i < names.length; ++i)
    window.console[names[i]] = function() {};
};
*/


function showSource( e ) {
  var target = e.target;
  while (!target.classList.contains('method-detail')) {
    target = target.parentNode;
  }
  if (typeof target !== "undefined" && target !== null) {
    target = target.querySelector('.method-source-code');
  }
  if (typeof target !== "undefined" && target !== null) {
    target.classList.toggle('active-menu')
  }
};

function hookSourceViews() {
  document.querySelectorAll('.toggle-source').forEach(function (codeObject) {
    codeObject.addEventListener('click', showSource);
  });
};

function hookSearch() {

  const searchButton = document.querySelector('button[aria-label="Search"]');
  const searchDialog = document.getElementById('search-dialog');

  if (searchButton && searchDialog) {
    searchButton.addEventListener('click', function(event) {
      event.preventDefault();
      searchDialog.showModal();
      searchDialog.querySelector('input[name="q"]').focus();
    });
  }

  // Close dialog when clicking on the backdrop
  searchDialog.addEventListener('click', function(event) {
    const rect = this.getBoundingClientRect();
    const isInDialog = (rect.top <= event.clientY && event.clientY <= rect.top + rect.height &&
                        rect.left <= event.clientX && event.clientX <= rect.left + rect.width);
    if (!isInDialog) {
      this.close();
    }
  });

  var input  = document.querySelector('#search-field');
  var result = document.querySelector('#search-results');
  result.classList.remove("initially-hidden");

  var search_section = document.querySelector('#search-dialog');
  search_section.classList.remove("initially-hidden");

  var search = new Search(search_data, input, result);

  search.renderItem = function(result) {
    var li = document.createElement('li');
    var html = '';

    // TODO add relative path to <script> per-page
    html += '<p class="search-match"><a href="' + index_rel_prefix + this.escapeHTML(result.path) + '">' + this.hlt(result.title);
    if (result.params)
      html += '<span class="params">' + result.params + '</span>';
    html += '</a>';


    if (result.namespace)
      html += '<p class="search-namespace">' + this.hlt(result.namespace);

    if (result.snippet)
      html += '<div class="search-snippet">' + result.snippet + '</div>';

    li.innerHTML = html;

    return li;
  }

  search.select = function(result) {
    window.location.href = result.firstChild.firstChild.href;
  }

  search.scrollIntoView = search.scrollInWindow;
};

function hookFocus() {
  document.addEventListener("keydown", (event) => {
    if (document.activeElement.tagName === 'INPUT') {
      return;
    }
    if (event.key === "/") {
      event.preventDefault();
      document.querySelector('#search-field').focus();
    }
  });
}

function hookSidebar() {
  var navigation = document.querySelector('#navigation');
  var navigationToggle = document.querySelector('#navigation-toggle');

  navigationToggle.addEventListener('click', function() {
    navigation.hidden = !navigation.hidden;
    navigationToggle.ariaExpanded = navigationToggle.ariaExpanded !== 'true';
  });

  var isSmallViewport = window.matchMedia("(max-width: 1024px)").matches;
  if (isSmallViewport) {
    navigation.hidden = true;
    navigationToggle.ariaExpanded = false;
  }
}

function hookScrollSpy() {
  const anchors = document.querySelectorAll('[id]');

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      const id = entry.target.id;
      const correspondingLi = document.querySelector(`.contextual li a[href="#${id}"]`)?.parentElement;

      if (correspondingLi) {
        if (entry.isIntersecting) {
          correspondingLi.classList.add('active');
        } else {
          correspondingLi.classList.remove('active');
        }
      }
    });
  }, {
    rootMargin: '-60px 0px -10% 0px',
    threshold: 0
  });

  anchors.forEach(anchor => observer.observe(anchor));
}

function scrollToActiveLeftSidebarItem() {
  const item = document.querySelector("#class-and-module-index .active")
  item && item.scrollIntoView({block: "center"})
}

document.addEventListener('DOMContentLoaded', function() {
  hookSourceViews();
  hookSearch();
  hookFocus();
  hookSidebar();
  hookScrollSpy();
  scrollToActiveLeftSidebarItem();
});
