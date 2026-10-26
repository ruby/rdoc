'use strict';

const { test } = require('node:test');
const { assert, assertIncludes, refuteIncludes, loadHighlighter } = require('../helper');

const highlight = loadHighlighter('aliki/js/bash_highlighter.js');

test('prompts', () => {
  // $ followed by space or end of line is a prompt
  for (const [input, expected] of [
    ['$ bundle exec rake', '<span class="sh-prompt">$</span>'],
    ['  $ npm install', '<span class="sh-prompt">$</span>'],
    ['$', '<span class="sh-prompt">$</span>'],
  ]) {
    assertIncludes(highlight(input), expected, `Failed for: ${input}`);
  }

  // $VAR is a variable, not a prompt
  refuteIncludes(highlight('$HOME/bin'), '<span class="sh-prompt">');
});

test('comments', () => {
  for (const [input, expected] of [
    ['# This is a comment', '<span class="sh-comment"># This is a comment</span>'],
    ['bundle exec rake # Run tests', '<span class="sh-comment"># Run tests</span>'],
  ]) {
    assertIncludes(highlight(input), expected, `Failed for: ${input}`);
  }
});

test('options', () => {
  for (const [input, expected] of [
    ['ls -l', '<span class="sh-option">-l</span>'],
    ['npm install --save-dev', '<span class="sh-option">--save-dev</span>'],
    ['git commit --message=fix', '<span class="sh-option">--message=fix</span>'],
    ['ls -la --color=auto', ['<span class="sh-option">-la</span>', '<span class="sh-option">--color=auto</span>']],
  ]) {
    for (const exp of [expected].flat()) {
      assertIncludes(highlight(input), exp, `Failed for: ${input}`);
    }
  }
});

test('options with quoted values', () => {
  // Option with quoted value should stop at the quote
  let result = highlight('git commit --message="initial commit"');
  assertIncludes(result, '<span class="sh-option">--message=</span>');
  assertIncludes(result, '<span class="sh-string">&quot;initial commit&quot;</span>');

  // Single-quoted value
  result = highlight("git commit --message='initial commit'");
  assertIncludes(result, '<span class="sh-option">--message=</span>');
  assertIncludes(result, '<span class="sh-string">&#39;initial commit&#39;</span>');
});

test('strings', () => {
  for (const [input, expected] of [
    ['echo "hello world"', '<span class="sh-string">&quot;hello world&quot;</span>'],
    ["echo 'hello world'", '<span class="sh-string">&#39;hello world&#39;</span>'],
    ['echo "hello \\"world\\""', '<span class="sh-string">&quot;hello \\&quot;world\\&quot;&quot;</span>'],
    ['npx @herb-tools/linter "**/*.rhtml"', '<span class="sh-string">&quot;**/*.rhtml&quot;</span>'],
  ]) {
    assertIncludes(highlight(input), expected, `Failed for: ${input}`);
  }
});

test('commands', () => {
  const result = highlight('bundle exec rake');
  assertIncludes(result, '<span class="sh-command">bundle</span>');
  // Only the first word is highlighted as command
  refuteIncludes(result, '<span class="sh-command">exec</span>');
  refuteIncludes(result, '<span class="sh-command">rake</span>');
});

test('path commands', () => {
  for (const [input, expected] of [
    ['./configure --prefix=/usr/local', '<span class="sh-command">./configure</span>'],
    ['../configure --enable-gcov', '<span class="sh-command">../configure</span>'],
    ['./autogen.sh', '<span class="sh-command">./autogen.sh</span>'],
    ['~/.rubies/ruby-master/bin/ruby -e "puts 1"', '<span class="sh-command">~/.rubies/ruby-master/bin/ruby</span>'],
  ]) {
    assertIncludes(highlight(input), expected, `Failed for: ${input}`);
  }
});

test('absolute path commands', () => {
  for (const [input, expected] of [
    ['/bin/sh -c "echo hello"', '<span class="sh-command">/bin/sh</span>'],
    ['/usr/bin/env ruby', '<span class="sh-command">/usr/bin/env</span>'],
    ['/opt/homebrew/bin/ruby -v', '<span class="sh-command">/opt/homebrew/bin/ruby</span>'],
  ]) {
    assertIncludes(highlight(input), expected, `Failed for: ${input}`);
  }
});

test('environment variables', () => {
  for (const [input, expected] of [
    ['COVERAGE=true make test', ['<span class="sh-envvar">COVERAGE=</span>', '<span class="sh-command">make</span>']],
    ['CC=clang CXX=clang++ make', ['<span class="sh-envvar">CC=</span>', '<span class="sh-envvar">CXX=</span>', '<span class="sh-command">make</span>']],
    ['RUBY_TEST_TIMEOUT_SCALE=5 make check', ['<span class="sh-envvar">RUBY_TEST_TIMEOUT_SCALE=</span>', '<span class="sh-command">make</span>']],
  ]) {
    for (const exp of [expected].flat()) {
      assertIncludes(highlight(input), exp, `Failed for: ${input}`);
    }
  }
});

test('hyphens in words not options', () => {
  // Hyphen in @herb-tools/linter should NOT be treated as option
  let result = highlight('npx @herb-tools/linter');
  assertIncludes(result, '<span class="sh-command">npx</span>');
  refuteIncludes(result, '<span class="sh-option">-tools/linter</span>');
  assertIncludes(result, '@herb-tools/linter');

  // Command with hyphen gets highlighted as command, not option
  result = highlight('some-command arg');
  assertIncludes(result, '<span class="sh-command">some-command</span>');
  refuteIncludes(result, '<span class="sh-option">');
});

test('complex commands', () => {
  // Typical shell command with prompt
  let result = highlight('$ bundle exec rubocop -A');
  assertIncludes(result, '<span class="sh-prompt">$</span>');
  assertIncludes(result, '<span class="sh-command">bundle</span>');
  assertIncludes(result, '<span class="sh-option">-A</span>');

  // Complex git command
  result = highlight('$ git commit -m "Fix bug" --no-verify');
  assertIncludes(result, '<span class="sh-prompt">$</span>');
  assertIncludes(result, '<span class="sh-command">git</span>');
  assertIncludes(result, '<span class="sh-option">-m</span>');
  assertIncludes(result, '<span class="sh-string">&quot;Fix bug&quot;</span>');
  assertIncludes(result, '<span class="sh-option">--no-verify</span>');
});

test('multiline with comments', () => {
  const code = `# Generate documentation (creates _site directory)
bundle exec rake rdoc

# Force regenerate documentation
bundle exec rake rerdoc
`;

  const result = highlight(code);
  assertIncludes(result, '<span class="sh-comment"># Generate documentation (creates _site directory)</span>');
  assertIncludes(result, '<span class="sh-comment"># Force regenerate documentation</span>');
});

test('empty and whitespace', () => {
  assert.equal(highlight(''), '');
  assert.equal(highlight('   \n\t  \n  '), '   \n\t  \n  ');
});

test('html escaping', () => {
  let result = highlight('echo "<script>alert(1)</script>"');
  assertIncludes(result, '&lt;script&gt;');
  assertIncludes(result, '&lt;/script&gt;');

  result = highlight('echo "a && b"');
  assertIncludes(result, '&amp;&amp;');
});
