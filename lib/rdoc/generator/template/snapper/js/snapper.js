"use strict";

let searchModal;
let searchModalContent;
let sideSearchInput;
let searchInput;
let searchResults;
let mainContainer;
let searchIndex = search_data.index;

function hideSearchModal() {
  searchModal.style.display = "none";
  mainContainer.style.filter = "none";
}

function showSearchModal() {
  searchModal.style.display = "flex";
  mainContainer.style.filter = "blur(8px)";

  if (searchResults.innerHTML === "") {
    // Populate the search modal with the first 10 items to start
    const initialEntries = searchIndex.info.slice(0, 10).map((entry) => {
      return {
        title: entry[0],
        namespace: entry[1],
        path: entry[2],
        snippet: entry[4],
      };
    });
    searchResults.innerHTML = htmlForResults(initialEntries);
  }

  searchInput.value = "";
  searchInput.focus();
}

function htmlForResults(results) {
  // The solo closing p tag is intentional. The snippet is HTML and includes only the opening of the tag
  return results.map((result) => {
    let name = result.title;

    if (result.namespace) {
      name += ` (${result.namespace})`;
    }
    const escapedPath = result.path.replace(/[&<>"`']/g, (c) => `&#${c.charCodeAt(0)};`);

    return `<li>
          <a class="result-link" href="${index_rel_prefix}${escapedPath}">
            <span class="result-title">${name}</span>
            ${result.snippet}</p>
          </a>
        </li>`;
  }).join("");
}

function setupSearch() {
  searchModal = document.getElementById("search-modal");
  searchModalContent = document.getElementById("search-modal-content");
  sideSearchInput = document.getElementById("side-search");
  mainContainer = document.getElementById("main-container");
  searchInput = document.getElementById("search-modal-input");
  searchResults = document.getElementById("search-results");

  // Toggle the search modal on CMD|CTRL + K
  document.addEventListener("keydown", (event) => {
    if (event.metaKey && event.key === "k") {
      if (searchModal.style.display === "flex") {
        hideSearchModal();
      } else {
        showSearchModal();
      }
    } else if (event.key === "Escape") {
      hideSearchModal();
    }
  });

  // Show the search modal when clicking on the side search input. Hide it when clicking anywhere outside of the modal
  document.addEventListener("click", (event) => {
    if (event.target === sideSearchInput) {
      showSearchModal();
    } else if (!searchModalContent.contains(event.target)) {
      hideSearchModal();
    }
  });

  // Search submission
  let debounceTimerId;

  searchInput.addEventListener("input", (event) => {
    clearTimeout(debounceTimerId);

    debounceTimerId = setTimeout(() => {
      if (event.target.value === "") {
        searchResults.innerHTML = "";
        return;
      }

      const regex = new RegExp(event.target.value, "i");
      const results = [];

      searchIndex.longSearchIndex.forEach((entry, index) => {
        if (regex.test(entry)) {
          const info = searchIndex.info[index];

          // The data indexed by JsonIndex is in an array format
          results.push({
            title: info[0],
            namespace: info[1],
            path: info[2],
            snippet: info[4],
          });
        }
      });

      if (results.length === 0) {
        searchResults.innerHTML = "<li><p>No results found</p></li>";
        return;
      }

      searchResults.innerHTML = htmlForResults(results);
    }, 500);
  });
}

window.addEventListener("DOMContentLoaded", (_event) => {
  setupSearch();
});
