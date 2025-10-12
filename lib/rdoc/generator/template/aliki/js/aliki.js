/* ===== Method Source Code Toggling ===== */

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
  document.querySelectorAll('.method-source-toggle').forEach(function (codeObject) {
    codeObject.addEventListener('click', showSource);
  });
}

/* ===== Search Functionality ===== */

function createSearchInstance(input, result) {
  if (!input || !result) return null;

  result.classList.remove("initially-hidden");

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
    var href = result.firstChild.firstChild.href;
    var query = this.input.value;
    if (query) {
      var url = new URL(href, window.location.origin);
      url.searchParams.set('q', query);
      url.searchParams.set('nav', '0');
      href = url.toString();
    }
    window.location.href = href;
  }

  search.scrollIntoView = search.scrollInWindow;

  return search;
}

function hookSearch() {
  var input  = document.querySelector('#search-field');
  var result = document.querySelector('#search-results');

  if (!input || !result) return; // Exit if search elements not found

  var search_section = document.querySelector('#search-section');
  if (search_section) {
    search_section.classList.remove("initially-hidden");
  }

  var search = createSearchInstance(input, result);
  if (!search) return;

  // Check for ?q= URL parameter and trigger search automatically
  if (typeof URLSearchParams !== 'undefined') {
    var urlParams = new URLSearchParams(window.location.search);
    var queryParam = urlParams.get('q');
    if (queryParam) {
      var navParam = urlParams.get('nav');
      var autoSelect = navParam !== '0';
      input.value = queryParam;
      search.search(queryParam, autoSelect);
    }
  }
}

/* ===== Keyboard Shortcuts ===== */

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

/* ===== Mobile Navigation ===== */

function hookSidebar() {
  var navigation = document.querySelector('#navigation');
  var navigationToggle = document.querySelector('#navigation-toggle');

  if (!navigation || !navigationToggle) return;

  function closeNav() {
    navigation.hidden = true;
    navigationToggle.ariaExpanded = 'false';
    document.body.classList.remove('nav-open');
  }

  function openNav() {
    navigation.hidden = false;
    navigationToggle.ariaExpanded = 'true';
    document.body.classList.add('nav-open');
  }

  function toggleNav() {
    if (navigation.hidden) {
      openNav();
    } else {
      closeNav();
    }
  }

  navigationToggle.addEventListener('click', function(e) {
    e.stopPropagation();
    toggleNav();
  });

  var isSmallViewport = window.matchMedia("(max-width: 1023px)").matches;
  if (isSmallViewport) {
    closeNav();

    // Close nav when clicking links inside it
    document.addEventListener('click', (e) => {
      if (e.target.closest('#navigation a')) {
        closeNav();
      }
    });

    // Close nav when clicking backdrop
    document.addEventListener('click', (e) => {
      if (!navigation.hidden &&
          !e.target.closest('#navigation') &&
          !e.target.closest('#navigation-toggle')) {
        closeNav();
      }
    });
  }
}

/* ===== Right Sidebar Table of Contents ===== */

function generateToc() {
  var tocNav = document.querySelector('#toc-nav');
  if (!tocNav) return; // Exit if TOC nav doesn't exist

  var main = document.querySelector('main');
  if (!main) return;

  // Find all h2 and h3 headings in the main content
  var headings = main.querySelectorAll('h1, h2, h3');
  if (headings.length === 0) return;

  var tocList = document.createElement('ul');
  tocList.className = 'toc-list';

  headings.forEach(function(heading) {
    // Skip if heading doesn't have an id
    if (!heading.id) return;

    var li = document.createElement('li');
    var level = heading.tagName.toLowerCase();
    li.className = 'toc-item toc-' + level;

    var link = document.createElement('a');
    link.href = '#' + heading.id;
    link.className = 'toc-link';
    link.textContent = heading.textContent.replace(/¶.*$/, '').trim(); // Remove pilcrow and "top" links
    link.setAttribute('data-target', heading.id);

    li.appendChild(link);
    tocList.appendChild(li);
  });

  if (tocList.children.length > 0) {
    tocNav.appendChild(tocList);
  } else {
    // Hide TOC if no headings found
    var tocContainer = document.querySelector('.table-of-contents');
    if (tocContainer) {
      tocContainer.style.display = 'none';
    }
  }
}

