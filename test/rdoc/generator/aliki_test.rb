# frozen_string_literal: true
require_relative '../helper'

class RDocGeneratorAlikiTest < RDoc::TestCase

  def setup
    super

    @lib_dir = "#{@pwd}/lib"
    $LOAD_PATH.unshift @lib_dir

    @options = RDoc::Options.new
    @options.option_parser = OptionParser.new

    @tmpdir = File.join Dir.tmpdir, "test_rdoc_generator_aliki_#{$$}"
    FileUtils.mkdir_p @tmpdir
    Dir.chdir @tmpdir
    @options.op_dir = @tmpdir
    @options.generator = RDoc::Generator::Aliki

    $LOAD_PATH.each do |path|
      aliki_dir = File.join path, 'rdoc/generator/template/aliki/'
      next unless File.directory? aliki_dir
      @options.template_dir = aliki_dir
      break
    end

    @rdoc.options = @options

    @g = @options.generator.new @store, @options
    @rdoc.generator = @g

    @top_level = @store.add_file 'file.rb'
    @top_level.parser = RDoc::Parser::Ruby
    @klass = @top_level.add_class RDoc::NormalClass, 'Klass'

    @alias_constant = RDoc::Constant.new 'A', nil, ''
    @alias_constant.record_location @top_level

    @top_level.add_constant @alias_constant

    @klass.add_module_alias @klass, @klass.name, @alias_constant, @top_level

    @meth = RDoc::AnyMethod.new nil, 'method'
    @meth_with_html_tag_yield = RDoc::AnyMethod.new nil, 'method_with_html_tag_yield'
    @meth_with_html_tag_yield.block_params = '%<<script>alert("atui")</script>>, yield_arg'

    @klass.add_method @meth
    @klass.add_method @meth_with_html_tag_yield

    @store.complete :private
  end

  def teardown
    super

    $LOAD_PATH.shift
    Dir.chdir @pwd
    FileUtils.rm_rf @tmpdir
  end

  def test_template_dir
    assert_kind_of RDoc::Generator::Aliki, @g
    assert_match %r{/template/aliki/?$}, @g.template_dir.to_s
  end

  def test_aliased_classes_full_name
    @g.generate

    assert_equal(%w[Klass Klass::A Object], @g.classes.map(&:full_name).sort)
  end

  def test_write_style_sheet_copies_css_and_js_only
    @g.generate

    # Aliki should have these assets
    assert_file 'css/rdoc.css'
    assert_file 'js/aliki.js'
    assert_file 'js/search_controller.js'
    assert_file 'js/search_navigation.js'
    assert_file 'js/search_ranker.js'
    assert_file 'js/theme-toggle.js'
    assert_file 'js/c_highlighter.js'
  end

  # Aliki-specific: verify version query strings on asset references
  def test_asset_version_query_strings
    @g.generate

    content = File.binread('index.html')

    # CSS should have version query string
    assert_match %r{css/rdoc\.css\?v=#{Regexp.escape(RDoc::VERSION)}}, content

    # JS files should have version query strings
    assert_match %r{js/aliki\.js\?v=#{Regexp.escape(RDoc::VERSION)}}, content
    assert_match %r{js/search_controller\.js\?v=#{Regexp.escape(RDoc::VERSION)}}, content
    assert_match %r{js/search_navigation\.js\?v=#{Regexp.escape(RDoc::VERSION)}}, content
    assert_match %r{js/search_ranker\.js\?v=#{Regexp.escape(RDoc::VERSION)}}, content
    assert_match %r{js/search_data\.js\?v=#{Regexp.escape(RDoc::VERSION)}}, content
    assert_match %r{js/theme-toggle\.js\?v=#{Regexp.escape(RDoc::VERSION)}}, content
  end

  def test_open_graph_meta_tags_for_index
    @options.title = "My Ruby Project"
    @g.generate

    content = File.binread('index.html')

    assert_match %r{<meta property="og:type" content="website">}, content
    assert_match %r{<meta property="og:title" content="My Ruby Project">}, content
    assert_match %r{<meta\s+property="og:description"\s+content="API documentation for My Ruby Project}m, content
  end

  def test_open_graph_meta_tags_for_class
    top_level = @store.add_file 'file.rb'
    top_level.add_class @klass.class, @klass.name
    @klass.add_comment "A useful class for doing things.", top_level

    @g.generate

    content = File.binread('Klass.html')

    assert_match %r{<meta property="og:title" content=}, content
    assert_match %r{<meta property="og:description" content="A useful class for doing things\.">}, content
  end

  # Aliki-specific: Twitter meta tags
  def test_twitter_meta_tags_for_index
    @options.title = "My Ruby Project"
    @g.generate

    content = File.binread('index.html')

    assert_match %r{<meta name="twitter:card" content="summary">}, content
    assert_match %r{<meta name="twitter:title" content="My Ruby Project">}, content
    assert_match %r{<meta\s+name="twitter:description"\s+content="API documentation for My Ruby Project}m, content
  end

  def test_twitter_meta_tags_for_class
    top_level = @store.add_file 'file.rb'
    top_level.add_class @klass.class, @klass.name
    @klass.add_comment "A useful class for doing things.", top_level

    @g.generate

    content = File.binread('Klass.html')

    assert_match %r{<meta name="twitter:card" content="summary">}, content
    assert_match %r{<meta name="twitter:description" content="A useful class for doing things\.">}, content
  end

  def test_meta_tags_multiline_format
    top_level = @store.add_file 'file.rb'
    top_level.add_class @klass.class, @klass.name
    inner = @klass.add_class RDoc::NormalClass, 'Inner'
    inner.add_comment "This is a normal class.", top_level

    @g.generate

    content = File.binread('Klass/Inner.html')

    # Aliki formats meta tags across multiple lines
    assert_match %r{name="keywords"\s+content="ruby,class,Klass::Inner"}m, content
    assert_match %r{name="description"\s+content="class Klass::Inner: This is a normal class\."}m, content
  end

  def test_template_stylesheets_with_version
    css = Tempfile.create(%W[custom .css], Dir.mktmpdir('tmp', '.'))
    File.write(css, '')
    css.close
    base = File.basename(css)

    @options.template_stylesheets << css

    @g.generate

    assert_file base
    # Aliki includes version in query string for custom stylesheets too
    assert_match %r{href="\./#{Regexp.escape(base)}\?v=#{Regexp.escape(RDoc::VERSION)}"}, File.binread('index.html')
  end

  def test_generated_method_with_html_tag_yield_escapes_xss
    top_level = @store.add_file 'file.rb'
    top_level.add_class @klass.class, @klass.name

    @g.generate

    content = File.binread('Klass.html')

    # Script tags in yield params should be escaped
    assert_match %r{%&lt;&lt;script&gt;alert\(&quot;atui&quot;\)&lt;/script&gt;&gt;}, content
    refute_match %r{<script>alert\("atui"\)</script>}, content
  end

  def test_title_escape_prevents_xss
    @options.title = '<script>alert("xss")</script>'
    @g.generate

    content = File.binread('index.html')

    # Title should be HTML escaped
    assert_match %r{<title>&lt;script&gt;alert\(&quot;xss&quot;\)&lt;/script&gt;</title>}, content
    refute_match %r{<title><script>alert}, content
  end

  def test_generate_does_not_create_page_file_for_main_page
    top_level = @store.add_file("README.rdoc", parser: RDoc::Parser::Simple)
    top_level.comment = "= Main Page\nThis is the main page content."

    other_page = @store.add_file("OTHER.rdoc", parser: RDoc::Parser::Simple)
    other_page.comment = "= Other Page\nThis is another page."

    @options.main_page = "README.rdoc"

    @g.generate

    assert_file "index.html"
    refute File.exist?("README_rdoc.html"), "main_page should not be generated as a separate page"
    assert_file "OTHER_rdoc.html"
  end

  def test_generate_sidebar_excludes_main_page
    top_level = @store.add_file("README.rdoc", parser: RDoc::Parser::Simple)
    top_level.comment = "= Main Page\nThis is the main page content."

    other_page = @store.add_file("OTHER.rdoc", parser: RDoc::Parser::Simple)
    other_page.comment = "= Other Page\nThis is another page."

    @options.main_page = "README.rdoc"
    @store.options.main_page = "README.rdoc"

    @g.generate

    other_html = File.binread("OTHER_rdoc.html")

    # The sidebar should not include the main_page at all
    assert_not_match %r{href="[^"]*README_rdoc\.html"}, other_html
    # But OTHER should be listed
    assert_match %r{href="[^"]*OTHER_rdoc\.html"}, other_html
  end

  def test_generate_cross_reference_to_main_page_links_to_index_html
    readme = @store.add_file("README.rdoc", parser: RDoc::Parser::Simple)
    readme.comment = "= Main Page\nThis is the main page content."

    other_page = @store.add_file("OTHER.rdoc", parser: RDoc::Parser::Simple)
    other_page.comment = "= Other Page\nSee README.rdoc for more info."

    @options.main_page = "README.rdoc"
    @store.options.main_page = "README.rdoc"

    @g.generate

    other_html = File.binread("OTHER_rdoc.html")

    # Cross-reference to main_page should point to index.html
    assert_match %r{<a href="[^"]*index\.html">README\.rdoc</a>}, other_html
    assert_not_match %r{<a href="[^"]*README_rdoc\.html">}, other_html
  end

  def test_generate
    @klass.add_class RDoc::NormalClass, 'Inner'
    @klass.add_comment "Test class documentation", @top_level

    @g.generate

    # Core HTML files
    assert_file 'index.html'
    assert_file 'Klass.html'
    assert_file 'Klass/Inner.html'

    # Aliki assets
    assert_file 'js/search_data.js'
    assert_file 'css/rdoc.css'
    assert_file 'js/aliki.js'

    # Verify HTML structure
    index = File.binread('index.html')
    assert_match %r{<html lang="en">}, index
    assert_match %r{<body role="document"}, index
    assert_match %r{<nav id="navigation" role="navigation" hidden>}, index
    assert_match %r{<main role="main">}, index
  end

  def test_canonical_url
    @klass.add_class RDoc::NormalClass, 'Inner'
    @store.options.canonical_root = @options.canonical_root = "https://example.com/docs/"
    @g.generate

    index_content = File.binread('index.html')
    assert_include index_content, '<link rel="canonical" href="https://example.com/docs/">'

    # Open Graph should also include canonical URL
    assert_match %r{<meta property="og:url" content="https://example\.com/docs/">}, index_content

    inner_content = File.binread('Klass/Inner.html')
    assert_include inner_content, '<link rel="canonical" href="https://example.com/docs/Klass/Inner.html">'
  end

  def test_dry_run_creates_no_files
    @g.dry_run = true

    @g.generate

    refute_file 'index.html'
    refute_file 'css/rdoc.css'
    refute_file 'js/aliki.js'
  end

  # Test locale affects html lang attribute
  def test_html_lang_from_locale
    @options.locale = RDoc::I18n::Locale.new 'ja'
    @g.generate

    content = File.binread('index.html')
    assert_include content, '<html lang="ja">'
  end
end
