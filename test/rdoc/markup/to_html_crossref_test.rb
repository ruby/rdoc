# frozen_string_literal: true
require_relative '../xref_test_case'
require 'rdoc/markdown'

class RDocMarkupToHtmlCrossrefTest < XrefTestCase

  def setup
    super

    @options.hyperlink_all = true
    @options.warn_missing_rdoc_ref = true

    @to = RDoc::Markup::ToHtmlCrossref.new @options, 'index.html', @c1
  end

  def test_convert_CROSSREF
    result = @to.convert 'C1'

    assert_equal para("<a href=\"C1.html\"><code>C1</code></a>"), result

    result = @to.convert '+C1+'
    assert_equal para("<a href=\"C1.html\"><code>C1</code></a>"), result

    result = @to.convert 'Constant[rdoc-ref:C1]'
    assert_equal para("<a href=\"C1.html\">Constant</a>"), result

    result = @to.convert 'FOO'
    assert_equal para("FOO"), result

    result = @to.convert '+FOO+'
    assert_equal para("<code>FOO</code>"), result

    result = @to.convert '<tt># :stopdoc:</tt>:'
    assert_equal para("<code># :stopdoc:</code>:"), result
  end

  def test_convert_CROSSREF_backslash_in_tt
    @options.hyperlink_all = false

    formatter = RDoc::Markup::ToHtmlCrossref.new(@options, 'C9.html', @c9_b)

    result = formatter.convert '<tt>C1</tt>'
    assert_equal para('<a href="C1.html"><code>C1</code></a>'), result

    result = formatter.convert '<tt>.bar.hello()</tt>'
    assert_equal para('<code>.bar.hello()</code>'), result

    result = formatter.convert '<tt>.bar.hello(\)</tt>'
    assert_equal para('<code>.bar.hello(\)</code>'), result

    result = formatter.convert '<tt>.bar.hello(\\\\)</tt>'
    assert_equal para('<code>.bar.hello(\\)</code>'), result
  end

  def test_convert_CROSSREF_ignored_excluded_words
    @options.autolink_excluded_words = ['C1']

    result = @to.convert 'C1'
    assert_equal para("C1"), result

    result = @to.convert '+C1+'
    assert_equal para("<a href=\"C1.html\"><code>C1</code></a>"), result

    # Explicit linking with rdoc-ref is not ignored
    result = @to.convert 'Constant[rdoc-ref:C1]'
    assert_equal para("<a href=\"C1.html\">Constant</a>"), result
  end

  def test_convert_CROSSREF_method
    result = @to.convert 'C1#m(foo, bar, baz)'

    assert_equal para("<a href=\"C1.html#method-i-m\"><code>C1#m(foo, bar, baz)</code></a>"), result
  end

  def test_convert_CROSSREF_label
    result = @to.convert 'C1@foo'
    assert_equal para("<a href=\"C1.html#class-C1-label-foo\">foo at <code>C1</code></a>"), result

    result = @to.convert 'C1#m@foo'
    assert_equal para("<a href=\"C1.html#method-i-m-label-foo\">foo at <code>C1#m</code></a>"),
                 result
  end

  def test_convert_CROSSREF_label_for_md
    result = @to.convert 'EXAMPLE@foo'
    assert_equal para("<a href=\"EXAMPLE_md.html#label-foo\">foo at <code>EXAMPLE</code></a>"), result
  end

  def test_convert_CROSSREF_label_period
    result = @to.convert 'C1@foo.'
    assert_equal para("<a href=\"C1.html#class-C1-label-foo\">foo at <code>C1</code></a>."), result
  end

  def test_convert_CROSSREF_label_space
    result = @to.convert 'C1@foo+bar'
    assert_equal para("<a href=\"C1.html#class-C1-label-foo+bar\">foo bar at <code>C1</code></a>"),
                 result
  end

  def test_convert_CROSSREF_section
    @c1.add_section 'Section'

    result = @to.convert 'C1@Section'
    assert_equal para("<a href=\"C1.html#Section\">Section at <code>C1</code></a>"), result
  end

  def test_convert_CROSSREF_constant
    result = @to.convert 'C1::CONST'

    assert_equal para("<a href=\"C1.html#CONST\"><code>C1::CONST</code></a>"), result
  end

  def test_convert_RDOCLINK_rdoc_ref
    result = @to.convert 'rdoc-ref:C1'

    assert_equal para("<a href=\"C1.html\"><code>C1</code></a>"), result
  end

  def test_convert_RDOCLINK_rdoc_ref_not_found
    result = nil
    stdout, _ = capture_output do
      result = @to.convert 'rdoc-ref:FOO'
    end

    assert_equal para("FOO"), result
    assert_include stdout, "index.html: `rdoc-ref:FOO` can't be resolved for `FOO`"
  end

  def test_convert_RDOCLINK_rdoc_ref_method
    result = @to.convert 'rdoc-ref:C1#m'

    assert_equal para("<a href=\"C1.html#method-i-m\"><code>C1#m</code></a>"), result
  end

  def test_convert_RDOCLINK_rdoc_ref_method_label
    result = @to.convert 'rdoc-ref:C1#m@foo'

    assert_equal para("<a href=\"C1.html#method-i-m-label-foo\">foo at <code>C1#m</code></a>"),
                 result, 'rdoc-ref:C1#m@foo'
  end

  def test_convert_RDOCLINK_rdoc_ref_method_percent
    m = @c1.add_method RDoc::AnyMethod.new nil, '%'

    result = @to.convert 'rdoc-ref:C1#%'

    assert_equal para("<a href=\"C1.html#method-i-25\"><code>C1#%</code></a>"), result

    m.singleton = true

    result = @to.convert 'rdoc-ref:C1::%'

    assert_equal para("<a href=\"C1.html#method-c-25\"><code>C1::%</code></a>"), result
  end

  def test_convert_RDOCLINK_rdoc_ref_method_escape_html
    m = @c1.add_method RDoc::AnyMethod.new nil, '<<'

    result = @to.convert 'rdoc-ref:C1#<<'

    assert_equal para("<a href=\"C1.html#method-i-3C-3C\"><code>C1#&lt;&lt;</code></a>"), result
    m.singleton = true

    result = @to.convert 'rdoc-ref:C1::<<'

    assert_equal para("<a href=\"C1.html#method-c-3C-3C\"><code>C1::&lt;&lt;</code></a>"), result
  end

  def test_convert_RDOCLINK_rdoc_ref_method_percent_label
    m = @c1.add_method RDoc::AnyMethod.new nil, '%'

    result = @to.convert 'rdoc-ref:C1#%@f'

    assert_equal para("<a href=\"C1.html#method-i-25-label-f\">f at <code>C1#%</code></a>"),
                 result

    m.singleton = true

    result = @to.convert 'rdoc-ref:C1::%@f'

    assert_equal para("<a href=\"C1.html#method-c-25-label-f\">f at <code>C1::%</code></a>"),
                 result
  end

  def test_convert_RDOCLINK_rdoc_ref_label
    result = @to.convert 'rdoc-ref:C1@foo'

    assert_equal para("<a href=\"C1.html#class-C1-label-foo\">foo at <code>C1</code></a>"), result,
                 'rdoc-ref:C1@foo'
  end

  def test_convert_RDOCLINK_rdoc_ref_label_in_current_file
    result = @to.convert 'rdoc-ref:@foo'

    assert_equal para("<a href=\"#label-foo\">foo</a>"), result,
                 'rdoc-ref:@foo'

    result = @to.convert '{Foo}[rdoc-ref:@foo]'

    assert_equal para("<a href=\"#label-foo\">Foo</a>"), result,
                 '{Foo}[rdoc-ref:@foo]'
  end

  def test_gen_url
    assert_equal '<a href="C1.html">Some class</a>',
                 @to.gen_url('rdoc-ref:C1', 'Some class')

    assert_equal '<a href="http://example">HTTP example</a>',
                 @to.gen_url('http://example', 'HTTP example')
  end

  def test_gen_url_rdoc_ref_not_found
    stdout, _ = capture_output do
      @to.gen_url 'rdoc-ref:FOO', 'FOO'
    end

    assert_include stdout, "index.html: `rdoc-ref:FOO` can't be resolved for `FOO`"
  end

  def test_handle_regexp_CROSSREF
    assert_equal "<a href=\"C2/C3.html\"><code>C2::C3</code></a>", REGEXP_HANDLING('C2::C3')
  end

  def test_handle_regexp_CROSSREF_label
    assert_equal "<a href=\"C1.html#method-i-m-label-foo\">foo at <code>C1#m</code></a>",
                 REGEXP_HANDLING('C1#m@foo')
  end

  def test_handle_regexp_CROSSREF_show_hash_false
    @to.show_hash = false

    assert_equal "<a href=\"C1.html#method-i-m\"><code>m</code></a>",
                 REGEXP_HANDLING('#m')
  end

  def test_handle_regexp_CROSSREF_with_arg_looks_like_TIDYLINK
    result = @to.convert 'C1.m[:sym]'

    assert_equal para("<a href=\"C1.html#method-c-m\"><code>C1.m[:sym]</code></a>"), result,
                 'C1.m[:sym]'
  end

  def test_handle_regexp_HYPERLINK_rdoc
    readme = @store.add_file 'README.txt'
    readme.parser = RDoc::Parser::Simple

    @to = RDoc::Markup::ToHtmlCrossref.new @options, 'C2.html', @c2

    link = @to.handle_regexp_HYPERLINK hyper 'C2::C3'

    assert_equal '<a href="C2/C3.html"><code>C2::C3</code></a>', link

    link = @to.handle_regexp_HYPERLINK hyper 'C4'

    assert_equal '<a href="C4.html"><code>C4</code></a>', link

    link = @to.handle_regexp_HYPERLINK hyper 'README.txt'

    assert_equal '<a href="README_txt.html">README.txt</a>', link
  end

  def test_handle_regexp_TIDYLINK_rdoc
    readme = @store.add_file 'README.txt'
    readme.parser = RDoc::Parser::Simple

    @to = RDoc::Markup::ToHtmlCrossref.new @options, 'C2.html', @c2

    link = @to.handle_regexp_TIDYLINK tidy 'C2::C3'

    assert_equal '<a href="C2/C3.html">tidy</a>', link

    link = @to.handle_regexp_TIDYLINK tidy 'C4'

    assert_equal '<a href="C4.html">tidy</a>', link

    link = @to.handle_regexp_TIDYLINK tidy 'C1#m'

    assert_equal '<a href="C1.html#method-i-m">tidy</a>', link

    link = @to.handle_regexp_TIDYLINK tidy 'README.txt'

    assert_equal '<a href="README_txt.html">tidy</a>', link
  end

  def test_handle_regexp_TIDYLINK_label
    link = @to.handle_regexp_TIDYLINK tidy 'C1#m@foo'

    assert_equal "<a href=\"C1.html#method-i-m-label-foo\">tidy</a>",
                 link, 'C1#m@foo'
  end

  def test_convert_TIDYLINK_markdown_with_crossrefs
    markdown = RDoc::Markdown.parse('[Link to `C1` and `Foo` and `\\C1` and `Bar`](https://example.com)')

    result = markdown.accept(@to)

    assert_equal para('<a href="https://example.com">Link to <code>C1</code> and <code>Foo</code> and <code>\\C1</code> and <code>Bar</code></a>'), result
  end

  def test_to_html_CROSSREF_email
    @options.hyperlink_all = false

    @to = RDoc::Markup::ToHtmlCrossref.new @options, 'index.html', @c1

    result = @to.to_html 'first.last@example.com'

    assert_equal 'first.last@example.com', result
  end

  def test_to_html_CROSSREF_email_hyperlink_all
    result = @to.to_html 'first.last@example.com'

    assert_equal 'first.last@example.com', result
  end

  def test_link
    assert_equal 'n', @to.link('n', 'n')

    assert_equal '<a href="C1.html#method-c-m"><code>m</code></a>', @to.link('m', 'm')
  end

  def test_link_for_method_traverse
    @to = RDoc::Markup::ToHtmlCrossref.new @options, 'C2.html', @c9
    assert_equal '<a href="C9/A.html#method-i-foo"><code>C9::B#foo</code></a>', @to.link('C9::B#foo', 'C9::B#foo')
  end

  def test_link_class_method_full
    assert_equal '<a href="Parent.html#method-c-m"><code>Parent::m</code></a>',
                 @to.link('Parent::m', 'Parent::m')
  end

  def test_convert_CROSSREF_file_path_not_linked
    # Must use hyperlink_all = false for file path pattern to match the right regex
    @options.hyperlink_all = false
    @to = RDoc::Markup::ToHtmlCrossref.new @options, 'index.html', @c1

    file = @store.add_file 'lib/foo/bar.rb'
    file.parser = RDoc::Parser::Ruby

    # Verify the file IS resolvable via rdoc-ref (sanity check)
    result = @to.convert 'rdoc-ref:lib/foo/bar.rb'
    assert_equal para('<a href="lib/foo/bar_rb.html">lib/foo/bar.rb</a>'), result

    # But file paths inside backticks should NOT be converted to links
    result = @to.convert '+lib/foo/bar.rb+'
    assert_equal para('<code>lib/foo/bar.rb</code>'), result
  end

  def para(text)
    "\n<p>#{text}</p>\n"
  end

  def REGEXP_HANDLING(text)
    @to.handle_regexp_CROSSREF regexp_handling text
  end

  def hyper(reference)
    RDoc::Markup::RegexpHandling.new 0, "rdoc-ref:#{reference}"
  end

  def regexp_handling(text)
    RDoc::Markup::RegexpHandling.new 0, text
  end

  def tidy(reference)
    RDoc::Markup::RegexpHandling.new 0, "{tidy}[rdoc-ref:#{reference}]"
  end

end