function hookTocActiveHighlighting() {
  var tocLinks = document.querySelectorAll('.toc-link');
  if (tocLinks.length === 0) return;

  var observerOptions = {
    root: null,
    rootMargin: '-20% 0px -35% 0px',
    threshold: 0
  };

  var activeLink = null;

  var observer = new IntersectionObserver(function(entries) {
    entries.forEach(function(entry) {
      if (entry.isIntersecting) {
        var id = entry.target.id;
        var correspondingLink = document.querySelector('.toc-link[data-target="' + id + '"]');

        if (correspondingLink) {
          // Remove active class from all links
          tocLinks.forEach(function(link) {
            link.classList.remove('active');
          });

          // Add active class to current link
          correspondingLink.classList.add('active');
          activeLink = correspondingLink;

          // Scroll link into view if needed
          var tocNav = document.querySelector('#toc-nav');
          if (tocNav) {
            var linkRect = correspondingLink.getBoundingClientRect();
            var navRect = tocNav.getBoundingClientRect();

            if (linkRect.top < navRect.top || linkRect.bottom > navRect.bottom) {
              correspondingLink.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
            }
          }
        }
      }
    });
  }, observerOptions);

  // Observe all headings that have corresponding TOC links
  tocLinks.forEach(function(link) {
    var targetId = link.getAttribute('data-target');
    var targetHeading = document.getElementById(targetId);
    if (targetHeading) {
      observer.observe(targetHeading);
    }
  });

  // Smooth scroll when clicking TOC links
  tocLinks.forEach(function(link) {
    link.addEventListener('click', function(e) {
      e.preventDefault();
      var targetId = this.getAttribute('data-target');
      var targetHeading = document.getElementById(targetId);
      if (targetHeading) {
        targetHeading.scrollIntoView({ behavior: 'smooth', block: 'start' });
        history.pushState(null, '', '#' + targetId);
      }
    });
  });
}

/* ===== Mobile Search Modal ===== */

function hookSearchModal() {
  var searchToggle = document.querySelector('#search-toggle');
  var searchModal = document.querySelector('#search-modal');
  var searchModalClose = document.querySelector('#search-modal-close');
  var searchModalBackdrop = document.querySelector('.search-modal-backdrop');
  var searchInput = document.querySelector('#search-field-mobile');
  var searchResults = document.querySelector('#search-results-mobile');
  var searchEmpty = document.querySelector('.search-modal-empty');

  if (!searchToggle || !searchModal) return;

  // Initialize search for mobile modal
  var mobileSearch = createSearchInstance(searchInput, searchResults);
  if (!mobileSearch) return;

  // Hide empty state when there are results
  var originalRenderItem = mobileSearch.renderItem;
  mobileSearch.renderItem = function(result) {
    if (searchEmpty) searchEmpty.style.display = 'none';
    return originalRenderItem.call(this, result);
  };

  function openSearchModal() {
    searchModal.hidden = false;
    document.body.style.overflow = 'hidden';
    // Focus input after animation
    setTimeout(function() {
      if (searchInput) searchInput.focus();
    }, 100);
  }

  function closeSearchModal() {
    searchModal.hidden = true;
    document.body.style.overflow = '';
  }

  // Open on button click
  searchToggle.addEventListener('click', openSearchModal);

  // Close on close button click
  if (searchModalClose) {
    searchModalClose.addEventListener('click', closeSearchModal);
  }

  // Close on backdrop click
  if (searchModalBackdrop) {
    searchModalBackdrop.addEventListener('click', closeSearchModal);
  }

  // Close on Escape key
  document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape' && !searchModal.hidden) {
      closeSearchModal();
    }
  });

  // Check for ?q= URL parameter on mobile and open modal
  if (typeof URLSearchParams !== 'undefined') {
    var urlParams = new URLSearchParams(window.location.search);
    var queryParam = urlParams.get('q');
    var isSmallViewport = window.matchMedia("(max-width: 1023px)").matches;

    if (queryParam && isSmallViewport) {
      openSearchModal();
      searchInput.value = queryParam;
      var navParam = urlParams.get('nav');
      var autoSelect = navParam !== '0';
      mobileSearch.search(queryParam, autoSelect);
    }
  }
}

