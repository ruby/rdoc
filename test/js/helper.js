'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { inspect } = require('node:util');
const vm = require('node:vm');

const TEMPLATE_DIR = path.join(__dirname, '../../lib/rdoc/generator/template');

// The template scripts are classic browser scripts that share globals.
// Load them into one fresh context, in the order a page loads them.
function loadScripts(files, globals = {}) {
  const context = vm.createContext(globals);
  for (const file of files) {
    const source = fs.readFileSync(path.join(TEMPLATE_DIR, file), 'utf8');
    vm.runInContext(source, context, { filename: file });
  }
  return context;
}

// Load a highlighter script with a fake document and return a function that
// highlights one code block the way the page does on DOMContentLoaded.
function loadHighlighter(file) {
  let onLoad = null;
  let blocks = [];
  const document = {
    readyState: 'loading',
    addEventListener(type, listener) {
      if (type === 'DOMContentLoaded') onLoad = listener;
    },
    querySelectorAll() {
      return blocks;
    }
  };
  loadScripts([file], { document });

  return function highlight(code) {
    const attributes = {};
    const block = {
      textContent: code,
      innerHTML: code,
      getAttribute: (name) => attributes[name],
      setAttribute: (name, value) => { attributes[name] = value; }
    };
    blocks = [block];
    onLoad();
    return block.innerHTML;
  };
}

function assertIncludes(collection, item, message) {
  assert.ok(
    collection.includes(item),
    message ?? `Expected ${inspect(collection)} to include ${inspect(item)}`
  );
}

function refuteIncludes(collection, item, message) {
  assert.ok(
    !collection.includes(item),
    message ?? `Expected ${inspect(collection)} not to include ${inspect(item)}`
  );
}

module.exports = { assert, assertIncludes, refuteIncludes, loadHighlighter, loadScripts };
