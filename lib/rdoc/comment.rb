# frozen_string_literal: true
##
# A comment holds the text comment for a RDoc::CodeObject and provides a
# unified way of cleaning it up and parsing it into an RDoc::Markup::Document.
#
# Each comment may have a different markup format set by #format=.  By default
# 'rdoc' is used.  The :markup: directive tells RDoc which format to use.
#
# See {RDoc Markup Reference}[rdoc-ref:doc/markup_reference/rdoc.rdoc@Directive+for+Specifying+RDoc+Source+Format].


class RDoc::Comment

  include RDoc::Text

  ##
  # The format of this comment.  Defaults to RDoc::Markup

  attr_reader :format

  ##
  # The source this comment was read from.  This is usually an
  # RDoc::TopLevel.  A comment loaded from a generated document without a file
  # uses that RDoc::Markup::Document as its source.

  attr_reader :markup_source

  ##
  # Line where this Comment was written

  attr_accessor :line

  ##
  # The text for this comment.

  attr_reader :text

  ##
  # Alias for text.

  alias to_s text

  ##
  # Creates a new comment with +text+ from +markup_source+.

  def initialize(text = nil, markup_source:, language: nil, format: 'rdoc', normalized: false)
    raise ArgumentError, 'markup_source is required' unless markup_source

    @markup_source = markup_source
    @text         = text.nil? ? nil : text.dup
    @language     = language

    @document   = nil
    @format     = format
    @normalized = normalized
  end

  ##
  #--
  # TODO deep copy @document

  def initialize_copy(copy) # :nodoc:
    @text = copy.text&.dup
  end

  def ==(other) # :nodoc:
    self.class === other and
      other.text == @text and other.location == location
  end

  ##
  # A comment is empty if its text String is empty.

  def empty?
    @text.to_s.empty? && (@document.nil? || @document.empty?)
  end

  ##
  # HACK dubious

  def encode!(encoding)
    @text = String.new @text, encoding: encoding
    self
  end

  ##
  # Sets the format of this comment and resets its parsed document.

  def format=(format)
    @format = format
    @document = nil
  end

  ##
  # Sets the language of this comment and resets its parsed document.

  def language=(language)
    @language = language
    @document = nil
  end

  ##
  # The RDoc::TopLevel this comment was found in.

  def location
    return @markup_source if RDoc::TopLevel === @markup_source
    return @location if defined?(@location)

    file = @markup_source.file if @markup_source.respond_to?(:file)
    @location = RDoc::TopLevel.new(file) if file
  end

  ##
  # For duck-typing when merging classes at load time.

  alias file location # :nodoc:

  def inspect # :nodoc:
    location = self.location
    relative_name = location ? location.relative_name : '(unknown)'

    "#<%s:%x %s %p>" % [self.class, object_id, relative_name, @text]
  end

  ##
  # Normalizes the text.  See RDoc::Text#normalize_comment for details

  def normalize
    return self unless @text
    return self if @normalized # TODO eliminate duplicate normalization

    text = normalize_comment @text
    @document = nil if text != @text
    @text = text

    @normalized = true

    self
  end

  # Change normalized, when creating already normalized comment.

  def normalized=(value)
    @normalized = value
  end

  ##
  # Was this text normalized?

  def normalized? # :nodoc:
    @normalized
  end

  ##
  # Parses the comment into an RDoc::Markup::Document.  The parsed document is
  # cached until the text, format, or language changes.

  def parse
    return @document if @document

    @document = super @text, @format
    @document.file = location if location
    @document
  end

  ##
  # Replaces this comment's text with +text+ and resets the parsed document.
  #
  # An error is raised if the comment contains a document but no text.

  def text=(text)
    raise RDoc::Error, 'replacing document-only comment is not allowed' if
      @text.nil? and @document

    @document = nil
    @normalized = false
    @text = text.nil? ? nil : text.dup
  end

  ##
  # Returns true if this comment is in TomDoc format.

  def tomdoc?
    @format == 'tomdoc'
  end

  MULTILINE_DIRECTIVES = %w[call-seq].freeze # :nodoc:

  # There are more, but already handled by RDoc::Parser::C
  COLON_LESS_DIRECTIVES = %w[call-seq Document-method].freeze # :nodoc:

  DIRECTIVE_OR_ESCAPED_DIRECTIV_REGEXP = /\A(?<colon>\\?:|:?)(?<directive>[\w-]+):(?<param>.*)/

  private_constant :MULTILINE_DIRECTIVES, :COLON_LESS_DIRECTIVES, :DIRECTIVE_OR_ESCAPED_DIRECTIV_REGEXP

  class << self

    ##
    # Creates a comment from an already parsed +document+.

    def from_document(document, text: '', markup_source: nil, language: nil, format: 'rdoc', normalized: false) # :nodoc:
      markup_source ||= if document.file
                          RDoc::TopLevel.new document.file
                        else
                          document
                        end

      comment = new(
        text,
        markup_source: markup_source,
        language: language,
        format: format,
        normalized: normalized
      )
      comment.normalize
      comment.instance_variable_set :@document, document
      comment
    end

    # Parse comment, collect directives as an attribute and return [normalized_comment_text, directives_hash]
    # This method expands include and removes everything not needed in the document text, such as
    # private section, directive line, comment characters `# /* * */` and indent spaces.
    #
    # RDoc comment consists of include, directive, multiline directive, private section and comment text.
    #
    # Include
    #   # :include: filename
    #
    # Directive
    #   # :directive-without-value:
    #   # :directive-with-value: value
    #
    # Multiline directive (only :call-seq:)
    #   # :multiline-directive:
    #   #   value1
    #   #   value2
    #
    # Private section
    #   #--
    #   # private comment
    #   #++

    def parse(text, filename, line_no, type, &include_callback)
      case type
      when :ruby
        text = text.gsub(/^#+/, '') if text.start_with?('#')
        private_start_regexp = /^-{2,}$/
        private_end_regexp = /^\+{2}$/
        indent_regexp = /^\s*/
      when :c
        private_start_regexp = /^(\s*\*)?-{2,}$/
        private_end_regexp = /^(\s*\*)?\+{2}$/
        indent_regexp = /^\s*(\/\*+|\*)?\s*/
        text = text.gsub(/\s*\*+\/\s*\z/, '')
      when :simple
        # Unlike other types, this implementation only looks for two dashes at
        # the beginning of the line. Three or more dashes are considered to be
        # a rule and ignored.
        private_start_regexp = /^-{2}$/
        private_end_regexp = /^\+{2}$/
        indent_regexp = /^\s*/
      end

      directives = {}
      lines = text.split("\n")
      in_private = false
      comment_lines = []
      until lines.empty?
        line = lines.shift
        read_lines = 1
        if in_private
          # If `++` appears in a private section that starts with `--`, private section ends.
          in_private = false if line.match?(private_end_regexp)
          line_no += read_lines
          next
        elsif line.match?(private_start_regexp)
          # If `--` appears in a line, private section starts.
          in_private = true
          line_no += read_lines
          next
        end

        prefix = line[indent_regexp]
        prefix_indent = ' ' * prefix.size
        line = line.byteslice(prefix.bytesize..)

        if (directive_match = DIRECTIVE_OR_ESCAPED_DIRECTIV_REGEXP.match(line))
          colon = directive_match[:colon]
          directive = directive_match[:directive]
          raw_param = directive_match[:param]
          param = raw_param.strip
        else
          colon = directive = raw_param = param = nil
        end

        if !directive
          comment_lines << prefix_indent + line
        elsif colon == '\\:'
          # If directive is escaped, unescape it
          comment_lines << prefix_indent + line.sub('\\:', ':')
        elsif raw_param.start_with?(':') || (colon.empty? && !COLON_LESS_DIRECTIVES.include?(directive))
          # Something like `:toto::` is not a directive
          # Only few directives allows to start without a colon
          comment_lines << prefix_indent + line
        elsif directive == 'include'
          filename_to_include = param
          include_callback.call(filename_to_include, prefix_indent).lines.each { |l| comment_lines << l.chomp }
        elsif MULTILINE_DIRECTIVES.include?(directive)
          value_lines = take_multiline_directive_value_lines(directive, filename, line_no, lines, prefix_indent.size, indent_regexp, !param.empty?)
          read_lines += value_lines.size
          lines.shift(value_lines.size)
          unless param.empty?
            # Accept `:call-seq: first-line\n  second-line` for now
            value_lines.unshift(param)
          end
          value = value_lines.join("\n")
          directives[directive] = [value.empty? ? nil : value, line_no]
        else
          directives[directive] = [param.empty? ? nil : param, line_no]
        end
        line_no += read_lines
      end

      normalized_comment = String.new(encoding: text.encoding) << normalize_comment_lines(comment_lines).join("\n")
      [normalized_comment, directives]
    end

    # Remove preceding indent spaces and blank lines from the comment lines

    private def normalize_comment_lines(lines)
      blank_line_regexp = /\A\s*\z/
      lines = lines.dup
      lines.shift while lines.first&.match?(blank_line_regexp)
      lines.pop while lines.last&.match?(blank_line_regexp)

      min_spaces = lines.map do |l|
        l.match(/\A *(?=\S)/)&.end(0)
      end.compact.min
      if min_spaces && min_spaces > 0
        lines.map { |l| l[min_spaces..] || '' }
      else
        lines
      end
    end

    # Take value lines of multiline directive

    private def take_multiline_directive_value_lines(directive, filename, line_no, lines, base_indent_size, indent_regexp, has_param)
      return [] if lines.empty?

      first_indent_size = lines.first.match(indent_regexp).end(0)

      # Blank line or unindented line is not part of multiline-directive value
      return [] if first_indent_size <= base_indent_size

      if has_param
        # :multiline-directive: line1
        #   line2
        #   line3
        #
        value_lines = lines.take_while do |l|
          l.rstrip.match(indent_regexp).end(0) > base_indent_size
        end
        min_indent = value_lines.map { |l| l.match(indent_regexp).end(0) }.min
        value_lines.map { |l| l[min_indent..] }
      else
        # Take indented lines accepting blank lines between them
        value_lines = lines.take_while do |l|
          l = l.rstrip
          indent = l[indent_regexp]
          if indent == l || indent.size >= first_indent_size
            true
          end
        end
        value_lines.map! { |l| (l[first_indent_size..] || '').chomp }

        if value_lines.size != lines.size && !value_lines.last.empty?
          warn "#{filename}:#{line_no} Multiline directive :#{directive}: should end with a blank line."
        end
        value_lines.pop while value_lines.last&.empty?
        value_lines
      end
    end
  end
end