/* ===== Code Block Copy Functionality ===== */

function createCopyButton() {
  var button = document.createElement('button');
  button.className = 'copy-code-button';
  button.type = 'button';
  button.setAttribute('aria-label', 'Copy code to clipboard');
  button.setAttribute('title', 'Copy code');

  // Create clipboard icon SVG
  var clipboardIcon = `
    <svg viewBox="0 0 24 24">
      <rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect>
      <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path>
    </svg>
  `;

  // Create checkmark icon SVG (for copied state)
  var checkIcon = `
    <svg viewBox="0 0 24 24">
      <polyline points="20 6 9 17 4 12"></polyline>
    </svg>
  `;

  button.innerHTML = clipboardIcon;
  button.dataset.clipboardIcon = clipboardIcon;
  button.dataset.checkIcon = checkIcon;

  return button;
}

function wrapCodeBlocksWithCopyButton() {
  // Copy buttons are generated dynamically rather than statically in rhtml templates because:
  // - Code blocks are generated by RDoc's markup formatter (RDoc::Markup::ToHtml),
  //   not directly in rhtml templates
  // - Modifying the formatter would require extending RDoc's core internals

  // Find all pre elements that are not already wrapped
  var preElements = document.querySelectorAll('main pre:not(.code-block-wrapper pre)');

  preElements.forEach(function(pre) {
    // Skip if already wrapped
    if (pre.parentElement.classList.contains('code-block-wrapper')) {
      return;
    }

    // Create wrapper
    var wrapper = document.createElement('div');
    wrapper.className = 'code-block-wrapper';

    // Insert wrapper before pre
    pre.parentNode.insertBefore(wrapper, pre);

    // Move pre into wrapper
    wrapper.appendChild(pre);

    // Create and add copy button
    var copyButton = createCopyButton();
    wrapper.appendChild(copyButton);

    // Add click handler
    copyButton.addEventListener('click', function() {
      copyCodeToClipboard(pre, copyButton);
    });
  });
}

function copyCodeToClipboard(preElement, button) {
  var code = preElement.textContent;

  // Use the Clipboard API (supported by all modern browsers)
  if (navigator.clipboard && navigator.clipboard.writeText) {
    navigator.clipboard.writeText(code).then(function() {
      showCopySuccess(button);
    }).catch(function() {
      alert('Failed to copy code.');
    });
  } else {
    alert('Failed to copy code.');
  }
}

function showCopySuccess(button) {
  // Change icon to checkmark
  button.innerHTML = button.dataset.checkIcon;
  button.classList.add('copied');
  button.setAttribute('aria-label', 'Copied!');
  button.setAttribute('title', 'Copied!');

  // Revert back after 2 seconds
  setTimeout(function() {
    button.innerHTML = button.dataset.clipboardIcon;
    button.classList.remove('copied');
    button.setAttribute('aria-label', 'Copy code to clipboard');
    button.setAttribute('title', 'Copy code');
  }, 2000);
}

/* ===== Initialization ===== */

document.addEventListener('DOMContentLoaded', function() {
  hookSourceViews();
  hookSearch();
  hookFocus();
  hookSidebar();
  generateToc();
  hookTocActiveHighlighting();
  hookSearchModal();
  wrapCodeBlocksWithCopyButton();
});
