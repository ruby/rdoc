# frozen_string_literal: true

##
# Generates llms.txt and llms-full.txt files for LLM consumption.
# Extracted from RDoc::Generator::Aliki to separate LLM-ready output
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
  # Generate llms.txt and llms-full.txt files

  def generate
    generate_llms_txt
    generate_llms_full_txt
  end

  ##
  # Build llms.txt content conforming to llmstxt.org spec

  def build_llms_txt
    md = []

    # H1 with project name (required)
    md << "# #{@options.title}"
    md << ""

    # Blockquote with description (optional)
    if @main_page && @main_page.comment
      excerpt_text = excerpt(raw_comment_text(@main_page.comment))
      md << "> #{excerpt_text}" unless excerpt_text.empty?
      md << ""
    end

    md << "- [Full documentation](llms-full.txt)"
    md << ""

    # Classes/modules section
    displayable_classes = @classes.reject(&:is_alias_for).select(&:display?)
    unless displayable_classes.empty?
      md << "## Documentation"
      md << ""
      displayable_classes.sort_by(&:full_name).each do |klass|
        desc = class_excerpt(klass)
        md << "- [#{klass.full_name}](#{klass.path}): #{desc}"
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
        desc = file_excerpt(file)
        md << "- [#{name}](#{file.path}): #{desc}"
      end
      md << ""
    end

    md.join("\n").strip + "\n"
  end

  ##
  # Build llms-full.txt content with all documentation concatenated.

  def build_llms_full_txt
    plain_formatter = RDoc::Markup::ToMarkdown.new

    parts = []
    parts << "# #{@options.title}"
    parts << ""

    # Include main page content
    if @main_page && @main_page.comment
      main_content = format_comment(@main_page.comment, plain_formatter)
      parts << main_content unless main_content.empty?
      parts << ""
    end

    # Include all page documentation (skip main page to avoid duplication)
    @files.select { |f| f.text? && f.display? && f != @main_page }.sort_by(&:full_name).each do |file|
      parts << "---"
      parts << ""
      content = file.comment ? format_comment(file.comment, plain_formatter).strip : ""
      parts << content + "\n" unless content.empty?
      parts << ""
    end

    # Include all class/module documentation
    @classes.reject(&:is_alias_for).select(&:display?).sort_by(&:full_name).each do |klass|
      parts << "---"
      parts << ""
      parts << build_class_markdown(klass, plain_formatter)
      parts << ""
    end

    parts.join("\n").strip + "\n"
  end

  private

  ##
  # Generate llms.txt discovery file

  def generate_llms_txt
    out_file = @outputdir + 'llms.txt'
    debug_msg "  generating #{out_file}"

    content = build_llms_txt

    return if @dry_run

    out_file.write(content, encoding: @options.encoding)
  end

  ##
  # Generate llms-full.txt with all documentation concatenated

  def generate_llms_full_txt
    out_file = @outputdir + 'llms-full.txt'
    debug_msg "  generating #{out_file}"

    content = build_llms_full_txt

    return if @dry_run

    out_file.write(content, encoding: @options.encoding)
  end

  ##
  # Build markdown content for a class/module

  def build_class_markdown(klass, formatter)
    md = []
    md << "# #{klass.full_name}"
    md << ""

    # Inheritance and mixins
    hierarchy_start = md.size

    if klass.is_a?(RDoc::NormalClass) && klass.superclass
      superclass_name = case klass.superclass
                        when String then klass.superclass
                        else klass.superclass.full_name
                        end
      unless superclass_name == "Object"
        md << "Inherits from: #{superclass_name}"
      end
    end

    includes = klass.includes.map(&:name)
    md << "Includes: #{includes.join(', ')}" unless includes.empty?

    extends = klass.extends.map(&:name)
    md << "Extends: #{extends.join(', ')}" unless extends.empty?

    md << "" if md.size > hierarchy_start

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
      prefix = singleton ? "#{klass.full_name}." : "#{klass.full_name}#"
      md << "### #{prefix}#{meth.name}"
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
  end

  ##
  # Extracts a short summary from formatted text for the llms.txt blockquote.
  # Uses only the first paragraph and truncates at word boundary to 150 characters.

  def excerpt(text)
    # Extract first paragraph only (up to first blank line)
    first_para = text.strip.split(/\n\s*\n/, 2).first || ""
    # Strip heading syntax (markdown '#' or RDoc '=') and inline markup
    clean = first_para.gsub(/^[#=]+\s*/, '').strip
    clean = clean.gsub(/(?<!\w)[+*_](\S.*?\S|\S)[+*_](?!\w)/, '\1') # +code+, *bold*, _italic_
    clean = clean.gsub(/\\(.)/, '\1') # unescape RDoc backslash escapes
    clean = clean.gsub(/\s+/, ' ')
    # Truncate at word boundary
    if clean.length > 150
      truncated = clean[0...150].sub(/\s+\S*\z/, '')
      "#{truncated}..."
    else
      clean
    end
  end

  ##
  # Extracts a short description for a class/module for use in llms.txt

  def class_excerpt(klass)
    fallback = "#{klass.type.capitalize} #{klass.full_name}"
    return fallback if klass.comment_location.nil? || klass.comment_location.empty?

    raw = klass.comment_location.map { |comment, _| raw_comment_text(comment) }.join("\n\n")
    result = excerpt(raw)
    result.empty? ? fallback : result
  end

  ##
  # Extracts a short description for a page file for use in llms.txt

  def file_excerpt(file)
    fallback = file.page_name || file.base_name
    return fallback unless file.comment

    result = excerpt(raw_comment_text(file.comment))
    result.empty? ? fallback : result
  end

  ##
  # Extracts raw text from a comment without formatting through ToMarkdown.

  def raw_comment_text(comment)
    case comment
    when RDoc::Comment then comment.text
    when String then comment
    else ""
    end
  end

  def debug_msg(msg)
    $stderr.puts msg if $DEBUG_RDOC
  end
end
