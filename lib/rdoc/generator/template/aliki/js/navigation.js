'use strict';

// Reuse the search index's visible classes and modules, adding unlinked
// ancestors where a namespace is hidden but has visible descendants.
function buildClassTree(index) {
  const roots = [];
  const byName = new Map();

  index.forEach((entry) => {
    if (entry.type !== 'class' && entry.type !== 'module') return;

    let children = roots;
    let fullName = '';
    entry.full_name.split('::').forEach((name) => {
      fullName = fullName ? fullName + '::' + name : name;
      let node = byName.get(fullName);
      if (!node) {
        node = {name, full_name: fullName, path: null, children: []};
        byName.set(fullName, node);
        children.push(node);
      }
      children = node.children;
    });
    byName.get(fullName).path = entry.path;
  });

  return roots;
}

// Share the class tree across pages without constructing the whole tree's DOM.
function buildClassNavigation(container, nodes, prefix, current) {
  function renderBranch(entries, expandSingleRoot = false) {
    const list = document.createElement('ul');
    list.className = 'link-list nav-list';

    entries.forEach((node) => {
      const item = document.createElement('li');
      const code = document.createElement('code');
      if (node.path) {
        const link = document.createElement('a');
        link.href = prefix + node.path;
        link.textContent = node.name;
        if (node.full_name === current) link.setAttribute('aria-current', 'page');
        code.appendChild(link);
      } else {
        code.textContent = node.name;
      }

      if (node.children.length) {
        const details = document.createElement('details');
        const summary = document.createElement('summary');
        summary.appendChild(code);
        details.appendChild(summary);
        let populated = false;
        const populate = () => {
          if (!details.open || populated) return;
          details.appendChild(renderBranch(node.children));
          populated = true;
        };
        details.addEventListener('toggle', populate);
        details.open = expandSingleRoot || node.full_name === current ||
          current.startsWith(node.full_name + '::');
        populate();
        item.appendChild(details);
      } else {
        item.appendChild(code);
      }
      list.appendChild(item);
    });
    return list;
  }

  container.replaceChildren(renderBranch(nodes, nodes.length === 1));
}

document.addEventListener('DOMContentLoaded', () => {
  const container = document.getElementById('class-navigation');
  if (!container || typeof search_data === 'undefined') return;
  buildClassNavigation(container, buildClassTree(search_data.index), index_rel_prefix, container.dataset.currentClass);
});
