# frozen_string_literal: true

require 'prism'
require_relative '../rbs_helper'

# Parse and collect document from Ruby source code.

##
# Extracts code elements from a source file returning a TopLevel object
# containing the constituent file elements.
#
# RubyParser understands how to document:
# * classes
# * modules
# * methods
# * constants
# * aliases
# * private, public, protected
# * private_class_function, public_class_function
# * private_constant, public_constant
# * module_function
# * attr, attr_reader, attr_writer, attr_accessor
# * extra accessors given on the command line
# * metaprogrammed methods
# * require
# * include
#
# == Method Arguments
#
# The parser extracts the arguments from the method definition.  You can
# override this with a custom argument definition using the :args: directive:
#
#   ##
#   # This method tries over and over until it is tired
#
#   def go_go_go(thing_to_try, tries = 10) # :args: thing_to_try
#     puts thing_to_try
#     go_go_go thing_to_try, tries - 1
#   end
#
# If you have a more-complex set of overrides you can use the :call-seq:
# directive:
#
#   ##
#   # This method can be called with a range or an offset and length
#   #
#   # :call-seq:
#   #   my_method(Range)
#   #   my_method(offset, length)
#
#   def my_method(*args)
#   end
#
# The parser extracts +yield+ expressions from method bodies to gather the
# yielded argument names.  If your method manually calls a block instead of
# yielding or you want to override the discovered argument names use
# the :yields: directive:
#
#   ##
#   # My method is awesome
#
#   def my_method(&block) # :yields: happy, times
#     block.call 1, 2
#   end
#
# == Metaprogrammed Methods
#
# To pick up a metaprogrammed method, the parser looks for a comment starting
# with '##' before a metaprogramming method call:
#
#   ##
#   # This is a meta-programmed method!
#
#   add_my_method :meta_method, :arg1, :arg2
#
# The parser looks at the first argument to determine the name, in
# this example, :meta_method.  If a name cannot be found, a warning is printed
# and 'unknown' is used.
#
# You can force the name of a method using the :method: directive:
#
#   ##
#   # :method: some_method!
#
# By default, meta-methods are instance methods.  To indicate that a method is
# a singleton method instead use the :singleton-method: directive:
#
#   ##
#   # :singleton-method:
#
# You can also use the :singleton-method: directive with a name:
#
#   ##
#   # :singleton-method: some_method!
#
# You can define arguments for metaprogrammed methods via either the
# \:call-seq:, :arg: or :args: directives.
#
# Additionally you can mark a method as an attribute by
# using :attr:, :attr_reader:, :attr_writer: or :attr_accessor:.  Just like
# for :method:, the name is optional.
#
#   ##
#   # :attr_reader: my_attr_name
#
# == Hidden methods and attributes
#
# You can provide documentation for methods that don't appear using
# the :method:, :singleton-method: and :attr: directives:
#
#   ##
#   # :attr_writer: ghost_writer
#   # There is an attribute here, but you can't see it!
#
#   ##
#   # :method: ghost_method
#   # There is a method here, but you can't see it!
#
#   ##
#   # this is a comment for a regular method
#
#   def regular_method() end
#
# Note that by default, the :method: directive will be ignored if there is a
# standard rdocable item following it.

