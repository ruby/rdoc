# frozen_string_literal: true

require_relative '../../support/test_case'

class RDocGeneratorAlikiSearchIndexTest < RDoc::TestCase
  def setup
    super

    @tmpdir = Dir.mktmpdir "test_rdoc_generator_aliki_search_index_#{$$}_"
    FileUtils.mkdir_p @tmpdir

    @options = RDoc::Options.new
    @options.files = []
    @options.setup_generator 'aliki'
    @options.template_dir = ''
    @options.op_dir = @tmpdir
    @options.option_parser = OptionParser.new
    @options.finish

    @g = RDoc::Generator::Aliki.new @store, @options

    @rdoc.options = @options
    @rdoc.generator = @g

    @top_level = @store.add_file 'file.rb'
    @top_level.parser = RDoc::Parser::Ruby

    Dir.chdir @tmpdir
  end

  def teardown
    super

    Dir.chdir @pwd
    FileUtils.rm_rf @tmpdir
  end

  def test_build_search_index_returns_array
    index = @g.build_search_index

    assert_kind_of Array, index
  end

  def test_build_search_index_includes_classes
    @klass = @top_level.add_class RDoc::NormalClass, 'MyClass'
    @store.complete :private

    index = @g.build_search_index

    class_entry = index.find { |e| e[:name] == 'MyClass' }
    assert_not_nil class_entry, "Expected to find MyClass in index"
    assert_equal 'MyClass', class_entry[:full_name]
    assert_equal 'class', class_entry[:type]
    assert_equal 'MyClass.html', class_entry[:path]
  end

  def test_build_search_index_includes_modules
    @mod = @top_level.add_module RDoc::NormalModule, 'MyModule'
    @store.complete :private

    index = @g.build_search_index

    mod_entry = index.find { |e| e[:name] == 'MyModule' }
    assert_not_nil mod_entry, "Expected to find MyModule in index"
    assert_equal 'MyModule', mod_entry[:full_name]
    assert_equal 'module', mod_entry[:type]
    assert_equal 'MyModule.html', mod_entry[:path]
  end

  def test_build_search_index_includes_nested_class
    @outer = @top_level.add_class RDoc::NormalClass, 'Outer'
    @inner = @outer.add_class RDoc::NormalClass, 'Inner'
    @store.complete :private

    index = @g.build_search_index

    inner_entry = index.find { |e| e[:full_name] == 'Outer::Inner' }
    assert_not_nil inner_entry, "Expected to find Outer::Inner in index"
    assert_equal 'Inner', inner_entry[:name]
    assert_equal 'Outer::Inner', inner_entry[:full_name]
    assert_equal 'class', inner_entry[:type]
    assert_equal 'Outer/Inner.html', inner_entry[:path]
  end

  def test_build_search_index_includes_instance_methods
    @klass = @top_level.add_class RDoc::NormalClass, 'MyClass'
    @meth = RDoc::AnyMethod.new nil, 'my_method'
    @meth.singleton = false
    @klass.add_method @meth
    @store.complete :private

    index = @g.build_search_index

    meth_entry = index.find { |e| e[:name] == 'my_method' && e[:type] == 'instance_method' }
    assert_not_nil meth_entry, "Expected to find instance method my_method in index"
    assert_equal 'MyClass#my_method', meth_entry[:full_name]
    assert_equal 'instance_method', meth_entry[:type]
    assert_match(/MyClass\.html#method-i-my_method/, meth_entry[:path])
  end

  def test_build_search_index_includes_class_methods
    @klass = @top_level.add_class RDoc::NormalClass, 'MyClass'
    @meth = RDoc::AnyMethod.new nil, 'my_class_method'
    @meth.singleton = true
    @klass.add_method @meth
    @store.complete :private

    index = @g.build_search_index

    meth_entry = index.find { |e| e[:name] == 'my_class_method' && e[:type] == 'class_method' }
    assert_not_nil meth_entry, "Expected to find class method my_class_method in index"
    assert_equal 'MyClass::my_class_method', meth_entry[:full_name]
    assert_equal 'class_method', meth_entry[:type]
    assert_match(/MyClass\.html#method-c-my_class_method/, meth_entry[:path])
  end

  def test_build_search_index_includes_constants
    @klass = @top_level.add_class RDoc::NormalClass, 'MyClass'
    @const = RDoc::Constant.new 'MY_CONSTANT', 'value', 'A constant'
    @klass.add_constant @const
    @store.complete :private

    index = @g.build_search_index

    const_entry = index.find { |e| e[:name] == 'MY_CONSTANT' && e[:type] == 'constant' }
    assert_not_nil const_entry, "Expected to find constant MY_CONSTANT in index"
    assert_equal 'MyClass::MY_CONSTANT', const_entry[:full_name]
    assert_equal 'constant', const_entry[:type]
  end

  def test_build_search_index_excludes_nodoc
    @klass = @top_level.add_class RDoc::NormalClass, 'DocumentedClass'
    @nodoc_klass = @top_level.add_class RDoc::NormalClass, 'NodocClass'
    @nodoc_klass.document_self = false
    @store.complete :private

    index = @g.build_search_index

    documented = index.find { |e| e[:name] == 'DocumentedClass' }
    nodoc = index.find { |e| e[:name] == 'NodocClass' }

    assert_not_nil documented, "Expected to find DocumentedClass in index"
    assert_nil nodoc, "Expected NodocClass to be excluded from index"
  end

  def test_build_search_index_excludes_ignored
    @klass = @top_level.add_class RDoc::NormalClass, 'VisibleClass'
    @ignored = @top_level.add_class RDoc::NormalClass, 'IgnoredClass'
    @ignored.ignore
    @store.complete :private

    index = @g.build_search_index

    visible = index.find { |e| e[:name] == 'VisibleClass' }
    ignored = index.find { |e| e[:name] == 'IgnoredClass' }

    assert_not_nil visible, "Expected to find VisibleClass in index"
    assert_nil ignored, "Expected IgnoredClass to be excluded from index"
  end

  def test_build_search_index_includes_special_method_names
    @klass = @top_level.add_class RDoc::NormalClass, 'MyClass'

    @bracket_method = RDoc::AnyMethod.new nil, '[]'
    @klass.add_method @bracket_method

    @shovel_method = RDoc::AnyMethod.new nil, '<<'
    @klass.add_method @shovel_method

    @equals_method = RDoc::AnyMethod.new nil, '=='
    @klass.add_method @equals_method

    @store.complete :private

    index = @g.build_search_index

    bracket = index.find { |e| e[:name] == '[]' }
    shovel = index.find { |e| e[:name] == '<<' }
    equals = index.find { |e| e[:name] == '==' }

    assert_not_nil bracket, "Expected to find [] method in index"
    assert_not_nil shovel, "Expected to find << method in index"
    assert_not_nil equals, "Expected to find == method in index"
  end

  def test_write_search_index_creates_js_file
    @klass = @top_level.add_class RDoc::NormalClass, 'TestClass'
    @store.complete :private

    @g.write_search_index

    search_data_path = File.join(@tmpdir, 'js', 'search_data.js')
    assert_file search_data_path

    js_content = File.read(search_data_path)
    assert_match(/^var search_data = /, js_content)

    # Extract JSON from JS
    json_str = js_content.sub(/^var search_data = /, '').chomp(';')
    data = JSON.parse(json_str, symbolize_names: true)

    assert_kind_of Hash, data
    assert_kind_of Array, data[:index]
    assert data[:index].any? { |e| e[:name] == 'TestClass' }
  end

  def test_build_search_index_entry_structure
    @klass = @top_level.add_class RDoc::NormalClass, 'MyClass'
    @store.complete :private

    index = @g.build_search_index
    entry = index.find { |e| e[:name] == 'MyClass' }

    assert_equal %i[name full_name type path].sort, entry.keys.sort
  end
end
