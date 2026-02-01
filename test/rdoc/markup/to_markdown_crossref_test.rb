# frozen_string_literal: true
require_relative '../xref_test_case'

class RDocMarkupToMarkdownCrossrefTest < XrefTestCase

  def setup
    super

    @options.hyperlink_all = true
    @options.warn_missing_rdoc_ref = true

    @to = RDoc::Markup::ToMarkdownCrossref.new @options, 'index.md', @c1
  end

  def test_convert_CROSSREF_class
    result = @to.convert 'C2'
    assert_equal para("[`C2`](C2.md)"), result
  end

  def test_convert_CROSSREF_class_in_tt
    result = @to.convert '+C2+'
    assert_equal para("[`C2`](C2.md)"), result
  end

  def test_convert_CROSSREF_method
    result = @to.convert 'C1#m(foo, bar, baz)'
    assert_equal para("[`C1#m(foo, bar, baz)`](C1.md#method-i-m)"), result
  end

  def test_convert_CROSSREF_label
    result = @to.convert 'C2@foo'
    assert_equal para("[foo at `C2`](C2.md#class-c2-foo)"), result
  end

  def test_convert_CROSSREF_label_space
    result = @to.convert 'C2@foo+bar'
    assert_equal para("[foo bar at `C2`](C2.md#class-c2-foo-bar)"), result
  end

  def test_convert_CROSSREF_section
    @c2.add_section 'Section'

    result = @to.convert 'C2@Section'
    assert_equal para("[Section at `C2`](C2.md#section)"), result
  end

  def test_convert_CROSSREF_constant
    result = @to.convert 'C1::CONST'
    assert_equal para("[`C1::CONST`](C1.md#CONST)"), result
  end

  def test_convert_RDOCLINK_rdoc_ref
    result = @to.convert 'rdoc-ref:C2'
    assert_equal para("[`C2`](C2.md)"), result
  end

  def test_convert_RDOCLINK_rdoc_ref_not_found
    result = nil
    stdout, _ = capture_output do
      result = @to.convert 'rdoc-ref:FOO'
    end

    assert_equal para("FOO"), result
    assert_include stdout, "index.md: `rdoc-ref:FOO` can't be resolved for `FOO`"
  end

  def test_convert_RDOCLINK_rdoc_ref_method
    result = @to.convert 'rdoc-ref:C1#m'
    assert_equal para("[`C1#m`](C1.md#method-i-m)"), result
  end

  def test_html_to_md_path_conversion
    result = @to.convert 'C2::C3'
    assert_match %r{C2/C3\.md}, result
  end

  def test_handle_TT_with_crossref
    result = @to.convert '<tt>C2</tt>'
    assert_equal para("[`C2`](C2.md)"), result
  end

  def test_handle_TT_without_crossref
    @options.hyperlink_all = false
    formatter = RDoc::Markup::ToMarkdownCrossref.new(@options, 'C9.md', @c9_b)

    result = formatter.convert '<tt>.bar.hello()</tt>'
    assert_equal para('<code>.bar.hello()</code>'), result
  end

  def test_suppress_link_inside_tidylink_label
    result = @to.convert '{rdoc-ref:C2 C2 http://example.com}[url]'
    assert_equal para("[rdoc-ref:C2 C2 http://example.com](url)"), result
  end

  def test_self_referential_link_suppressed
    # When context is @c1 and we reference C1 via rdoc-ref, it should be plain text not a link
    result = @to.convert 'rdoc-ref:C1'
    assert_equal para("`C1`"), result
  end

  def test_self_referential_crossref_suppressed
    # When context is @c1 and we auto-crossref C1, it should be plain text not a link
    result = @to.convert 'C1'
    assert_equal para("`C1`"), result
  end

  def test_unresolved_reference_returns_plain_text
    result = @to.convert 'NonExistentClass'
    assert_equal para("NonExistentClass"), result
  end

  def test_gen_url_rdoc_ref
    # C2 is not the context, so it should generate a link
    assert_equal '[`C2`](C2.md)',
                 @to.gen_url('rdoc-ref:C2', 'C2')
  end

  def test_gen_url_rdoc_ref_self
    # C1 is the context, so self-reference should be suppressed
    assert_equal '`C1`',
                 @to.gen_url('rdoc-ref:C1', 'C1')
  end

  def test_gen_url_http
    assert_equal '[HTTP example](http://example)',
                 @to.gen_url('http://example', 'HTTP example')
  end

  def test_handle_regexp_CROSSREF_show_hash_false
    @to.show_hash = false

    assert_equal "[`m`](C1.md#method-i-m)",
                 REGEXP_HANDLING('#m')
  end

  def test_link
    assert_equal 'n', @to.link('n', 'n')

    assert_equal '[`m`](C1.md#method-c-m)', @to.link('m', 'm')
  end

  def test_convert_CROSSREF_ignored_excluded_words
    @options.autolink_excluded_words = ['C2']

    result = @to.convert 'C2'
    assert_equal para("C2"), result

    # Explicit linking with rdoc-ref is not ignored
    result = @to.convert 'Constant[rdoc-ref:C2]'
    assert_equal para("[Constant](C2.md)"), result
  end

  private

  def para(text)
    "#{text}\n"
  end

  def REGEXP_HANDLING(text)
    @to.handle_regexp_CROSSREF text
  end
end
