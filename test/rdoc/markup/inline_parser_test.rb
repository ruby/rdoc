# frozen_string_literal: true

require_relative '../helper'
require 'rdoc/markup/inline_parser'

class RDocMarkupInlineParserTest < RDoc::TestCase
  def parse(text)
    RDoc::Markup::InlineParser.new(text).parse
  end

  def em_node(*children)
    { type: :EM, children: children }
  end

  def bold_node(*children)
    { type: :BOLD, children: children }
  end

  def bold_word(text)
    { type: :BOLD_WORD, children: [text] }
  end

  def em_word(text)
    { type: :EM_WORD, children: [text] }
  end

  def strike_node(*children)
    { type: :STRIKE, children: children }
  end

  def tt_node(*children)
    { type: :TT, children: children }
  end

  def tidylink_node(children, url)
    { type: :TIDYLINK, children: children, url: url }
  end

  def hard_break_node
    { type: :HARD_BREAK, children: [] }
  end

  def test_escape
    # Escaping backslash are removed, other backslashes (suppressed crossref) remains
    assert_equal(['\\', bold_node('\\Array'), bold_node('\\#to_s'), bold_node('\\::new')], parse('\\\\<b>\\Array</b><b>\\#to_s</b><b>\\::new</b>'))
    assert_equal(['_a_ +a+ <b>b</b> \\n \\ABC'], parse('\\_a_ \\+a+ \\<b>b\\</b> \\n \\ABC'))
    assert_equal([bold_node('</b>')], parse('<b>\\</b></b>'))
    assert_equal([em_node('</i>')], parse('<i>\\</i></i>'))
    assert_equal(['a\\'], parse('a\\'))
    assert_equal([tidylink_node(['<b></b>'], 'url')], parse('{\\<b>\\</b>}[url]'))
    # Unescape \\ and \< in code blocks
    assert_equal([tt_node('p(%(<b></b>\\)+"\\a\\n")')], parse('<tt>p(%(\\<b>\\</b>\\\\)+"\\a\\n")</tt>'))
  end

  def test_bold
    assert_equal([bold_node()], parse('<b></b>'))
    assert_equal(['*a b*'], parse('*a b*'))
    assert_equal(['x*a* *b*x'], parse('x*a* *b*x'))
    assert_equal([bold_word('bold')], parse('*bold*'))
    assert_equal([bold_word('bold')], parse('**bold**'))
    assert_equal([bold_node('bo ld')], parse('<b>bo ld</b>'))
    assert_equal(
      ['a ', bold_word('A'), ' b ', bold_word('B'), ' c ', bold_node('C C'), ' d'],
      parse('a *A* b **B** c <b>C C</b> d')
    )
    assert_equal([bold_node('a', em_node('b'), bold_node('c'), 'd')], parse('<b>a<i>b</i><b>c</b>d</b>'))
  end

  def test_em
    assert_equal([em_node()], parse('<em></em>'))
    assert_equal(['_a b_'], parse('_a b_'))
    assert_equal(['x_a_ _b_x'], parse('x_a_ _b_x'))
    assert_equal([em_word('em')], parse('_em_'))
    assert_equal([em_word('F1LE')], parse('__F1LE__'))
    assert_equal(['_foo_bar_baz'], parse('_foo_bar_baz'))

    # _ inside _em_
    assert_equal([em_word('foo_bar')], parse('_foo_bar_'))

    # non-alphanumeric after _
    assert_equal([em_word('host'), ':', em_word('port')], parse('_host_:_port_'))

    # Special exception
    assert_equal(['__send__'], parse('__send__'))
    assert_equal(['__FILE__'], parse('__FILE__'))

    assert_equal([em_node('e m')], parse('<em>e m</em>'))
    assert_equal([em_node('e m')], parse('<i>e m</i>'))
    assert_equal([em_node('a', bold_node('b'), em_node('c'), 'd')], parse('<i>a<b>b</b><i>c</i>d</i>'))
  end

  def test_method_like_words
    assert_equal([bold_word('::Foo.bar-baz')], parse('*::Foo.bar-baz*'))
    assert_equal([bold_word('#foo_bar=')], parse('*#foo_bar=*'))
    assert_equal([bold_word('#foo_bar!')], parse('*#foo_bar!*'))
    assert_equal([bold_word('#foo_bar?')], parse('*#foo_bar?*'))

    assert_equal([em_word('::Foo.bar-baz')], parse('_::Foo.bar-baz_'))
    assert_equal([em_word('#foo_bar=')], parse('_#foo_bar=_'))
    assert_equal([em_word('#foo_bar!')], parse('_#foo_bar!_'))
    assert_equal([em_word('#foo_bar?')], parse('_#foo_bar?_'))

    assert_equal([em_word('::Foo.bar-baz')], parse('__::Foo.bar-baz__'))
    assert_equal([em_word('#foo_bar=')], parse('__#foo_bar=__'))
    assert_equal([em_word('#foo_bar!')], parse('__#foo_bar!__'))
    assert_equal([em_word('#foo_bar?')], parse('__#foo_bar?__'))

    assert_equal([tt_node('::Foo.bar-baz')], parse('+::Foo.bar-baz+'))
    assert_equal([tt_node('#foo_bar=')], parse('+#foo_bar=+'))
    assert_equal([tt_node('#foo_bar!')], parse('+#foo_bar!+'))
    assert_equal([tt_node('#foo_bar?')], parse('+#foo_bar?+'))
  end

  def test_tt
    assert_equal([tt_node()], parse('<tt></tt>'))
    assert_equal(['`a b`'], parse('`a b`'))
    assert_equal(['x`a` `b`x'], parse('x`a` `b`x'))
    assert_equal([tt_node('code')], parse('`code`'))
    assert_equal([tt_node('code')], parse('+code+'))
    assert_equal([tt_node('code')], parse('++code++'))
    assert_equal([tt_node('code')], parse('``code``'))
    assert_equal([tt_node('<b></b>code(1 + 2)')], parse('<tt><b></b>code(1 + 2)</tt>'))
    assert_equal([tt_node('<b></b>code(1 + 2)')], parse('<code><b></b>code(1 + 2)</code>'))

    # Detect closing tag with escaping
    assert_equal([tt_node('a</tt>b\\')], parse('<tt>a\\</tt>b\\\\</tt>'))
    assert_equal([tt_node('a</code>b\\')], parse('<code>a\\</code>b\\\\</code>'))

    # Close with nearest non-escaped closing tag
    assert_equal([tt_node('a</tt>b'), 'c</tt>d</tt>'], parse('<tt>a\\</tt>b</tt>c</tt>d</tt>'))
    assert_equal([tt_node('a</code>b'), 'c</code>d</code>'], parse('<code>a\\</code>b</code>c</code>d</code>'))
  end

  def test_strike
    assert_equal([strike_node()], parse('<s></s>'))
    assert_equal([strike_node('strike ')], parse('<s>strike </s>'))
    assert_equal([strike_node('strike ')], parse('<del>strike </del>'))
    assert_equal([strike_node('a', bold_node('b'), strike_node('c'), 'd')], parse('<s>a<b>b</b><s>c</s>d</s>'))
  end

  def test_hard_break
    assert_equal([hard_break_node], parse('<br>'))
    assert_equal(['a', hard_break_node, 'b'], parse('a<br>b'))
    assert_equal([hard_break_node, hard_break_node], parse('<br><br>'))
    assert_equal([em_node('a', hard_break_node, 'b'), hard_break_node, 'c'], parse('<em>a<br>b</em><br>c'))
  end

  def test_simplified_tidylink
    # Empty url is not allowed
    assert_equal(['label[]'], parse('label[]'))
    assert_equal([tidylink_node(['label'], 'url')], parse('label[url]'))
    assert_equal([tidylink_node(['label'], 'http://example.com/?q=<b></b>+1+')], parse('label[http://example.com/?q=<b></b>+1+]'))
  end

  def test_tidylink
    # Empty label is allowed, empty url is not allowed
    assert_equal([tidylink_node([], 'url')], parse('{}[url]'))
    assert_equal(['{label}[]'], parse('{label}[]'))

    assert_equal(
      [tidylink_node(['label'], 'http://example.com/')],
      parse('{label}[http://example.com/]')
    )
    assert_equal(
      [tidylink_node(['label'], 'brac[ke]]t\\'), '_esc[]aped'],
      parse('{label}[brac\[ke\]\]t\\\\]_esc\[\]aped')
    )
    assert_equal(
      ['See ', tidylink_node(['this link'], 'http://example.com/'), ' for more info.'],
      parse('See {this link}[http://example.com/] for more info.')
    )
    assert_equal(
      [tidylink_node(['Label with ', bold_word('bold'), ' text'], 'http://example.com/')],
      parse('{Label with *bold* text}[http://example.com/]')
    )
    assert_equal(
      [bold_node('bold', tidylink_node(['link'], 'http://example.com/'))],
      parse('<b>bold{link}[http://example.com/]</b>')
    )
    assert_equal(
      [tidylink_node(['link'], 'http://example.com/?q=<b></b>+1+')],
      parse('{link}[http://example.com/?q=<b></b>+1+]')
    )
    assert_equal(
      [tidylink_node([tt_node('}[]{')], 'url')],
      parse('{<code>}[]{</code>}[url]')
    )
    # Non-tidylink braces and brackets inside tidylink label are allowed
    assert_equal(
      [tidylink_node(['[a]{b}{c}d'], 'url')],
      parse('{[a]{b}{c}d}[url]')
    )
  end

  def test_invalid_nested_tidylink
    # Simplified tidylink invalidates open tidylinks
    assert_equal(
      [bold_node('{a ', tidylink_node(['b'], 'url'), '}[', bold_word('c'), ']')],
      parse('<b>{a b[url]}[*c*]</b>')
    )
    # Normal tidylink invalidates open tidylinks
    assert_equal(
      [bold_node('{a ', tidylink_node(['b'], 'url'), '}[', bold_word('c'), ']')],
      parse('<b>{a {b}[url]}[*c*]</b>')
    )
    # Tidylink invalidates all open tidylinks
    assert_equal(
      [bold_node('{label', em_node('{label{label', tidylink_node(['label'], 'url'), '}[a]}[b]'), '}[c]')],
      parse('<b>{label<em>{label{label{label}[url]}[a]}[b]</em>}[c]</b>')
    )
    # Valid tidylink inside invalidated tidylink
    assert_equal(
      [bold_node('{', tidylink_node(['label1'], 'url1'), ' ', tidylink_node(['label2'], 'url2'), '}[', bold_word('b'), ']')],
      parse('<b>{{label1}[url1] {label2}[url2]}[*b*]</b>')
    )
    # Invalidated tidylink accepts tag break through brackets
    assert_equal(
      ['{', tidylink_node(['label'], 'url'), '}[', bold_node(']')],
      parse('{{label}[url]}[<b>]</b>')
    )
  end

  def test_unclosed_error_case
    # Treat as normal text
    assert_equal(['*unclosed bold'], parse('*unclosed bold'))
    assert_equal(['_unclosed em'], parse('_unclosed em'))
    assert_equal(['`unclosed tt'], parse('`unclosed tt'))
    assert_equal(['<b>unclosed tag'], parse('<b>unclosed tag'))
    assert_equal(['<code>unclosed code'], parse('<code>unclosed code'))
    assert_equal(['{unclosed tidylink'], parse('{unclosed tidylink'))
    assert_equal(['{label}[url'], parse('{label}[url'))
    assert_equal(['label[url'], parse('label[url'))
  end

  def test_unknown_tag_as_normal_text
    # Even if opening and closing tags are present, treat as normal text
    assert_equal(['<foo>', strike_node('</foo><bar><baz></bar><bar></baz>')], parse('<foo><s></foo><bar><baz></bar><bar></baz></s>'))
  end

  def test_invalid_closing_error_case
    # No opening tag, then treat it as normal text
    assert_equal([bold_node('</i>')], parse('<b></i></b>'))

    # </s>(strike closing) shouldn't close <del> (also strike)
    assert_equal([bold_node(strike_node('</s><s>'))], parse('<b><del></s><s></del></b>'))

    # Closing tag will close the last opened tag. Tag that has no corresponding open/close pair remains as normal text
    assert_equal([em_node('<b>'), '</b>'], parse('<em><b></em></b>'))

    # Tag that has corresponding open/close pair will be parsed normally
    assert_equal([em_node('<i>a', bold_node('b'), 'c<s>d')], parse('<em><i>a<b>b</b>c<s>d</em>'))

    # Unclosed code tag content will be parsed as normal rdoc
    assert_equal([em_node('<code><i>', bold_node('b'))], parse('<em><code><i><b>b</b></em>'))

    # Tidylink closing brace will close the last opened tidylink
    assert_equal([tidylink_node(['<em>', bold_node('b')], 'url'), '</em>'], parse('{<em><b>b</b>}[url]</em>'))

    # Tag closing will invalidate tidylink
    assert_equal([em_node('{a', bold_node('b')), 'c}[url]'], parse('<em>{a<b>b</b></em>c}[url]'))

    # Unclosed tidylink url will parsed as normal rdoc
    assert_equal(['label[http://example.com/?q=', bold_node(), tt_node('1')], parse('label[http://example.com/?q=<b></b>+1+'))
    assert_equal(['{label}[http://example.com/?q=', bold_node(), tt_node('1')], parse('{label}[http://example.com/?q=<b></b>+1+'))

    # Closing brace invalidates unclosed tags
    assert_equal(['{<s>', bold_node('foo'), '}</s>}[bar]'], parse('{<s><b>foo</b>}</s>}[bar]'))
  end
end
