"use strict";

let searchModal;
let searchModalContent;
let sideSearchInput;
let searchInput;
let mainContainer;

function hideSearchModal() {
  searchModal.style.display = "none";
  mainContainer.style.filter = "none";
}

function showSearchModal() {
  searchModal.style.display = "flex";
  mainContainer.style.filter = "blur(5px)";
  searchInput.value = "";
  searchInput.focus();
}

function setupSearch() {
  searchModal = document.getElementById("search-modal");
  searchModalContent = document.getElementById("search-modal-content");
  sideSearchInput = document.getElementById("side-search");
  mainContainer = document.getElementById("main-container");
  searchInput = document.getElementById("search-modal-input");

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
}

window.addEventListener("DOMContentLoaded", (_event) => {
  setupSearch();
});