class RDoc::Parser::Ruby < RDoc::Parser

  parse_files_matching(/\.rbw?$/)

  # Matches an RBS inline type annotation line: #: followed by whitespace
  RBS_SIG_LINE = /\A#:\s/ # :nodoc:

  attr_accessor :visibility
  attr_reader :singleton, :in_proc_block

  def initialize(top_level, content, options, stats)
    super

    content = handle_tab_width(content)

    @size = 0
    @token_listeners = nil
    content = RDoc::Encoding.remove_magic_comment content
    @content = content
    @markup = @options.markup
    @track_visibility = :nodoc != @options.visibility
    @encoding = @options.encoding

    # IR records emitted while visiting the AST, replayed by CodeObjectBuilder.
    # Records must be plain data (no AST node or CodeObject references)
    # so that the IR can be compared and serialized.
    @ir = []
    @scope_id = 0
    @scope_depth = 0
    @visibility = :public
    @singleton = false
    @in_proc_block = false
    @doc_state = :startdoc
  end

  # Applies document control directives (:startdoc:, :stopdoc: and :enddoc:)
  # to the current lexical scope. The state is restored when the enclosing
  # class/module scope is closed.
  # Returns true if a :startdoc: directive took effect. Its model-side effect
  # (reviving an ignored container) is replayed by CodeObjectBuilder from the
  # startdoc flag of the comment payload.

  def apply_document_control_directive(directives)
    startdoc = false
    directives.each do |directive, (_param, line)|
      case directive
      when 'startdoc', 'stopdoc'
        # :enddoc: cannot be cancelled within the scope, even by :startdoc:
        if @doc_state == :enddoc
          @options.warn "#{@top_level.relative_name}:#{line}: :startdoc: is ignored after :enddoc:" if directive == 'startdoc'
          next
        end
        @doc_state = directive.to_sym
        startdoc = true if directive == 'startdoc'
      when 'enddoc'
        @doc_state = :enddoc
      end
    end
    startdoc
  end

  # Returns true if code objects at the current position should not be
  # documented, that is, inside a :stopdoc: or :enddoc: region.

  def document_suppressed?
    @track_visibility && @doc_state != :startdoc
  end

  # Suppress `extend` and `include` within block
  # because they might be a metaprogramming block
  # example: `Module.new { include M }` `M.module_eval { include N }`

  def with_in_proc_block
    in_proc_block = @in_proc_block
    @in_proc_block = true
    yield
    @in_proc_block = in_proc_block
  end

  # Dive into another scope opened by the record of the given scope id

  def with_scope(scope_id, singleton: false)
    old_visibility = @visibility
    old_singleton = @singleton
    old_in_proc_block = @in_proc_block
    old_doc_state = @doc_state
    @visibility = :public
    @singleton = singleton
    @in_proc_block = false
    @scope_depth += 1
    emit({type: :scope_enter, id: scope_id, singleton: singleton})
    yield
  ensure
    emit({type: :scope_exit})
    @visibility = old_visibility
    @singleton = old_singleton
    @in_proc_block = old_in_proc_block
    @doc_state = old_doc_state
    @scope_depth -= 1
  end

  # Scans this Ruby file for Ruby constructs

  def scan
    @lines = @content.lines
    result = Prism.parse_lex(@content)
    @program_node, unordered_tokens = result.value
    # Heredoc tokens are not in start_offset order.
    # Need to sort them to use bsearch for finding tokens from location.
    @prism_tokens = unordered_tokens.map(&:first).sort_by { |t| t.location.start_offset }
    @line_nodes = {}
    prepare_line_nodes(@program_node)
    prepare_comments(result.comments)
    return if @top_level.done_documenting

    @first_non_meta_comment_start_line = nil
    if (_line_no, start_line = @unprocessed_comments.first)
      @first_non_meta_comment_start_line = start_line if start_line < @program_node.location.start_line
    end

    @program_node.accept(RDocVisitor.new(self, @top_level, @store))
    process_comments_until(@lines.size + 1)

    builder = CodeObjectBuilder.new(@top_level, @store, @options, @stats, @preprocess, track_visibility: @track_visibility)
    builder.run(@ir)
    @top_level
  end

  # Assign AST node to a line.
  # This is used to show meta-method source code in the documentation.

  def prepare_line_nodes(node) # :nodoc:
    case node
    when Prism::CallNode, Prism::DefNode
      @line_nodes[node.location.start_line] ||= node
    end
    node.compact_child_nodes.each do |child|
      prepare_line_nodes(child)
    end
  end

  # Prepares comments for processing. Comments are grouped into consecutive.
  # Consecutive comment is linked to the next non-blank line.
  #
  # Example:
  #   01| class A # modifier comment 1
  #   02|   def foo; end # modifier comment 2
  #   03|
  #   04|   # consecutive comment 1 start_line: 4
  #   05|   # consecutive comment 1 linked to line: 7
  #   06|
  #   07|   # consecutive comment 2 start_line: 7
  #   08|   # consecutive comment 2 linked to line: 10
  #   09|
  #   10|   def bar; end # consecutive comment 2 linked to this line
  #   11| end

  def prepare_comments(comments)
    current = []
    consecutive_comments = [current]
    @modifier_comments = {}
    comments.each do |comment|
      if comment.is_a? Prism::EmbDocComment
        consecutive_comments << [comment] << (current = [])
      elsif comment.location.start_line_slice.match?(/\S/)
        text = comment.slice
        text = RDoc::Encoding.change_encoding(text, @encoding) if @encoding
        @modifier_comments[comment.location.start_line] = text
      elsif current.empty? || current.last.location.end_line + 1 == comment.location.start_line
        current << comment
      else
        consecutive_comments << (current = [comment])
      end
    end
    consecutive_comments.reject!(&:empty?)

    # Example: line_no = 5, start_line = 2, comment_text = "# comment_start_line\n# comment\n"
    # 1| class A
    # 2|   # comment_start_line
    # 3|   # comment
    # 4|
    # 5|   def f; end # comment linked to this line
    # 6| end
    @unprocessed_comments = consecutive_comments.map! do |comments|
      start_line = comments.first.location.start_line
      line_no = comments.last.location.end_line + (comments.last.location.end_column == 0 ? 0 : 1)
      texts = comments.map do |c|
        c.is_a?(Prism::EmbDocComment) ? c.slice.lines[1...-1].join : c.slice
      end
      text = texts.join("\n")
      text = RDoc::Encoding.change_encoding(text, @encoding) if @encoding
      line_no += 1 while @lines[line_no - 1]&.match?(/\A\s*$/)
      [line_no, start_line, text]
    end

    # The first comment is special. It defines markup for the rest of the comments.
    _, first_comment_start_line, first_comment_text = @unprocessed_comments.first
    if first_comment_text && @lines[0...first_comment_start_line - 1].all? { |l| l.match?(/\A\s*$/) }
      _text, directives = @preprocess.parse_comment(first_comment_text, first_comment_start_line, :ruby)
      markup, = directives['markup']
      @markup = markup.downcase if markup
    end
  end

  def has_modifier_nodoc?(line_no) # :nodoc:
    @modifier_comments[line_no]&.match?(/\A#\s*:nodoc:/)
  end

  # Parses the modifier comment on the given line into a directives hash

  def modifier_directives(line_no) # :nodoc:
    if (comment_text = @modifier_comments[line_no])
      _text, directives = @preprocess.parse_comment(comment_text, line_no, :ruby)
      directives
    end
  end

  def call_node_name_arguments(call_node) # :nodoc:
    return [] unless call_node.arguments
    call_node.arguments.arguments.map do |arg|
      case arg
      when Prism::SymbolNode
        arg.value
      when Prism::StringNode
        arg.unescaped
      end
    end || []
  end

  # Emits a meta method comment record

  def emit_meta_comment(comment_payload, node)
    if node
      node_payload = {
        is_call_node: node.is_a?(Prism::CallNode),
        name_arguments: node.is_a?(Prism::CallNode) ? call_node_name_arguments(node) : [],
        tokens: syntax_highlighted_tokens(node),
        start_line: node.location.start_line
      }
    end
    emit({type: :meta_comment, comment: comment_payload, node: node_payload,
          visibility: @visibility, singleton: @singleton, suppressed: document_suppressed?})
  end

  INVALID_GHOST_METHOD_ACCEPT_DIRECTIVE_LIST = %w[
    method singleton-method attr attr_reader attr_writer attr_accessor
  ].freeze
  private_constant :INVALID_GHOST_METHOD_ACCEPT_DIRECTIVE_LIST

  def normal_comment_treat_as_ghost_method_for_now?(directives, line_no) # :nodoc:
    # Meta method comment should start with `##` but some comments does not follow this rule.
    # For now, RDoc accepts them as a meta method comment if there is no node linked to it.
    !@line_nodes[line_no] && INVALID_GHOST_METHOD_ACCEPT_DIRECTIVE_LIST.any? { |directive| directives.has_key?(directive) }
  end

  def handle_standalone_consecutive_comment_directive(comment_payload, start_with_sharp_sharp, line_no, start_line) # :nodoc:
    if start_with_sharp_sharp && start_line != @first_non_meta_comment_start_line
      emit_meta_comment(comment_payload, @line_nodes[line_no])
    elsif normal_comment_treat_as_ghost_method_for_now?(comment_payload[:directives], line_no) && start_line != @first_non_meta_comment_start_line
      emit_meta_comment(comment_payload, nil)
    else
      emit({type: :container_directives, comment: comment_payload})
    end
  end

  # Processes consecutive comments that were not linked to any documentable code until the given line number

  def process_comments_until(line_no_until)
    while !@unprocessed_comments.empty? && @unprocessed_comments.first[0] <= line_no_until
      line_no, start_line, text = @unprocessed_comments.shift
      if @markup == 'tomdoc'
        node = @line_nodes[line_no]
        emit({type: :tomdoc_comment, text: text, start_line: start_line, suppressed: document_suppressed?,
              tokens: node ? syntax_highlighted_tokens(node) : []})
      elsif (comment_payload = parse_comment_payload(text, start_line))
        handle_standalone_consecutive_comment_directive(comment_payload, text.start_with?(/#\#$/), line_no, start_line)
      end
    end
  end

  # Skips all undocumentable consecutive comments until the given line number.
  # Undocumentable comments are comments written inside `def` or inside undocumentable class/module

  def skip_comments_until(line_no_until)
    while !@unprocessed_comments.empty? && @unprocessed_comments.first[0] <= line_no_until
      @unprocessed_comments.shift
    end
  end

  # Consumes the consecutive comment linked to the given line number and
  # returns its payload

  def consecutive_comment_payload(line_no)
    return unless @unprocessed_comments.first&.first == line_no
    _line_no, start_line, text = @unprocessed_comments.shift
    parse_comment_payload(text, start_line)
  end

  # Parses comment text into a plain-data payload for IR records, or returns
  # +nil+ if the comment is a section header (which is emitted as its own
  # record and has no associated code object).

  def parse_comment_payload(comment_text, start_line) # :nodoc:
    type_signature_lines, type_signature_line_no = extract_type_signature!(comment_text, start_line)
    comment_text, directives = @preprocess.parse_comment(comment_text, start_line, :ruby)
    markup, = directives['markup']
    format = markup&.downcase || @markup
    if (section, directive_line = directives['section'])
      # If comment has :section:, it is not a documentable comment for a code object
      text = extract_section_comment(comment_text, directive_line - start_line)
      emit({type: :section, title: section, text: text, start_line: start_line, format: format,
            type_signature_lines: type_signature_lines, type_signature_line_no: type_signature_line_no})
      return
    end
    startdoc = apply_document_control_directive(directives)
    {text: comment_text, start_line: start_line, format: format, directives: directives, startdoc: startdoc,
     type_signature_lines: type_signature_lines, type_signature_line_no: type_signature_line_no}
  end

  # Extracts the comment for this section from the normalized comment block.
  # Removes all lines before the line that contains :section:
  # If the comment also ends with the same content, remove it as well

  def extract_section_comment(comment_text, prefix_line_count) # :nodoc:
    prefix = comment_text.lines[0...prefix_line_count].join
    comment_text.delete_prefix!(prefix)
    # Comment is already normalized and doesn't end with a newline
    comment_text.delete_suffix!(prefix.chomp)
    comment_text
  end

  # Returns syntax highlighted tokens of the given node

  def syntax_highlighted_tokens(node)
    RDoc::Parser::RubyColorizer.partial_colorize(@content, node, @prism_tokens)
  end

  # Handles `public :foo, :bar` `private :foo, :bar` and `protected :foo, :bar`

  def change_method_visibility(names, visibility, singleton: @singleton)
    emit({type: :change_method_visibility, names: names, visibility: visibility, singleton: singleton,
          suppressed: document_suppressed?})
  end

  # Handles `module_function :foo, :bar`

  def change_method_to_module_function(names)
    emit({type: :module_function, names: names, suppressed: document_suppressed?})
  end

  # Handles `alias foo bar` and `alias_method :foo, :bar`

  def add_alias_method(old_name, new_name, line_no)
    comment = consecutive_comment_payload(line_no)
    emit({type: :alias_method, old_name: old_name, new_name: new_name, line_no: line_no,
          singleton: @singleton, suppressed: document_suppressed?,
          comment: comment, modifier_directives: modifier_directives(line_no)})
  end

  # Handles `attr :a, :b`, `attr_reader :a, :b`, `attr_writer :a, :b` and `attr_accessor :a, :b`

  def add_attributes(names, rw, line_no)
    comment = consecutive_comment_payload(line_no)
    emit({type: :attributes, names: names, rw: rw, line_no: line_no, singleton: @singleton,
          visibility: @visibility, suppressed: document_suppressed?,
          comment: comment, modifier_directives: modifier_directives(line_no)})
  end

  # Handle `include Foo, Bar`

  def add_includes(names, line_no) # :nodoc:
    comment = consecutive_comment_payload(line_no)
    emit({type: :include, names: names, line_no: line_no, suppressed: document_suppressed?, comment: comment})
  end

  # Handle `extend Foo, Bar`

  def add_extends(names, line_no) # :nodoc:
    comment = consecutive_comment_payload(line_no)
    emit({type: :extend, names: names, line_no: line_no, suppressed: document_suppressed?, comment: comment})
  end

  # Adds a method defined by `def` syntax

  def add_method(method_name, receiver_name:, receiver_fallback_type:, visibility:, singleton:, params:, calls_super:, block_params:, tokens:, start_line:, args_end_line:, end_line:)
    comment = consecutive_comment_payload(start_line)
    modifier_directives_list = [start_line, args_end_line, end_line].uniq.filter_map { |line| modifier_directives(line) }
    emit({type: :method, name: method_name, receiver_name: receiver_name, receiver_fallback_type: receiver_fallback_type,
          visibility: visibility, singleton: singleton, params: params, calls_super: calls_super,
          block_params: block_params, tokens: tokens, line_no: start_line, suppressed: document_suppressed?,
          comment: comment, modifier_directives_list: modifier_directives_list})
  end

  # Adds a constant

  def add_constant(constant_name, rhs_name, start_line, end_line, alias_path: nil)
    comment = consecutive_comment_payload(start_line)
    modifier_directives_list = [modifier_directives(start_line), modifier_directives(end_line)].compact
    emit({type: :constant, constant_name: constant_name, rhs_name: rhs_name, line_no: start_line,
          alias_path: alias_path, suppressed: document_suppressed?,
          comment: comment, modifier_directives_list: modifier_directives_list})
  end

  # Emits a scope-opening record for a module or class and returns its scope
  # id, or nil if the body should not be visited

  def add_module_or_class(module_name, start_line, end_line, is_class: false, superclass_name: nil, superclass_expr: nil)
    comment = consecutive_comment_payload(start_line)
    modifier_directives_list = [modifier_directives(start_line), modifier_directives(end_line)].compact
    id = (@scope_id += 1)
    emit({type: :scope_open, id: id, kind: is_class ? :class : :module, name: module_name,
          line_no: start_line, superclass_name: superclass_name, superclass_expr: superclass_expr,
          suppressed: document_suppressed?,
          comment: comment, modifier_directives_list: modifier_directives_list})
    # RDoc doesn't track constants of a singleton class, so a bare-named module
    # or class inside `class << C` has no place to belong to
    return if @singleton && !module_name.include?('::')
    id
  end

  # Emits a scope-opening record for `class << (Name = Object.new)` and returns its scope id

  def singleton_scope_for_constant_write(name)
    id = (@scope_id += 1)
    emit({type: :singleton_scope_constant_write, id: id, name: name, suppressed: document_suppressed?})
    id
  end

  # Emits a scope-opening record for `class << ConstantPath` and returns its scope id

  def singleton_scope_for_path(expression_name)
    id = (@scope_id += 1)
    emit({type: :singleton_scope_path, id: id, name: expression_name, suppressed: document_suppressed?})
    id
  end

  # Emits a scope-opening record for `class << self` and returns its scope id,
  # or nil at the top level

  def singleton_scope_for_self
    return if @scope_depth == 0
    id = (@scope_id += 1)
    emit({type: :singleton_scope_self, id: id})
    id
  end

  # Handles `require 'foo'`

  def add_require(name)
    emit({type: :require, name: name})
  end

  # Handles `private_constant :FOO` and `public_constant :FOO`

  def set_constant_visibility(names, visibility)
    emit({type: :constant_visibility, names: names, visibility: visibility})
  end

  private

  def emit(record)
    @ir << record
    record
  end

  # Extracts RBS type signature lines (#: ...) from raw comment text.
  # Mutates the input text to remove the extracted lines.
  # Returns +[type_signature_lines, first_sig_line]+, or nil if none are
  # found. The lines array may contain multiple lines for overloaded
  # signatures. Validation happens in CodeObjectBuilder so that comments consumed in
  # an undocumentable scope don't warn.

  def extract_type_signature!(text, start_line)
    return nil unless text.include?('#:')

    lines = text.lines
    sig_lines, doc_lines = lines.partition { |l| l.match?(RBS_SIG_LINE) }
    return nil if sig_lines.empty?

    first_sig_line = start_line + lines.index(sig_lines.first)
    text.replace(doc_lines.join)
    type_signature_lines = sig_lines.map { |l| l.sub(RBS_SIG_LINE, '').strip }.reject(&:empty?)
    return nil if type_signature_lines.empty?

    [type_signature_lines, first_sig_line]
  end

  class RDocVisitor < Prism::Visitor # :nodoc:
    def initialize(scanner, top_level, store)
      @scanner = scanner
      @top_level = top_level
      @store = store
    end

    def visit_if_node(node)
      if node.end_keyword
        super
      else
        # Visit with the order in text representation to handle this method comment
        # # comment
        # def f
        # end if call_node
        node.statements.accept(self)
        node.predicate.accept(self)
      end
    end
    alias visit_unless_node visit_if_node

    def visit_call_node(node)
      @scanner.process_comments_until(node.location.start_line - 1)
      if node.receiver.nil?
        case node.name
        when :attr
          _visit_call_attr_reader_writer_accessor(node, 'R')
        when :attr_reader
          _visit_call_attr_reader_writer_accessor(node, 'R')
        when :attr_writer
          _visit_call_attr_reader_writer_accessor(node, 'W')
        when :attr_accessor
          _visit_call_attr_reader_writer_accessor(node, 'RW')
        when :include
          _visit_call_include(node)
        when :extend
          _visit_call_extend(node)
        when :public
          super
          _visit_call_public_private_protected(node, :public)
        when :private
          super
          _visit_call_public_private_protected(node, :private)
        when :protected
          super
          _visit_call_public_private_protected(node, :protected)
        when :private_constant
          _visit_call_private_constant(node)
        when :public_constant
          _visit_call_public_constant(node)
        when :require
          _visit_call_require(node)
        when :alias_method
          _visit_call_alias_method(node)
        when :module_function
          super
          _visit_call_module_function(node)
        when :public_class_method
          super
          _visit_call_public_private_class_method(node, :public)
        when :private_class_method
          super
          _visit_call_public_private_class_method(node, :private)
        else
          super
        end
      else
        super
      end
    end

    def visit_block_node(node)
      @scanner.with_in_proc_block do
        # include, extend and method definition inside block are not documentable.
        # visibility methods and attribute definition methods should be ignored inside block.
        super
      end
    end

    def visit_alias_method_node(node)
      return if @scanner.in_proc_block
      @scanner.process_comments_until(node.location.start_line - 1)
      return unless node.old_name.is_a?(Prism::SymbolNode) && node.new_name.is_a?(Prism::SymbolNode)
      @scanner.add_alias_method(node.old_name.value.to_s, node.new_name.value.to_s, node.location.start_line)
    end

    def visit_module_node(node)
      node.constant_path.accept(self)
      @scanner.process_comments_until(node.location.start_line - 1)
      module_name = constant_path_string(node.constant_path)
      scope_id = @scanner.add_module_or_class(module_name, node.location.start_line, node.location.end_line) if module_name
      if scope_id
        @scanner.with_scope(scope_id) do
          node.body&.accept(self)
          @scanner.process_comments_until(node.location.end_line)
        end
      else
        @scanner.skip_comments_until(node.location.end_line)
      end
    end

    def visit_class_node(node)
      node.constant_path.accept(self)
      node.superclass&.accept(self)
      @scanner.process_comments_until(node.location.start_line - 1)
      superclass_name = constant_path_string(node.superclass) if node.superclass
      superclass_expr = node.superclass.slice if node.superclass && !superclass_name
      class_name = constant_path_string(node.constant_path)
      scope_id = @scanner.add_module_or_class(class_name, node.location.start_line, node.location.end_line, is_class: true, superclass_name: superclass_name, superclass_expr: superclass_expr) if class_name
      if scope_id
        @scanner.with_scope(scope_id) do
          node.body&.accept(self)
          @scanner.process_comments_until(node.location.end_line)
        end
      else
        @scanner.skip_comments_until(node.location.end_line)
      end
    end

    def visit_singleton_class_node(node)
      # A comment linked to the `class << ...` line (e.g. a document control
      # directive) belongs to the enclosing scope, not to the singleton scope
      @scanner.process_comments_until(node.location.start_line)

      if @scanner.has_modifier_nodoc?(node.location.start_line)
        # Skip visiting inside the singleton class. Also skips creation of node.expression as a module
        @scanner.skip_comments_until(node.location.end_line)
        return
      end

      expression = node.expression
      expression = expression.body.body.first if expression.is_a?(Prism::ParenthesesNode) && expression.body&.body&.size == 1

      case expression
      when Prism::ConstantWriteNode
        scope_id = @scanner.singleton_scope_for_constant_write(expression.name.to_s)
      when Prism::ConstantPathNode, Prism::ConstantReadNode
        expression_name = constant_path_string(expression)
        scope_id = @scanner.singleton_scope_for_path(expression_name) if expression_name
      when Prism::SelfNode
        scope_id = @scanner.singleton_scope_for_self
      end
      expression.accept(self)
      if scope_id
        @scanner.with_scope(scope_id, singleton: true) do
          node.body&.accept(self)
          @scanner.process_comments_until(node.location.end_line)
        end
      else
        @scanner.skip_comments_until(node.location.end_line)
      end
    end

    def visit_def_node(node)
      start_line = node.location.start_line
      args_end_line = node.parameters&.location&.end_line || start_line
      end_line = node.location.end_line
      @scanner.process_comments_until(start_line - 1)

      return if @scanner.in_proc_block

      case node.receiver
      when Prism::NilNode, Prism::TrueNode, Prism::FalseNode
        visibility = :public
        singleton = false
        receiver_name =
          case node.receiver
          when Prism::NilNode
            'NilClass'
          when Prism::TrueNode
            'TrueClass'
          when Prism::FalseNode
            'FalseClass'
          end
        receiver_fallback_type = :class
      when Prism::SelfNode
        # singleton method of a singleton class is not documentable
        return if @scanner.singleton
        visibility = :public
        singleton = true
      when Prism::ConstantReadNode, Prism::ConstantPathNode
        visibility = :public
        singleton = true
        receiver_name = constant_path_string(node.receiver)
        receiver_fallback_type = :module
        return unless receiver_name
      when nil
        visibility = @scanner.visibility
        singleton = @scanner.singleton
      else
        # `def (unknown expression).method_name` is not documentable
        return
      end
      name = node.name.to_s
      params, block_params, calls_super = MethodSignatureVisitor.scan_signature(node)
      tokens = @scanner.syntax_highlighted_tokens(node)

      @scanner.add_method(
        name,
        receiver_name: receiver_name,
        receiver_fallback_type: receiver_fallback_type,
        visibility: visibility,
        singleton: singleton,
        params: params,
        block_params: block_params,
        calls_super: calls_super,
        tokens: tokens,
        start_line: start_line,
        args_end_line: args_end_line,
        end_line: end_line
      )
    ensure
      @scanner.skip_comments_until(end_line)
    end

    def visit_constant_path_write_node(node)
      @scanner.process_comments_until(node.location.start_line - 1)
      path = constant_path_string(node.target)
      return unless path

      alias_path = constant_path_string(node.value)
      @scanner.add_constant(
        path,
        alias_path || node.value.slice,
        node.location.start_line,
        node.location.end_line,
        alias_path: alias_path
      )
      @scanner.skip_comments_until(node.location.end_line)
      # Do not traverse rhs not to document `A::B = Struct.new{def undocumentable_method; end}`
    end

    def visit_constant_write_node(node)
      @scanner.process_comments_until(node.location.start_line - 1)
      alias_path = constant_path_string(node.value)
      @scanner.add_constant(
        node.name.to_s,
        alias_path || node.value.slice,
        node.location.start_line,
        node.location.end_line,
        alias_path: alias_path
      )
      @scanner.skip_comments_until(node.location.end_line)
      # Do not traverse rhs not to document `A = Struct.new{def undocumentable_method; end}`
    end

    private

    def constant_arguments_names(call_node)
      return unless call_node.arguments
      names = call_node.arguments.arguments.map { |arg| constant_path_string(arg) }
      names.all? ? names : nil
    end

    def symbol_arguments(call_node)
      arguments_node = call_node.arguments
      return unless arguments_node && arguments_node.arguments.all? { |arg| arg.is_a?(Prism::SymbolNode)}
      arguments_node.arguments.map { |arg| arg.value.to_sym }
    end

    def visibility_method_arguments(call_node, singleton:)
      arguments_node = call_node.arguments
      return unless arguments_node
      symbols = symbol_arguments(call_node)
      if symbols
        # module_function :foo, :bar
        return symbols.map(&:to_s)
      else
        return unless arguments_node.arguments.size == 1
        arg = arguments_node.arguments.first
        return unless arg.is_a?(Prism::DefNode)

        if singleton
          # `private_class_method def foo; end` `private_class_method def not_self.foo; end` should be ignored
          return unless arg.receiver.is_a?(Prism::SelfNode)
        else
          # `module_function def something.foo` should be ignored
          return if arg.receiver
        end
        # `module_function def foo; end` or `private_class_method def self.foo; end`
        [arg.name.to_s]
      end
    end

    def constant_path_string(node)
      case node
      when Prism::ConstantReadNode
        node.name.to_s
      when Prism::ConstantPathNode
        parent_name = node.parent ? constant_path_string(node.parent) : ''
        "#{parent_name}::#{node.name}" if parent_name
      end
    end

    def _visit_call_require(call_node)
      return if @scanner.document_suppressed?
      return unless call_node.arguments&.arguments&.size == 1
      arg = call_node.arguments.arguments.first
      return unless arg.is_a?(Prism::StringNode)
      @scanner.add_require(arg.unescaped)
    end

    def _visit_call_module_function(call_node)
      return if @scanner.in_proc_block || @scanner.singleton
      names = visibility_method_arguments(call_node, singleton: false)&.map(&:to_s)
      @scanner.change_method_to_module_function(names) if names
    end

    def _visit_call_public_private_class_method(call_node, visibility)
      return if @scanner.in_proc_block || @scanner.singleton
      names = visibility_method_arguments(call_node, singleton: true)
      @scanner.change_method_visibility(names, visibility, singleton: true) if names
    end

    def _visit_call_public_private_protected(call_node, visibility)
      return if @scanner.in_proc_block
      arguments_node = call_node.arguments
      if arguments_node.nil? # `public` `private`
        @scanner.visibility = visibility
      else # `public :foo, :bar`, `private def foo; end`
        names = visibility_method_arguments(call_node, singleton: false)
        @scanner.change_method_visibility(names, visibility) if names
      end
    end

    def _visit_call_alias_method(call_node)
      return if @scanner.in_proc_block

      new_name, old_name, *rest = symbol_arguments(call_node)
      return unless old_name && new_name && rest.empty?
      @scanner.add_alias_method(old_name.to_s, new_name.to_s, call_node.location.start_line)
    end

    def _visit_call_include(call_node)
      return if @scanner.in_proc_block

      names = constant_arguments_names(call_node)
      line_no = call_node.location.start_line
      return unless names

      if @scanner.singleton
        @scanner.add_extends(names, line_no)
      else
        @scanner.add_includes(names, line_no)
      end
    end

    def _visit_call_extend(call_node)
      return if @scanner.in_proc_block

      names = constant_arguments_names(call_node)
      @scanner.add_extends(names, call_node.location.start_line) if names && !@scanner.singleton
    end

    def _visit_call_public_constant(call_node)
      return if @scanner.in_proc_block || @scanner.singleton
      names = symbol_arguments(call_node)
      @scanner.set_constant_visibility(names.map(&:to_s), :public) if names
    end

    def _visit_call_private_constant(call_node)
      return if @scanner.in_proc_block || @scanner.singleton
      names = symbol_arguments(call_node)
      @scanner.set_constant_visibility(names.map(&:to_s), :private) if names
    end

    def _visit_call_attr_reader_writer_accessor(call_node, rw)
      return if @scanner.in_proc_block
      names = symbol_arguments(call_node)
      @scanner.add_attributes(names.map(&:to_s), rw, call_node.location.start_line) if names
    end

    class MethodSignatureVisitor < Prism::Visitor # :nodoc:
      class << self
        def scan_signature(def_node)
          visitor = new
          def_node.body&.accept(visitor)
          params = "(#{def_node.parameters&.slice})"
          block_params = visitor.yields.first
          [params, block_params, visitor.calls_super]
        end
      end

      attr_reader :params, :yields, :calls_super

      def initialize
        @params = nil
        @calls_super = false
        @yields = []
      end

      def visit_def_node(node)
        # stop traverse inside nested def
      end

      def visit_yield_node(node)
        @yields << (node.arguments&.slice || '')
      end

      def visit_super_node(node)
        @calls_super = true
        super
      end

      def visit_forwarding_super_node(node)
        @calls_super = true
      end
    end
  end
end
