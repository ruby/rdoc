# frozen_string_literal: true

require_relative '../../markup/to_markdown_crossref'

##
# Generates markdown files and llms.txt for LLM consumption.
# Extracted from RDoc::Generator::Aliki to separate markdown generation
# from HTML generation and search index concerns.

class RDoc::Generator::Aliki::MarkdownGenerator
  def initialize(options, outputdir, classes, files, main_page, dry_run: false)
    @options   = options
    @outputdir = outputdir
    @classes   = classes
    @files     = files
    @main_page = main_page
    @dry_run   = dry_run
  end

  ##
  # Generate all markdown files: index, classes, pages, and llms.txt

  def generate
    generate_index_markdown

    @classes.reject(&:is_alias_for).each do |klass|
      generate_class_markdown(klass)
    end

    @files.each do |file|
      generate_file_markdown(file) if file.text?
    end

    generate_llms_txt
  end

  ##
  # Generate markdown for the index page

  def generate_index_markdown
    out_file = @outputdir + 'index.md'
    debug_msg "  generating #{out_file}"

    content = build_index_markdown

    return if @dry_run

    out_file.write(content, encoding: @options.encoding)
  end

  ##
  # Build markdown content for the index page

  def build_index_markdown
    md = []
    md << "# #{@options.title}"
    md << ""

    if @main_page && @main_page.comment
      main_content = format_comment(@main_page.comment, markdown_formatter(@main_page))
      md << main_content unless main_content.empty?
    end

    md.join("\n").strip + "\n"
  end

  ##
  # Generate markdown for a single class/module

  def generate_class_markdown(klass)
    return unless klass.display?

    out_file = @outputdir + md_path_for(klass.path)
    debug_msg "  generating #{out_file}"

    content = build_class_markdown(klass)

    return if @dry_run

    out_file.dirname.mkpath
    out_file.write(content, encoding: @options.encoding)
  end

  ##
  # Generate markdown for a standalone page file

  def generate_file_markdown(file)
    return unless file.display?

    out_file = @outputdir + md_path_for(file.path)
    debug_msg "  generating #{out_file}"

    content = build_file_markdown(file)

    return if @dry_run

    out_file.dirname.mkpath
    out_file.write(content, encoding: @options.encoding)
  end

  ##
  # Build markdown content for a standalone page

  def build_file_markdown(file)
    content = file.comment ? format_comment(file.comment, markdown_formatter(file)) : ""
    content.strip + "\n"
  end

  ##
  # Generate llms.txt discovery file conforming to llmstxt.org spec

  def generate_llms_txt
    out_file = @outputdir + 'llms.txt'
    debug_msg "  generating #{out_file}"

    content = build_llms_txt

    return if @dry_run

    out_file.write(content, encoding: @options.encoding)
  end

  ##
  # Build llms.txt content

  def build_llms_txt
    md = []

    # H1 with project name (required)
    md << "# #{@options.title}"
    md << ""

    # Blockquote with description (optional)
    if @main_page && @main_page.comment
      plain_text = format_comment(@main_page.comment, RDoc::Markup::ToMarkdown.new)
      excerpt_text = excerpt(plain_text)
      md << "> #{excerpt_text}" unless excerpt_text.empty?
      md << ""
    end

    # Classes/modules section
    displayable_classes = @classes.reject(&:is_alias_for).select(&:display?)
    unless displayable_classes.empty?
      md << "## Documentation"
      md << ""
      displayable_classes.sort_by(&:full_name).each do |klass|
        md << "- [#{klass.full_name}](#{md_path_for(klass.path)}): #{klass.type.capitalize} #{klass.full_name}"
      end
      md << ""
    end

    # Pages section
    displayable_files = @files.select { |f| f.text? && f.display? }
    unless displayable_files.empty?
      md << "## Guides"
      md << ""
      displayable_files.sort_by(&:full_name).each do |file|
        name = file.page_name || file.base_name
        md << "- [#{name}](#{md_path_for(file.path)}): #{name}"
      end
      md << ""
    end

    md.join("\n").strip + "\n"
  end

  ##
  # Build markdown content for a class/module

  def build_class_markdown(klass)
    formatter = markdown_formatter(klass)
    md = []
    md << "# #{klass.full_name}"
    md << ""

    # Inheritance and mixins
    has_hierarchy = false

    if klass.is_a?(RDoc::NormalClass) && klass.superclass
      superclass_name = case klass.superclass
                        when String then klass.superclass
                        else klass.superclass.full_name
                        end
      unless superclass_name == "Object"
        md << "Inherits from: #{superclass_name}"
        has_hierarchy = true
      end
    end

    includes = klass.includes.map(&:name)
    unless includes.empty?
      md << "Includes: #{includes.join(', ')}"
      has_hierarchy = true
    end

    extends = klass.extends.map(&:name)
    unless extends.empty?
      md << "Extends: #{extends.join(', ')}"
      has_hierarchy = true
    end

    md << "" if has_hierarchy

    # Class description
    description = markdown_for_comment(klass.comment_location, formatter)
    unless description.empty?
      md << description
      md << ""
    end

    # Constants
    constants = klass.constants.select(&:display?).sort_by(&:name)
    unless constants.empty?
      md << "## Constants"
      md << ""
      constants.each do |const|
        md << "### #{const.name}"
        md << ""
        desc = markdown_for_comment([[const.comment, const.file]], formatter)
        md << desc unless desc.empty?
        md << ""
      end
    end

    # Attributes
    attributes = klass.attributes.select(&:display?).sort_by(&:name)
    unless attributes.empty?
      md << "## Attributes"
      md << ""
      attributes.each do |attr|
        rw = case attr.rw
             when 'R' then '(r)'
             when 'W' then '(w)'
             else '(rw)'
             end
        md << "### #{attr.name} #{rw}"
        md << ""
        desc = markdown_for_comment([[attr.comment, attr.file]], formatter)
        md << desc unless desc.empty?
        md << ""
      end
    end

    # Methods grouped by visibility and type
    add_methods_section(md, klass, :public, true, "Public Class Methods", formatter)
    add_methods_section(md, klass, :protected, true, "Protected Class Methods", formatter)
    add_methods_section(md, klass, :private, true, "Private Class Methods", formatter)
    add_methods_section(md, klass, :public, false, "Public Instance Methods", formatter)
    add_methods_section(md, klass, :protected, false, "Protected Instance Methods", formatter)
    add_methods_section(md, klass, :private, false, "Private Instance Methods", formatter)

    md.join("\n").strip + "\n"
  end

  private

  ##
  # Adds a methods section to the markdown output for the given visibility and type

  def add_methods_section(md, klass, visibility, singleton, title, formatter)
    methods = klass.method_list.select do |m|
      m.display? && m.visibility == visibility && m.singleton == singleton
    end.sort_by(&:name)

    return if methods.empty?

    md << "## #{title}"
    md << ""

    methods.each do |meth|
      md << "### #{meth.name}"
      md << ""

      if meth.arglists
        md << "```"
        md << meth.arglists
        md << "```"
        md << ""
      end

      desc = markdown_for_comment([[meth.comment, meth.file]], formatter)
      md << desc unless desc.empty?
      md << ""
    end
  end

  ##
  # Converts a comment_location array to markdown text using the given formatter

  def markdown_for_comment(comment_location, formatter)
    return "" if comment_location.nil? || comment_location.empty?

    parts = comment_location.map do |comment, _location|
      format_comment(comment, formatter)
    end

    parts.join("\n\n").strip
  end

  ##
  # Formats a single comment using the given formatter

  def format_comment(comment, formatter)
    case comment
    when RDoc::Comment
      comment.parse.accept(formatter)
    when RDoc::Markup::Document
      comment.accept(formatter)
    when String
      RDoc::Markup::Parser.parse(comment).accept(formatter)
    else
      ""
    end
  rescue NoMethodError
    # Handle edge cases where formatter encounters nil values (e.g., malformed tables)
    ""
  end

  ##
  # Creates a markdown formatter with optional cross-reference support

  def markdown_formatter(context = nil)
    if context
      from_path = md_path_for(context.path)
      RDoc::Markup::ToMarkdownCrossref.new(@options, from_path, context)
    else
      RDoc::Markup::ToMarkdown.new
    end
  end

  ##
  # Converts an .html path to the corresponding .md path

  def md_path_for(html_path)
    html_path.sub(/\.html$/, '.md')
  end

  ##
  # Extracts a short summary from formatted text for the llms.txt blockquote.
  # Truncates to 150 characters.

  def excerpt(text)
    text.strip.gsub(/\s+/, ' ')[0...150]
  end

  def debug_msg(msg)
    $stderr.puts msg if $DEBUG_RDOC
  end
end
