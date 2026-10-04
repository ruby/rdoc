# frozen_string_literal: true

require 'uri'
require_relative 'compiled_template'

module RDoc
  module Generator
    ##
    # Aliki theme for RDoc documentation
    #
    # Author: Stan Lo
    #

    class Aliki < Generator::Darkfish
      DESCRIPTION = 'HTML generator, written by Stan Lo'

      TEMPLATE_DIR = (Pathname.new(__dir__) + 'template' + 'aliki').freeze # :nodoc:
      # Pages include the assembled head's inputs; absent page objects are nil.
      PAGE_INPUTS = %i[io rel_prefix asset_rel_prefix current klass file].freeze # :nodoc:
      TEMPLATE_INPUTS = { # :nodoc:
        'class.rhtml' => PAGE_INPUTS + [:breadcrumb],
        'index.rhtml' => PAGE_INPUTS,
        'page.rhtml' => PAGE_INPUTS,
        'servlet_not_found.rhtml' => PAGE_INPUTS + [:message],
        'servlet_root.rhtml' => PAGE_INPUTS + [:installed],
        '_head.rhtml' => %i[rel_prefix asset_rel_prefix current klass file],
        '_aside_toc.rhtml' => [],
        '_footer.rhtml' => [:rel_prefix],
        '_header.rhtml' => [:rel_prefix],
        '_icons.rhtml' => [],
        '_sidebar_ancestors.rhtml' => [:klass],
        '_sidebar_classes.rhtml' => [:rel_prefix],
        '_sidebar_extends.rhtml' => [:klass],
        '_sidebar_includes.rhtml' => [:klass],
        '_sidebar_installed.rhtml' => [:installed],
        '_sidebar_methods.rhtml' => [:klass],
        '_sidebar_pages.rhtml' => %i[rel_prefix current],
        '_sidebar_search.rhtml' => [],
        '_sidebar_sections.rhtml' => [:klass],
        '_sidebar_toggle.rhtml' => [],
      }.transform_values(&:freeze).freeze

      RDoc.add_generator self

      def initialize(store, options)
        super
        @template_dir = TEMPLATE_DIR
      end

      ##
      # Generate documentation. Overrides Darkfish to use Aliki's own search index
      # instead of the JsonIndex generator.

      def generate
        setup

        write_style_sheet
        generate_index
        generate_class_files
        generate_file_files
        generate_table_of_contents
        write_search_index

        copy_static

      rescue => e
        debug_msg "%s: %s\n  %s" % [
          e.class.name, e.message, e.backtrace.join("\n  ")
        ]

        raise
      end

      ##
      # Copy only the static assets required by the Aliki theme. Unlike Darkfish we
      # don't ship embedded fonts or image sprites, so limit the asset list to keep
      # generated documentation lightweight.

      def write_style_sheet
        debug_msg "Copying Aliki static files"
        options = { verbose: $DEBUG_RDOC, noop: @dry_run }

        install_rdoc_static_file @template_dir + 'css/rdoc.css', "./css/rdoc.css", options

        unless @options.template_stylesheets.empty?
          FileUtils.cp @options.template_stylesheets, '.', **options
        end

        Dir[(@template_dir + 'js/**/*').to_s].each do |path|
          next if File.directory?(path)
          next if File.basename(path).start_with?('.')

          dst = Pathname.new(path).relative_path_from(@template_dir)

          install_rdoc_static_file @template_dir + path, dst, options
        end
      end

      ##
      # Build a search index array for Aliki's searcher.

      def build_search_index
        setup

        index = []

        @classes.each do |klass|
          next unless klass.display?

          index << build_class_module_entry(klass)

          klass.constants.each do |const|
            next unless const.display?

            index << build_constant_entry(const, klass)
          end
        end

        @methods.each do |method|
          next unless method.display?

          index << build_method_entry(method)
        end

        index
      end

      ##
      # Write the search index as a JavaScript file
      # Format: var search_data = { index: [...] }
      #
      # We still write to a .js instead of a .json because loading a JSON file triggers CORS check in browsers.
      # And if we simply inspect the generated pages using file://, which is often the case due to lack of the server mode,
      # the JSON file will be blocked by the browser.

      def write_search_index
        debug_msg "Writing Aliki search index"

        index = build_search_index

        FileUtils.mkdir_p 'js' unless @dry_run

        search_index_path = 'js/search_data.js'
        return if @dry_run

        data = { index: index }
        File.write search_index_path, "var search_data = #{JSON.generate(data)};"
      end

      ##
      # Returns the type signature of +method_attr+ as HTML with linked type names.
      # Returns nil if no type signature is present.

      def type_signature_html(method_attr, from_path)
        lines = method_attr.type_signature_lines || @store.rbs_signature_for(method_attr)
        return unless lines

        RbsHelper.signature_to_html(
          lines,
          lookup: @store.type_name_lookup,
          from_path: from_path
        )
      end

      ##
      # Resolves a URL for use in templates. Absolute URLs are returned unchanged.
      # Relative URLs are prefixed with rel_prefix to ensure they resolve correctly from any page.

      def resolve_url(rel_prefix, url)
        uri = URI.parse(url)
        if uri.absolute?
          url
        else
          "#{rel_prefix}/#{url}"
        end
      rescue URI::InvalidURIError
        "#{rel_prefix}/#{url}"
      end

      #: (Pathname, ?bool, ?Class[ERB]) -> ERB
      def template_for(file, page = true, klass = ERB)
        cached = @template_cache[file]
        # String and streaming ERB compile different output operations.  Replace
        # only owned compiled templates; custom ERB caches keep legacy behavior.
        if cached.is_a?(CompiledTemplate) && cached.class != klass
          @template_cache.delete(file)
        end

        template = super
        return template if template.is_a?(CompiledTemplate)
        return template unless [ERB, ERBIO, ERBPartial].include?(template.class)

        if inputs = builtin_template_inputs(file)
          template.extend CompiledTemplate
          template.generator = self
          template.render_inputs = inputs
        end
        template
      end

    private

      #: (Pathname, ?Pathname?, **untyped) -> untyped
      def render_page_template(template_file, out_file = nil, **inputs, &block)
        return super unless builtin_template_inputs(template_file)

        erb_class = erb_class_for out_file
        template = template_for template_file, true, erb_class
        return super unless template.is_a?(CompiledTemplate)

        render_template template_file, out_file do |io|
          CompiledTemplate::Inputs.new(io: io, **inputs)
        end
      end

      #: (Pathname) -> Array[Symbol]?
      def builtin_template_inputs(file)
        # Custom generators and templates retain their shared-binding behavior.
        return unless self.class == Aliki && @template_dir.expand_path == TEMPLATE_DIR
        return unless file.dirname.expand_path == TEMPLATE_DIR

        TEMPLATE_INPUTS[file.basename.to_s]
      end

      def template_encoding
        ::Encoding::UTF_8
      end

      def build_class_module_entry(klass)
        type = case klass
               when NormalClass then 'class'
               when NormalModule then 'module'
               else 'class'
               end

        entry = {
          name: klass.name,
          full_name: klass.full_name,
          type: type,
          path: klass.path
        }

        snippet = klass.search_snippet
        entry[:snippet] = snippet unless snippet.empty?
        entry
      end

      def build_method_entry(method)
        type = method.singleton ? 'class_method' : 'instance_method'

        entry = {
          name: method.name,
          full_name: method.full_name,
          type: type,
          path: method.path
        }

        snippet = method.search_snippet
        entry[:snippet] = snippet unless snippet.empty?
        entry
      end

      def build_constant_entry(const, parent)
        entry = {
          name: const.name,
          full_name: "#{parent.full_name}::#{const.name}",
          type: 'constant',
          path: parent.path
        }

        snippet = const.search_snippet
        entry[:snippet] = snippet unless snippet.empty?
        entry
      end
    end
  end
end
