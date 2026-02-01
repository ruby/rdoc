# frozen_string_literal: true
require_relative '../helper'

class RDocGeneratorAlikiMarkdownTest < RDoc::TestCase

  def setup
    super

    @lib_dir = "#{@pwd}/lib"
    $LOAD_PATH.unshift @lib_dir

    @options = RDoc::Options.new
    @options.option_parser = OptionParser.new

    @tmpdir = File.join Dir.tmpdir, "test_rdoc_generator_aliki_markdown_#{$$}"
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
  end

  def teardown
    super

    $LOAD_PATH.shift
    Dir.chdir @pwd
    FileUtils.rm_rf @tmpdir
  end

  def test_generates_markdown_for_class_with_rdoc_markup
    top_level = @store.add_file 'lib/example.rb'
    top_level.parser = RDoc::Parser::Ruby

    klass = top_level.add_class RDoc::NormalClass, 'Example'
    klass.add_comment <<~RDOC, top_level
      This is an example class.

      It does example things.
    RDOC

    meth = RDoc::AnyMethod.new nil, 'foo'
    meth.call_seq = "foo(bar) -> String"
    meth.comment = RDoc::Comment.new("Does foo things.", top_level)
    klass.add_method meth

    @store.complete :private
    @g.generate

    assert_file 'Example.md'

    content = File.read('Example.md')

    assert_match(/^# Example$/, content)
    assert_match(/This is an example class/, content)
    assert_match(/^## Public Instance Methods$/, content)
    assert_match(/^### foo$/, content)
    assert_match(/^```\nfoo\(bar\) -> String\n```$/, content)
    assert_match(/Does foo things/, content)
  end

  def test_generates_markdown_for_class_with_markdown_markup
    top_level = @store.add_file 'lib/example.rb'
    top_level.parser = RDoc::Parser::Ruby

    klass = top_level.add_class RDoc::NormalClass, 'MarkdownExample'

    comment = RDoc::Comment.new <<~MD, top_level
      This is a **bold** example class.

      It has `code` in it.
    MD
    comment.format = 'markdown'
    klass.add_comment comment, top_level

    @store.complete :private
    @g.generate

    assert_file 'MarkdownExample.md'

    content = File.read('MarkdownExample.md')

    assert_match(/^# MarkdownExample$/, content)
    assert_match(/\*\*bold\*\*/, content)
    assert_match(/`code`/, content)
  end

  def test_generates_markdown_for_standalone_rdoc_page
    readme = @store.add_file 'README.rdoc'
    readme.parser = RDoc::Parser::Simple
    readme.comment = RDoc::Comment.new <<~RDOC, readme
      = My Project

      This is the readme.

      == Installation

      Run the installer.
    RDOC

    @store.complete :private
    @g.generate

    # README.rdoc generates README_rdoc.html, so markdown should be README_rdoc.md
    md_file = Dir.glob('*.md').find { |f| f.include?('README') }
    assert md_file, "Expected a README markdown file to be generated"

    content = File.read(md_file)

    assert_match(/My Project/, content)
    assert_match(/Installation/, content)
  end

  def test_generates_markdown_for_standalone_md_page
    guide = @store.add_file 'GUIDE.md'
    guide.parser = RDoc::Parser::Markdown

    comment = RDoc::Comment.new <<~MD, guide
      # User Guide

      Welcome to the **user guide**.

      ## Getting Started

      Here's how to start.
    MD
    comment.format = 'markdown'
    guide.comment = comment

    @store.complete :private
    @g.generate

    md_file = Dir.glob('*.md').find { |f| f.include?('GUIDE') }
    assert md_file, "Expected a GUIDE markdown file to be generated"

    content = File.read(md_file)

    assert_match(/User Guide/, content)
    assert_match(/\*\*user guide\*\*/, content)
    assert_match(/Getting Started/, content)
  end

  def test_generates_llms_txt
    @options.title = "My Ruby Project"

    top_level = @store.add_file 'lib/example.rb'
    top_level.parser = RDoc::Parser::Ruby
    klass = top_level.add_class RDoc::NormalClass, 'Example'
    klass.add_comment "An example class.", top_level

    readme = @store.add_file 'README.rdoc'
    readme.parser = RDoc::Parser::Simple
    readme.comment = RDoc::Comment.new "Project readme.", readme

    @store.complete :private
    @g.generate

    assert_file 'llms.txt'

    content = File.read('llms.txt')

    # Check llmstxt.org format
    assert_match(/^# My Ruby Project$/, content)
    assert_match(/\[Example\]\(Example\.md\)/, content)
    assert_match(/\[README/, content)
  end

  def test_method_signatures_in_plain_code_blocks
    top_level = @store.add_file 'lib/example.rb'
    top_level.parser = RDoc::Parser::Ruby

    klass = top_level.add_class RDoc::NormalClass, 'MultiSig'

    meth = RDoc::AnyMethod.new nil, 'transform'
    meth.call_seq = <<~CALLSEQ.strip
      transform(value) -> Result
      transform(value) { |v| ... } -> Result
    CALLSEQ
    klass.add_method meth

    @store.complete :private
    @g.generate

    content = File.read('MultiSig.md')

    # Should have plain code block (no language specifier)
    assert_match(/^```\ntransform\(value\) -> Result\ntransform\(value\) \{ \|v\| \.\.\. \} -> Result\n```$/m, content)

    # Should NOT have ```ruby
    refute_match(/```ruby/, content)
  end

  def test_visibility_and_method_ordering
    top_level = @store.add_file 'lib/example.rb'
    top_level.parser = RDoc::Parser::Ruby

    klass = top_level.add_class RDoc::NormalClass, 'Ordered'

    # Add methods in random order (with comments so they display)
    # Note: visibility must be set after add_method, as add_method overrides it
    private_instance = RDoc::AnyMethod.new nil, 'private_method'
    private_instance.comment = RDoc::Comment.new("A private method.", top_level)
    klass.add_method private_instance

    public_instance = RDoc::AnyMethod.new nil, 'public_method'
    public_instance.comment = RDoc::Comment.new("A public method.", top_level)
    klass.add_method public_instance

    public_class = RDoc::AnyMethod.new nil, 'class_method', singleton: true
    public_class.comment = RDoc::Comment.new("A class method.", top_level)
    klass.add_method public_class

    protected_instance = RDoc::AnyMethod.new nil, 'protected_method'
    protected_instance.comment = RDoc::Comment.new("A protected method.", top_level)
    klass.add_method protected_instance

    # Set visibility after adding methods
    klass.set_visibility_for(['private_method'], :private)
    klass.set_visibility_for(['protected_method'], :protected)

    @store.complete :private
    @g.generate

    content = File.read('Ordered.md')

    # Class methods should come before instance methods
    class_methods_pos = content.index('## Public Class Methods')
    public_instance_pos = content.index('## Public Instance Methods')
    protected_instance_pos = content.index('## Protected Instance Methods')
    private_instance_pos = content.index('## Private Instance Methods')

    assert class_methods_pos, "Should have Public Class Methods section"
    assert public_instance_pos, "Should have Public Instance Methods section"
    assert protected_instance_pos, "Should have Protected Instance Methods section"
    assert private_instance_pos, "Should have Private Instance Methods section"

    # Verify order: class methods < public instance < protected instance < private instance
    assert class_methods_pos < public_instance_pos, "Class methods should come before instance methods"
    assert public_instance_pos < protected_instance_pos, "Public should come before protected"
    assert protected_instance_pos < private_instance_pos, "Protected should come before private"
  end
end
