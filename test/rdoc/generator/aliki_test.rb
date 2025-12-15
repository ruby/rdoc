# frozen_string_literal: true
require_relative '../helper'

class RDocGeneratorAlikiTest < RDoc::TestCase

  def setup
    super

    @lib_dir = "#{@pwd}/lib"
    $LOAD_PATH.unshift @lib_dir # ensure we load from this RDoc

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
    @meth_bang = RDoc::AnyMethod.new nil, 'method!'
    @meth_with_html_tag_yield = RDoc::AnyMethod.new nil, 'method_with_html_tag_yield'
    @meth_with_html_tag_yield.block_params = '%<<script>alert("atui")</script>>, yield_arg'
    @attr = RDoc::Attr.new nil, 'attr', 'RW', ''

    @klass.add_method @meth
    @klass.add_method @meth_bang
    @klass.add_method @meth_with_html_tag_yield
    @klass.add_attribute @attr

    @ignored = @top_level.add_class RDoc::NormalClass, 'Ignored'
    @ignored.ignore

    @store.complete :private

    @object      = @store.find_class_or_module 'Object'
    @klass_alias = @store.find_class_or_module 'Klass::A'
  end

  def teardown
    super

    $LOAD_PATH.shift
    Dir.chdir @pwd
    FileUtils.rm_rf @tmpdir
  end

  def test_generate
    top_level = @store.add_file 'file.rb'
    top_level.add_class @klass.class, @klass.name
    @klass.add_class RDoc::NormalClass, 'Inner'
    @klass.add_comment <<~RDOC, top_level
    = Heading 1
    Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
    == Heading 1.1
    tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
    === Heading 1.1.1
    quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
    ==== Heading 1.1.1.1
    consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
    == Heading 1.2
    cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat
    == Heading 1.3
    non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
    === Heading 1.3.1
    etc etc...
    RDOC

    @g.generate

    assert_file 'index.html'
    assert_file 'Object.html'
    assert_file 'Klass.html'
    assert_file 'Klass/Inner.html'
    assert_file 'js/search_index.js'

    # Aliki has a simpler asset structure than Darkfish (no fonts)
    assert_file 'css/rdoc.css'
    assert_file 'js/aliki.js'

    encoding = Regexp.escape Encoding::UTF_8.name

    assert_match %r%<meta charset="#{encoding}">%, File.binread('index.html')
    assert_match %r%<meta charset="#{encoding}">%, File.binread('Object.html')

    refute_match(/Ignored/, File.binread('index.html'))
  end

  def test_generate_index_with_main_page
    top_level = @store.add_file 'file.rb'
    top_level.comment = <<~RDOC
    = Heading 1
    Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
    == Heading 1.1
    tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
    === Heading 1.1.1
    quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
    ==== Heading 1.1.1.1
    consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
    == Heading 1.2
    cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat
    == Heading 1.3
    non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
    === Heading 1.3.1
    etc etc...
    RDOC

    @options.main_page = 'file.rb'
    @options.title = 'My awesome Ruby project'

    @g.generate

    assert_file 'index.html'
    assert_file 'js/search_index.js'

    assert_file 'css/rdoc.css'
  end

  def test_generate_index_without_main_page
    top_level = @store.add_file 'file.rb'
    top_level.comment = <<~RDOC
    = Heading 1
    Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
    == Heading 1.1
    tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
    === Heading 1.1.1
    quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
    ==== Heading 1.1.1.1
    consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
    == Heading 1.2
    cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat
    == Heading 1.3
    non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
    === Heading 1.3.1
    etc etc...
    RDOC

    @options.title = 'My awesome Ruby project'

    @g.generate

    assert_file 'index.html'
    assert_file 'js/search_index.js'

    assert_file 'css/rdoc.css'
  end

  def test_generate_page
    @store.add_file 'outer.rdoc', parser: RDoc::Parser::Simple
    @store.add_file 'outer/inner.rdoc', parser: RDoc::Parser::Simple
    @g.generate
    assert_file 'outer_rdoc.html'
    assert_file 'outer/inner_rdoc.html'
  end

  def test_generate_dry_run
    @g.dry_run = true
    top_level = @store.add_file 'file.rb'
    top_level.add_class @klass.class, @klass.name

    @g.generate

    refute_file 'index.html'
    refute_file 'Object.html'
  end

  def test_generate_static
    FileUtils.mkdir_p 'dir/images'
    FileUtils.touch 'dir/images/image.png'
    FileUtils.mkdir_p 'file'
    FileUtils.touch 'file/file.txt'

    @options.static_path = [
      File.expand_path('dir'),
      File.expand_path('file/file.txt'),
    ]

    @g.generate

    assert_file 'images/image.png'
    assert_file 'file.txt'
  end

  def test_generate_static_dry_run
    FileUtils.mkdir 'static'
    FileUtils.touch 'static/image.png'

    @options.static_path = [File.expand_path('static')]
    @g.dry_run = true

    @g.generate

    refute_file 'image.png'
  end

  def test_setup
    @g.setup

    assert_equal [@klass_alias, @ignored, @klass, @object],
                 @g.classes.sort_by { |klass| klass.full_name }
    assert_equal [@top_level],                           @g.files
    assert_equal [@meth, @meth, @meth_bang, @meth_bang, @meth_with_html_tag_yield, @meth_with_html_tag_yield], @g.methods
    assert_equal [@klass_alias, @klass, @object], @g.modsort
  end

  def test_template_for
    classpage = Pathname.new @options.template_dir + 'class.rhtml'

    template = @g.send(:template_for, classpage, true, RDoc::ERBIO)
    assert_kind_of RDoc::ERBIO, template

    assert_same template, @g.send(:template_for, classpage)
  end

  def test_template_for_dry_run
    classpage = Pathname.new @options.template_dir + 'class.rhtml'

    template = @g.send(:template_for, classpage, true, ERB)
    assert_kind_of ERB, template

    assert_same template, @g.send(:template_for, classpage)
  end

  def test_generated_method_with_html_tag_yield
    top_level = @store.add_file 'file.rb'
    top_level.add_class @klass.class, @klass.name

    @g.generate

    path = File.join @tmpdir, 'A.html'

    f = open(path)
    internal_file = f.read
    method_name_index = internal_file.index('<span class="method-name">method_with_html_tag_yield</span>')
    last_of_method_name_index = method_name_index + internal_file[method_name_index..-1].index('<div class="method-description">') - 1
    method_name = internal_file[method_name_index..last_of_method_name_index]
    f.close

    assert_includes method_name, '{ |%&lt;&lt;script&gt;alert(&quot;atui&quot;)&lt;/script&gt;&gt;, yield_arg| ... }'
  end

  def test_template_stylesheets
    css = Tempfile.create(%W'hoge .css', Dir.mktmpdir('tmp', '.'))
    File.write(css, '')
    css.close
    base = File.basename(css)
    refute_file(base)

    @options.template_stylesheets << css

    @g.generate

    assert_file base
    # Aliki uses asset_rel_prefix and includes version in query string
    assert_match(/href="\.\/#{Regexp.escape(base)}\?v=#{Regexp.escape(RDoc::VERSION)}"/, File.binread('index.html'))
  end

  def test_html_lang
    @g.generate

    content = File.binread("index.html")
    assert_include(content, '<html lang="en">')
  end

  def test_html_lang_from_locale
    @options.locale = RDoc::I18n::Locale.new 'ja'
    @g.generate

    content = File.binread("index.html")
    assert_include(content, '<html lang="ja">')
  end

  def test_title
    title = "RDoc Test".freeze
    @options.title = title
    @g.generate

    assert_main_title(File.binread('index.html'), title)
  end

  def test_title_escape
    title = %[<script>alert("RDoc")</script>].freeze
    @options.title = title
    @g.generate

    assert_main_title(File.binread('index.html'), title)
  end

  def test_meta_tags_for_index
    @options.title = "My awesome Ruby project"
    @g.generate

    content = File.binread("index.html")

    assert_include(content, '<meta name="keywords" content="ruby,documentation,My awesome Ruby project">')
    assert_include(content, '<meta name="description" content="Documentation for My awesome Ruby project">')
  end

  def test_meta_tags_for_classes
    top_level = @store.add_file("file.rb")
    top_level.add_class(@klass.class, @klass.name)
    inner = @klass.add_class(RDoc::NormalClass, "Inner")
    inner.add_comment("This is a normal class. It is fully documented.", top_level)

    @g.generate

    content = File.binread("Klass/Inner.html")
    # Aliki formats meta tags across multiple lines
    assert_match(/name="keywords"\s+content="ruby,class,Klass::Inner"/, content)
    assert_match(/name="description"\s+content="class Klass::Inner: This is a normal class\. It is fully documented\."/, content)
  end

  def test_canonical_url_for_index
    @store.options.canonical_root = @options.canonical_root = "https://docs.ruby-lang.org/en/master/"
    @g.generate

    content = File.binread("index.html")

    assert_include(content, '<link rel="canonical" href="https://docs.ruby-lang.org/en/master/">')
  end

  def test_canonical_url_for_classes
    top_level = @store.add_file("file.rb")
    top_level.add_class(@klass.class, @klass.name)
    @klass.add_class(RDoc::NormalClass, "Inner")

    @store.options.canonical_root = @options.canonical_root = "https://docs.ruby-lang.org/en/master/"
    @g.generate

    content = File.binread("Klass/Inner.html")

    assert_include(content, '<link rel="canonical" href="https://docs.ruby-lang.org/en/master/Klass/Inner.html">')
  end

  def assert_main_title(content, title)
    title = CGI.escapeHTML(title)
    assert_equal(title, content[%r[<title>(.*?)<\/title>]im, 1])
    assert_include(content[%r[<main\s[^<>]*+>\s*(.*?)</main>]im, 1], title)
  end
end
