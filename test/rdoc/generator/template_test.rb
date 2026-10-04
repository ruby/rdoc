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
    generator = generator_for 'aliki'

    first_evaluations = count_evaluations { generator.generate_class @alpha }
    second_evaluations = count_evaluations { generator.generate_class @beta }

    assert_operator first_evaluations, :>, 0
    assert_equal 0, second_evaluations
  end

  def test_darkfish_keeps_binding_based_rendering
    generator = generator_for 'darkfish'
    generator.generate_class @alpha

    assert_operator count_evaluations { generator.generate_class @beta }, :>, 0
    assert_kind_of Binding, generator.instance_variable_get(:@context)
    generator.instance_variable_get(:@template_cache).each_value do |template|
      assert_not_kind_of RDoc::Generator::CompiledTemplate, template
    end
  end

  def test_cached_renderers_are_methods_bound_to_the_generator
    generator = generator_for 'aliki'
    generator.generate_class @alpha

    templates = generator.instance_variable_get(:@template_cache).values
    renderers = templates.filter_map { |template| template.instance_variable_get(:@compiled_renderer) }

    assert_not_empty renderers
    renderers.each do |renderer|
      assert_kind_of Method, renderer
      assert_same generator, renderer.receiver
    end
  end

  def test_compiled_renderers_only_accept_declared_inputs
    generator = generator_for 'aliki'
    generator.generate_class @alpha

    page = generator.template_for generator.template_dir + 'class.rhtml'
    renderer = page.instance_variable_get :@compiled_renderer
    assert_kind_of Method, renderer
    assert_equal %i[io rel_prefix asset_rel_prefix current klass file breadcrumb],
                 renderer.parameters.map(&:last)

    partial = generator.template_for generator.template_dir + '_sidebar_sections.rhtml', false, RDoc::ERBPartial
    renderer = partial.instance_variable_get :@compiled_renderer
    assert_kind_of Method, renderer
    assert_equal [:klass], renderer.parameters.map(&:last)
  end

  def test_aliki_contracts_match_its_owned_templates
    generator = generator_for 'aliki'
    templates = generator.template_dir.children.select { |file| file.extname == '.rhtml' }.map { |file| file.basename.to_s }

    assert_equal templates.sort, RDoc::Generator::Aliki::TEMPLATE_INPUTS.keys.sort
  end

  def test_builtin_rendering_does_not_inspect_bindings
    generator = generator_for 'aliki'
    binding_reads = []
    trace = TracePoint.new(:call, :c_call) do |event|
      if event.self.is_a?(Binding) && %i[local_variables local_variable_get].include?(event.method_id)
        binding_reads << event.method_id
      end
    end

    trace.enable do
      generator.generate_class @alpha
      generator.generate_class @beta
    end

    assert_empty binding_reads
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
    assert_nil template.instance_variable_get(:@compiled_renderer)
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

  def test_cached_templates_follow_output_mode_changes
    generator = generator_for 'aliki'
    generator.generate_class @alpha

    generator.file_output = true
    generator.generate_class @beta
    beta_html = File.read File.join(@test_home, 'Beta.html')
    assert_include beta_html, 'Second page documentation.'

    generator.file_output = false
    assert_include generator.generate_class(@alpha), 'First page documentation: café.'
    assert_equal 0, count_evaluations { generator.generate_class @beta }
  end

  def test_cached_streaming_templates_can_switch_to_dry_run
    generator = generator_for 'aliki'
    generator.file_output = true
    generator.generate_class @alpha

    generator.dry_run = true
    html = generator.generate_class @beta

    assert_include html, 'Second page documentation.'
    refute_file File.join(@test_home, 'Beta.html')
    assert_equal 0, count_evaluations { generator.generate_class @alpha }
  end

  def test_index_reuses_its_renderer_when_the_main_page_changes
    generator = generator_for 'aliki'
    html = generator.generate_index
    assert_include html, 'This is the API documentation'

    template = generator.template_for generator.template_dir + 'index.rhtml'
    renderer = template.instance_variable_get :@compiled_renderer
    assert_kind_of Method, renderer

    readme = @store.add_file 'README.rdoc', parser: RDoc::Parser::Simple
    readme.comment = "= Main page heading\n\n== Second heading"
    @options.main_page = readme.full_name
    generator.refresh_store_data
    html = generator.generate_index
    assert_include html, 'Main page heading'
    assert_same renderer, template.instance_variable_get(:@compiled_renderer)

    @options.main_page = nil
    html = generator.generate_index
    assert_include html, 'This is the API documentation'
    assert_not_include html, '<h1 id="main-page-heading"'
    assert_same renderer, template.instance_variable_get(:@compiled_renderer)
  end

  def test_partials_reuse_their_renderer_across_page_types
    page = @store.add_file 'guides/USAGE.rdoc', parser: RDoc::Parser::Simple
    page.comment = '= Nested page documentation'

    generator = generator_for 'aliki'
    generator.generate_index
    partial = generator.template_for generator.template_dir + '_sidebar_pages.rhtml', false, RDoc::ERBPartial
    renderer = partial.instance_variable_get :@compiled_renderer
    assert_kind_of Method, renderer

    generator.generate_class @alpha
    assert_same renderer, partial.instance_variable_get(:@compiled_renderer)

    html = generator.generate_page page
    assert_include html, 'Nested page documentation'
    assert_include html, '../css/rdoc.css'
    assert_same renderer, partial.instance_variable_get(:@compiled_renderer)

    html = generator.generate_servlet_not_found 'Missing page'
    assert_include html, 'Missing page'
    assert_same renderer, partial.instance_variable_get(:@compiled_renderer)
    assert_equal 0, count_evaluations { generator.generate_class @beta }
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

  def test_custom_class_templates_can_access_incidental_caller_locals
    generator = generator_for 'aliki'
    page = Pathname.new(@test_home) + 'custom.rhtml'
    File.write page, <<~ERB
      <html><%= [klass.equal?(current), out_file.basename.to_s,
                 template_file.basename.to_s, here.is_a?(Binding),
                 search_index_rel_prefix == rel_prefix].join('|') %></html>
    ERB

    assert_equal "<html>true|Alpha.html|custom.rhtml|true|true</html>\n",
                 generator.generate_class(@alpha, page)
  end

  def test_builtin_templates_preserve_explicit_binding_evaluation_without_inputs
    generator = generator_for 'aliki'
    generator.generate_index
    template_file = generator.template_dir + 'index.rhtml'
    template = generator.template_for template_file
    renderer = template.instance_variable_get :@compiled_renderer
    context = generator.instance_eval { binding }
    context.local_variable_set :rel_prefix, '.'
    context.local_variable_set :asset_rel_prefix, '.'

    html = generator.render_template(template_file) { context }

    assert_include html, 'This is the API documentation'
    assert_equal html, context.local_variable_get(:io)
    assert_same renderer, template.instance_variable_get(:@compiled_renderer)
  end

  def test_custom_page_using_builtin_partials_keeps_shared_binding_behavior
    generator = generator_for 'aliki'
    generator.generate_class @beta
    page = Pathname.new(@test_home) + 'custom.rhtml'
    File.write page, '<html><% render "_footer.rhtml" %><%= @context.local_variable_get(:_erbout__footer) %></html>'

    html = generator.generate_class @alpha, page

    assert_include html, 'Generated by'
    assert_include html, RDoc::VERSION
    partial = generator.template_for generator.template_dir + '_footer.rhtml', false, RDoc::ERBPartial
    assert_kind_of Method, partial.instance_variable_get(:@compiled_renderer)
    assert_kind_of Binding, generator.instance_variable_get(:@context)
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

  def test_cached_custom_erb_classes_receive_the_original_page_binding
    generator = generator_for 'aliki'
    erb_class = Class.new(ERB) do
      def result(context = nil)
        "custom #{context.local_variable_get(:current).full_name}"
      end
    end
    generator.template_for generator.template_dir + 'class.rhtml', true, erb_class

    assert_equal 'custom Alpha', generator.generate_class(@alpha)
    assert_equal 'custom Beta', generator.generate_class(@beta)
  end

  def test_render_inputs_reject_unknown_fields
    assert_raise(ArgumentError) do
      RDoc::Generator::CompiledTemplate::Inputs.new(incidental_local: true)
    end
  end

  def test_generator_subclasses_keep_binding_based_rendering
    generator = generator_for 'aliki', Class.new(RDoc::Generator::Aliki)
    generator.generate_class @alpha

    evaluations = count_evaluations { generator.generate_class @beta }

    assert_operator evaluations, :>, 0
  end

  def test_generator_subclasses_can_override_the_legacy_render_template_signature
    generator_class = Class.new(RDoc::Generator::Aliki) do
      def render_template(template_file, out_file = nil, &block)
        super
      end
    end
    generator = generator_for 'aliki', generator_class

    assert_include generator.generate_class(@alpha), 'First page documentation: café.'
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
