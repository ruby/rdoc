# frozen_string_literal: true

require_relative '../../helper'

return if RUBY_DESCRIPTION =~ /truffleruby/ || RUBY_DESCRIPTION =~ /jruby/

begin
  require 'mini_racer'
rescue LoadError
  return
end

class RDocGeneratorAlikiHighlightBashTest < Test::Unit::TestCase
  HIGHLIGHT_BASH_JS_PATH = File.expand_path(
    '../../../../lib/rdoc/generator/template/aliki/js/bash_highlighter.js',
    __dir__
  )

  HIGHLIGHT_BASH_JS = begin
    highlight_bash_js = File.read(HIGHLIGHT_BASH_JS_PATH)

    # We need to modify the JS slightly to make it work in the context of a test.
    highlight_bash_js.gsub(
      /\(function\(\) \{[\s\S]*'use strict';/,
      "// Test wrapper\n"
    ).gsub(
      /if \(document\.readyState[\s\S]*\}\)\(\);/,
      "// Removed DOM initialization for testing"
    )
  end.freeze

  def setup
    @context = MiniRacer::Context.new
    @context.eval(HIGHLIGHT_BASH_JS)
  end

  def teardown
    @context.dispose
  end

  def test_prompts
    # $ followed by space or end of line is a prompt
    [
      ['$ bundle exec rake', '<span class="sh-prompt">$</span>'],
      ['  $ npm install', '<span class="sh-prompt">$</span>'],
      ['$', '<span class="sh-prompt">$</span>'],
    ].each do |input, expected|
      assert_includes highlight(input), expected, "Failed for: #{input}"
    end

    # $VAR is a variable, not a prompt
    refute_includes highlight('$HOME/bin'), '<span class="sh-prompt">'
  end

  def test_comments
    [
      ['# This is a comment', '<span class="sh-comment"># This is a comment</span>'],
      ['bundle exec rake # Run tests', '<span class="sh-comment"># Run tests</span>'],
    ].each do |input, expected|
      assert_includes highlight(input), expected, "Failed for: #{input}"
    end
  end

  def test_options
    [
      ['ls -l', '<span class="sh-option">-l</span>'],
      ['npm install --save-dev', '<span class="sh-option">--save-dev</span>'],
      ['git commit --message=fix', '<span class="sh-option">--message=fix</span>'],
      ['ls -la --color=auto', ['<span class="sh-option">-la</span>', '<span class="sh-option">--color=auto</span>']],
    ].each do |input, expected|
      Array(expected).each do |exp|
        assert_includes highlight(input), exp, "Failed for: #{input}"
      end
    end
  end

  def test_options_with_quoted_values
    # Option with quoted value should stop at the quote
    result = highlight('git commit --message="initial commit"')
    assert_includes result, '<span class="sh-option">--message=</span>'
    assert_includes result, '<span class="sh-string">&quot;initial commit&quot;</span>'

    # Single-quoted value
    result = highlight("git commit --message='initial commit'")
    assert_includes result, '<span class="sh-option">--message=</span>'
    assert_includes result, "<span class=\"sh-string\">&#39;initial commit&#39;</span>"
  end

  def test_strings
    [
      ['echo "hello world"', '<span class="sh-string">&quot;hello world&quot;</span>'],
      ["echo 'hello world'", "<span class=\"sh-string\">&#39;hello world&#39;</span>"],
      ['echo "hello \"world\""', '<span class="sh-string">&quot;hello \&quot;world\&quot;&quot;</span>'],
      ['npx @herb-tools/linter "**/*.rhtml"', '<span class="sh-string">&quot;**/*.rhtml&quot;</span>'],
    ].each do |input, expected|
      assert_includes highlight(input), expected, "Failed for: #{input}"
    end
  end

  def test_commands
    result = highlight('bundle exec rake')
    assert_includes result, '<span class="sh-command">bundle</span>'
    # Only the first word is highlighted as command
    refute_includes result, '<span class="sh-command">exec</span>'
    refute_includes result, '<span class="sh-command">rake</span>'
  end

  def test_path_commands
    [
      ['./configure --prefix=/usr/local', '<span class="sh-command">./configure</span>'],
      ['../configure --enable-gcov', '<span class="sh-command">../configure</span>'],
      ['./autogen.sh', '<span class="sh-command">./autogen.sh</span>'],
      ['~/.rubies/ruby-master/bin/ruby -e "puts 1"', '<span class="sh-command">~/.rubies/ruby-master/bin/ruby</span>'],
    ].each do |input, expected|
      assert_includes highlight(input), expected, "Failed for: #{input}"
    end
  end

  def test_absolute_path_commands
    [
      ['/bin/sh -c "echo hello"', '<span class="sh-command">/bin/sh</span>'],
      ['/usr/bin/env ruby', '<span class="sh-command">/usr/bin/env</span>'],
      ['/opt/homebrew/bin/ruby -v', '<span class="sh-command">/opt/homebrew/bin/ruby</span>'],
    ].each do |input, expected|
      assert_includes highlight(input), expected, "Failed for: #{input}"
    end
  end

  def test_environment_variables
    [
      ['COVERAGE=true make test', ['<span class="sh-envvar">COVERAGE=</span>', '<span class="sh-command">make</span>']],
      ['CC=clang CXX=clang++ make', ['<span class="sh-envvar">CC=</span>', '<span class="sh-envvar">CXX=</span>', '<span class="sh-command">make</span>']],
      ['RUBY_TEST_TIMEOUT_SCALE=5 make check', ['<span class="sh-envvar">RUBY_TEST_TIMEOUT_SCALE=</span>', '<span class="sh-command">make</span>']],
    ].each do |input, expected|
      Array(expected).each do |exp|
        assert_includes highlight(input), exp, "Failed for: #{input}"
      end
    end
  end

  def test_hyphens_in_words_not_options
    # Hyphen in @herb-tools/linter should NOT be treated as option
    result = highlight('npx @herb-tools/linter')
    assert_includes result, '<span class="sh-command">npx</span>'
    refute_includes result, '<span class="sh-option">-tools/linter</span>'
    assert_includes result, '@herb-tools/linter'

    # Command with hyphen gets highlighted as command, not option
    result = highlight('some-command arg')
    assert_includes result, '<span class="sh-command">some-command</span>'
    refute_includes result, '<span class="sh-option">'
  end

  def test_complex_commands
    # Typical shell command with prompt
    result = highlight('$ bundle exec rubocop -A')
    assert_includes result, '<span class="sh-prompt">$</span>'
    assert_includes result, '<span class="sh-command">bundle</span>'
    assert_includes result, '<span class="sh-option">-A</span>'

    # Complex git command
    result = highlight('$ git commit -m "Fix bug" --no-verify')
    assert_includes result, '<span class="sh-prompt">$</span>'
    assert_includes result, '<span class="sh-command">git</span>'
    assert_includes result, '<span class="sh-option">-m</span>'
    assert_includes result, '<span class="sh-string">&quot;Fix bug&quot;</span>'
    assert_includes result, '<span class="sh-option">--no-verify</span>'
  end

  def test_multiline_with_comments
    code = <<~SHELL
      # Generate documentation (creates _site directory)
      bundle exec rake rdoc

      # Force regenerate documentation
      bundle exec rake rerdoc
    SHELL

    result = highlight(code)
    assert_includes result, '<span class="sh-comment"># Generate documentation (creates _site directory)</span>'
    assert_includes result, '<span class="sh-comment"># Force regenerate documentation</span>'
  end

  def test_empty_and_whitespace
    assert_equal '', highlight('')
    assert_equal "   \n\t  \n  ", highlight("   \n\t  \n  ")
  end

  def test_html_escaping
    result = highlight('echo "<script>alert(1)</script>"')
    assert_includes result, '&lt;script&gt;'
    assert_includes result, '&lt;/script&gt;'

    result = highlight('echo "a && b"')
    assert_includes result, '&amp;&amp;'
  end

  private

  def highlight(code)
    @context.eval("highlightShell(#{code.to_json})")
  end
end
