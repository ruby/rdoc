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
    assert_match(/\[Example\]\(Example\.html\)/, content)
    assert_match(/\[README/, content)
  end

  def test_generates_llms_full_txt
    @options.title = "My Ruby Project"

    top_level = @store.add_file 'lib/example.rb'
    top_level.parser = RDoc::Parser::Ruby
    klass = top_level.add_class RDoc::NormalClass, 'Example'
    klass.add_comment "An example class.", top_level

    meth = RDoc::AnyMethod.new nil, 'foo'
    meth.comment = RDoc::Comment.new("Does foo things.", top_level)
    klass.add_method meth

    readme = @store.add_file 'README.rdoc'
    readme.parser = RDoc::Parser::Simple
    readme.comment = RDoc::Comment.new "Project readme content.", readme

    @store.complete :private
    @g.generate

    assert_file 'llms-full.txt'

    content = File.read('llms-full.txt')

    # Should start with project title
    assert_match(/^# My Ruby Project$/, content)

    # Should contain class documentation
    assert_match(/^# Example$/, content)
    assert_match(/An example class/, content)
    assert_match(/Does foo things/, content)

    # Should contain page documentation
    assert_match(/Project readme content/, content)

    # Sections should be separated by ---
    assert_match(/^---$/, content)

    # Pages should come before classes
    readme_pos = content.index('Project readme content')
    class_pos = content.index('# Example')
    assert readme_pos < class_pos, "Pages should come before class documentation"
  end

  def test_llms_txt_has_meaningful_descriptions
    @options.title = "My Ruby Project"

    top_level = @store.add_file 'lib/example.rb'
    top_level.parser = RDoc::Parser::Ruby
    klass = top_level.add_class RDoc::NormalClass, 'Example'
    klass.add_comment "An example class that does useful things.", top_level

    readme = @store.add_file 'README.rdoc'
    readme.parser = RDoc::Parser::Simple
    readme.comment = RDoc::Comment.new "Project readme with installation instructions.", readme

    @store.complete :private
    @g.generate

    content = File.read('llms.txt')

    # Class entry should use actual description, not just "Class Example"
    assert_match(/\[Example\].*: An example class that does useful things/, content)
    refute_match(/: Class Example$/, content)

    # Page entry should use actual content, not just the page name
    assert_match(/\[README.*\].*: Project readme with installation instructions/, content)
  end

  def test_llms_txt_excerpt_extracts_first_paragraph_only
    @options.title = "My Ruby Project"

    top_level = @store.add_file 'lib/example.rb'
    top_level.parser = RDoc::Parser::Ruby
    klass = top_level.add_class RDoc::NormalClass, 'MultiPara'
    klass.add_comment <<~RDOC, top_level
      A class for processing data.

      == Usage

        processor = MultiPara.new
        processor.run
    RDOC

    @store.complete :private
    @g.generate

    content = File.read('llms.txt')

    # Should use only the first paragraph, not headings or code
    assert_match(/\[MultiPara\].*: A class for processing data\./, content)
    refute_match(/Usage/, content)
    refute_match(/processor/, content)
  end

  def test_llms_txt_excerpt_truncates_at_word_boundary
    @options.title = "My Ruby Project"

    top_level = @store.add_file 'lib/example.rb'
    top_level.parser = RDoc::Parser::Ruby
    klass = top_level.add_class RDoc::NormalClass, 'LongDesc'
    klass.add_comment "This is a very long description that goes on and on about the many features and capabilities of this amazing class which provides extensive functionality for handling all sorts of complex data processing tasks in a reliable manner.", top_level

    @store.complete :private
    @g.generate

    content = File.read('llms.txt')

    # Should end with "..." and not exceed 153 chars (150 + "...")
    desc_match = content.match(/\[LongDesc\].*: (.+)$/)
    assert desc_match, "Should have LongDesc entry"
    desc = desc_match[1]
    assert desc.end_with?("..."), "Long description should end with '...'"
    assert desc.length <= 153, "Description should be truncated (got #{desc.length} chars)"
    # The text before "..." should end at a word boundary
    text_before_ellipsis = desc.sub(/\.\.\.\z/, '')
    assert_match(/\w\z/, text_before_ellipsis,
      "Should truncate at end of a complete word, not mid-word")
  end

  def test_generates_llms_txt_with_empty_store
    @options.title = "Empty Project"

    @store.complete :private
    @g.generate

    assert_file 'llms.txt'

    content = File.read('llms.txt')

    # Should have the title
    assert_match(/^# Empty Project$/, content)

    # Should not have Documentation or Guides sections
    refute_match(/## Documentation/, content)
    refute_match(/## Guides/, content)

    # llms-full.txt should also be generated
    assert_file 'llms-full.txt'

    full_content = File.read('llms-full.txt')
    assert_match(/^# Empty Project$/, full_content)
  end

  def test_llms_full_txt_method_signatures_in_code_blocks
    @options.title = "My Project"

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

    content = File.read('llms-full.txt')

    # Should have plain code block (no language specifier)
    assert_match(/^```\ntransform\(value\) -> Result\ntransform\(value\) \{ \|v\| \.\.\. \} -> Result\n```$/m, content)

    # Should NOT have ```ruby
    refute_match(/```ruby/, content)
  end

  def test_llms_full_txt_visibility_and_method_ordering
    @options.title = "My Project"

    top_level = @store.add_file 'lib/example.rb'
    top_level.parser = RDoc::Parser::Ruby

    klass = top_level.add_class RDoc::NormalClass, 'Ordered'

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

    klass.set_visibility_for(['private_method'], :private)
    klass.set_visibility_for(['protected_method'], :protected)

    @store.complete :private
    @g.generate

    content = File.read('llms-full.txt')

    # Class methods should come before instance methods
    class_methods_pos = content.index('## Public Class Methods')
    public_instance_pos = content.index('## Public Instance Methods')
    protected_instance_pos = content.index('## Protected Instance Methods')
    private_instance_pos = content.index('## Private Instance Methods')

    assert class_methods_pos, "Should have Public Class Methods section"
    assert public_instance_pos, "Should have Public Instance Methods section"
    assert protected_instance_pos, "Should have Protected Instance Methods section"
    assert private_instance_pos, "Should have Private Instance Methods section"

    assert class_methods_pos < public_instance_pos, "Class methods should come before instance methods"
    assert public_instance_pos < protected_instance_pos, "Public should come before protected"
    assert protected_instance_pos < private_instance_pos, "Protected should come before private"
  end

  def test_llms_full_txt_fully_qualified_method_names
    @options.title = "My Project"

    top_level = @store.add_file 'lib/example.rb'
    top_level.parser = RDoc::Parser::Ruby

    klass = top_level.add_class RDoc::NormalClass, 'Example'

    instance_meth = RDoc::AnyMethod.new nil, 'foo'
    instance_meth.comment = RDoc::Comment.new("An instance method.", top_level)
    klass.add_method instance_meth

    class_meth = RDoc::AnyMethod.new nil, 'bar', singleton: true
    class_meth.comment = RDoc::Comment.new("A class method.", top_level)
    klass.add_method class_meth

    @store.complete :private
    @g.generate

    content = File.read('llms-full.txt')

    # Instance methods should use # separator
    assert_match(/^### Example#foo$/, content)

    # Class methods should use . separator
    assert_match(/^### Example\.bar$/, content)
  end

  def test_llms_full_txt_inheritance_and_mixins
    @options.title = "My Project"

    top_level = @store.add_file 'lib/example.rb'
    top_level.parser = RDoc::Parser::Ruby

    parent = top_level.add_class RDoc::NormalClass, 'Base'
    klass = top_level.add_class RDoc::NormalClass, 'Child'
    klass.superclass = parent
    klass.add_comment "A child class.", top_level

    inc = RDoc::Include.new('Enumerable', 'Provides enumeration.')
    klass.add_include inc

    ext = RDoc::Extend.new('ClassMethods', 'Provides class methods.')
    klass.add_extend ext

    @store.complete :private
    @g.generate

    content = File.read('llms-full.txt')

    assert_match(/^# Child$/, content)
    assert_match(/Inherits from: Base/, content)
    assert_match(/Includes: Enumerable/, content)
    assert_match(/Extends: ClassMethods/, content)
  end

  def test_llms_full_txt_no_readme_duplication
    @options.title = "My Project"

    readme = @store.add_file 'README.rdoc'
    readme.parser = RDoc::Parser::Simple
    readme.comment = RDoc::Comment.new "Unique readme content for dedup test.", readme
    @options.main_page = 'README.rdoc'

    @store.complete :private
    @g.generate

    content = File.read('llms-full.txt')

    # README content should appear exactly once
    occurrences = content.scan('Unique readme content for dedup test').length
    assert_equal 1, occurrences, "README content should not be duplicated (found #{occurrences} times)"
  end
end
