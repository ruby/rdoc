# frozen_string_literal: true
require_relative '../helper'

class RDocGeneratorTemplateTest < RDoc::TestCase

  def setup
    super

    @options.op_dir = @test_home
    @top_level = @store.add_file 'example.rb'
    @top_level.parser = RDoc::Parser::Ruby
    @alpha = @top_level.add_class RDoc::NormalClass, 'Alpha'
    @beta = @top_level.add_class RDoc::NormalClass, 'Beta'
    @alpha.add_comment 'First page documentation: café.', @top_level
    @beta.add_comment 'Second page documentation.', @top_level
    @store.complete :private
  end

  def test_builtin_pages_and_partials_are_evaluated_only_once
    %w[aliki darkfish].each do |theme|
      generator = generator_for theme

      first_evaluations = count_evaluations { generator.generate_class @alpha }
      second_evaluations = count_evaluations { generator.generate_class @beta }

      assert_operator first_evaluations, :>, 0, theme
      assert_equal 0, second_evaluations, theme
    end
  end

  def test_cached_renderers_are_methods_bound_to_the_generator
    generator = generator_for 'aliki'
    generator.generate_class @alpha

    templates = generator.instance_variable_get(:@template_cache).values
    renderers = templates.flat_map do |template|
      (template.instance_variable_get(:@compiled_renderers) || {}).values
    end

    assert_not_empty renderers
    renderers.each do |renderer|
      assert_kind_of Method, renderer
      assert_same generator, renderer.receiver
    end
  end

  def test_clearing_the_template_cache_discards_its_compiled_renderers
    generator = generator_for 'aliki'
    generator.generate_class @alpha
    file = generator.template_dir + 'class.rhtml'
    first_template = generator.template_for file

    generator.instance_variable_get(:@template_cache).clear
    evaluations = count_evaluations { generator.generate_class @beta }

    assert_operator evaluations, :>, 0
    assert_not_same first_template, generator.template_for(file)
    assert_equal 0, count_evaluations { generator.generate_class @alpha }
  end

  def test_template_result_still_accepts_an_implicit_binding
    generator = generator_for 'aliki'
    template = generator.template_for generator.template_dir + '_sidebar_toggle.rhtml', false, RDoc::ERBPartial

    assert_include template.result, 'sidebar-navigation-toggle'
  end

  def test_template_result_preserves_a_foreign_binding
    generator = generator_for 'aliki'
    template = generator.template_for generator.template_dir + '_sidebar_toggle.rhtml', false, RDoc::ERBPartial

    assert_include template.result(binding), 'sidebar-navigation-toggle'
    assert_nil template.instance_variable_get(:@compiled_renderers)
  end

  def test_cached_templates_use_current_class_and_path
    %w[aliki darkfish].each do |theme|
      generator = generator_for theme
      alpha_html = generator.generate_class @alpha
      beta_html = generator.generate_class @beta

      assert_include alpha_html, '<title>class Alpha -'
      assert_include alpha_html, 'First page documentation: café.'
      assert_include beta_html, '<title>class Beta -'
      assert_include beta_html, 'Second page documentation.'
      assert_not_include beta_html, 'First page documentation: café.'
      assert_include beta_html, RDoc::VERSION
    end
  end

  def test_cached_templates_write_to_current_output_stream
    generator = generator_for 'aliki'
    generator.file_output = true
    generator.generate_class @alpha
    generator.generate_class @beta

    alpha_html = File.read File.join(@test_home, 'Alpha.html')
    beta_html = File.read File.join(@test_home, 'Beta.html')
    assert_include alpha_html, 'First page documentation: café.'
    assert_include beta_html, 'Second page documentation.'
    assert_not_include beta_html, 'First page documentation: café.'
  end

  def test_index_handles_a_new_local_variable_without_reusing_the_old_renderer
    generator = generator_for 'darkfish'
    generator.generate_index

    readme = @store.add_file 'README.rdoc', parser: RDoc::Parser::Simple
    readme.comment = '= Main page heading'
    @options.main_page = 'README.rdoc'
    generator.refresh_store_data

    html = generator.generate_index
    assert_include html, 'Main page heading'
    template = generator.template_for generator.template_dir + 'index.rhtml'
    assert_equal 2, template.instance_variable_get(:@compiled_renderers).size
  end

  def test_cached_templates_work_in_dry_run_mode
    generator = generator_for 'aliki'
    generator.file_output = true
    generator.dry_run = true
    generator.generate_class @alpha

    evaluations = count_evaluations { generator.generate_class @beta }

    assert_equal 0, evaluations
    refute_file File.join(@test_home, 'Alpha.html')
    refute_file File.join(@test_home, 'Beta.html')
  end

  def test_custom_templates_preserve_shared_binding_mutations
    @options.template_dir = @test_home
    generator = RDoc::Generator::Darkfish.new @store, @options
    generator.file_output = false

    page = Pathname.new(@test_home) + 'custom.rhtml'
    File.write page, '<html><% page_value = "changed" %><%= render "_custom.rhtml" %></html>'
    File.write File.join(@test_home, '_custom.rhtml'), '<%= page_value %>'
    context = generator.instance_eval { binding }
    context.local_variable_set :page_value, 'original'

    2.times do |index|
      html = generator.render_template(page) { context }
      assert_equal "<html>#{'changed' * (index + 1)}</html>", html
      assert_equal 'changed', context.local_variable_get(:page_value)
    end
  end

  def test_custom_page_using_builtin_partials_keeps_shared_binding_behavior
    generator = generator_for 'darkfish'
    generator.generate_class @beta
    page = Pathname.new(@test_home) + 'custom.rhtml'
    File.write page, '<html><% render "_footer.rhtml" %><%= @context.local_variable_get(:_erbout__footer) %></html>'

    html = generator.generate_class @alpha, page

    assert_include html, 'Generated by'
    assert_include html, RDoc::VERSION
    partial = generator.template_for generator.template_dir + '_footer.rhtml', false, RDoc::ERBPartial
    assert_equal 1, partial.instance_variable_get(:@compiled_renderers).size
    assert_nil generator.instance_variable_get(:@compiled_template_context)
  end

  def test_custom_erb_classes_keep_their_result_implementation
    generator = generator_for 'aliki'
    erb_class = Class.new(ERB) do
      def result(context = nil)
        'custom result'
      end
    end
    template = generator.template_for generator.template_dir + '_sidebar_toggle.rhtml', false, erb_class

    assert_equal 'custom result', template.result(generator.instance_eval { binding })
  end

  def test_generator_subclasses_keep_binding_based_rendering
    generator = generator_for 'darkfish', Class.new(RDoc::Generator::Darkfish)
    generator.generate_class @alpha

    evaluations = count_evaluations { generator.generate_class @beta }

    assert_operator evaluations, :>, 0
  end

  def test_template_errors_keep_the_template_filename
    generator = generator_for 'aliki'
    @alpha.define_singleton_method(:description) { self.no_such_method }

    error = assert_raise(RDoc::Error) { generator.generate_class @alpha }

    assert_include error.message, 'class.rhtml'
    file = generator.template_dir + 'class.rhtml'
    line = generator.assemble_template(file).lines.index { |text| text.include?('klass.description') } + 1
    assert error.backtrace.any? { |entry| entry.include?("#{file}:#{line}:") }
  end

  private

  def generator_for(theme, generator_class = nil)
    generator_class ||= theme == 'aliki' ? RDoc::Generator::Aliki : RDoc::Generator::Darkfish
    @options.template_dir = File.join @pwd, 'lib/rdoc/generator/template', theme
    generator = generator_class.new @store, @options
    @rdoc.generator = generator
    generator.file_output = false
    generator.setup
    generator
  end

  def count_evaluations
    count = 0
    erb_file = ERB.instance_method(:result).source_location.first
    trace = TracePoint.new(:line) do |event|
      count += 1 if event.path == erb_file && %i[def_method result].include?(event.method_id)
    end
    trace.enable { yield }
    count
  end
end
