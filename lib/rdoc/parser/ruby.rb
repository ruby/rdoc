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
  attr_reader :container, :singleton, :in_unknown_definee_block

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

    @module_nesting = [[top_level, false]]
    @container = top_level
    @visibility = :public
    @singleton = false
    @in_unknown_definee_block = false
  end

  # A method can evaluate its block with any receiver (`instance_eval`,
  # `module_eval` etc.), so self and the default definee inside a block are
  # unknown. Definitions targeting them (`def`, `include`, `extend`, `attr_*`,
  # visibility changes and aliases) are suppressed while visiting the block.
  # Constant assignments stay documentable because the cref is lexical.
  # example: `M.module_eval { include N }` `configure { def f; end }`

  def with_unknown_definee_block
    in_unknown_definee_block = @in_unknown_definee_block
    @in_unknown_definee_block = true
    yield
    @in_unknown_definee_block = in_unknown_definee_block
  end

  # Dive into another container.
  #
  # `push_nesting: false` switches the default definee without changing the
  # cref (`@module_nesting`). Class-body-like blocks (`X = Struct.new do ... end`)
  # need this: `def` belongs to the new class while constant assignments and
  # `class`/`module` keywords belong to the outer lexical scope.

  def with_container(container, singleton: false, push_nesting: true)
    old_container = @container
    old_visibility = @visibility
    old_singleton = @singleton
    old_in_unknown_definee_block = @in_unknown_definee_block
    @visibility = :public
    @container = container
    @singleton = singleton
    @in_unknown_definee_block = false
    @module_nesting.push([container, singleton]) if push_nesting
    yield container
  ensure
    @container = old_container
    @visibility = old_visibility
    @singleton = old_singleton
    @in_unknown_definee_block = old_in_unknown_definee_block
    @module_nesting.pop if push_nesting
  end

  # Records the location of this +container+ in the file for this parser and
  # adds it to the list of classes and modules in the file.

  def record_location(container) # :nodoc:
    case container
    when RDoc::ClassModule then
      @top_level.add_to_classes_or_modules container
    end

    container.record_location @top_level
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
  end

  def should_document?(code_object) # :nodoc:
    return true unless @track_visibility
    return false if code_object.parent&.document_children == false
    code_object.document_self
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

  # Creates an RDoc::Method on +container+ from +comment+ if there is a
  # Signature section in the comment

  def parse_comment_tomdoc(container, comment, line_no, start_line)
    return unless signature = RDoc::TomDoc.signature(comment)

    name, = signature.split %r%[ \(]%, 2

    meth = RDoc::AnyMethod.new name
    record_location(meth)
    meth.line = start_line
    meth.call_seq = signature
    return unless meth.name

    meth.start_collecting_tokens(:ruby)
    node = @line_nodes[line_no]
    tokens = node ? syntax_highlighted_tokens(node) : []
    tokens.each { |token| meth.token_stream << token }

    container.add_method meth
    meth.comment = comment
    @stats.add_method meth
  end

  def has_modifier_nodoc?(line_no) # :nodoc:
    @modifier_comments[line_no]&.match?(/\A#\s*:nodoc:/)
  end

  def handle_modifier_directive(code_object, line_no) # :nodoc:
    if (comment_text = @modifier_comments[line_no])
      _text, directives = @preprocess.parse_comment(comment_text, line_no, :ruby)
      handle_code_object_directives(code_object, directives)
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

  # Handles meta method comments

  def handle_meta_method_comment(comment, directives, node)
    handle_code_object_directives(@container, directives)
    is_call_node = node.is_a?(Prism::CallNode)
    singleton_method = false
    visibility = @visibility
    attributes = rw = line_no = method_name = nil
    directives.each do |directive, (param, line)|
      case directive
      when 'attr', 'attr_reader', 'attr_writer', 'attr_accessor'
        attributes = [param] if param
        attributes ||= call_node_name_arguments(node) if is_call_node
        rw = directive == 'attr_writer' ? 'W' : directive == 'attr_accessor' ? 'RW' : 'R'
      when 'method'
        method_name = param if param
        line_no = line
      when 'singleton-method'
        method_name = param if param
        line_no = line
        singleton_method = true
        visibility = :public
      end
    end

    if attributes
      attributes.each do |attr|
        a = RDoc::Attr.new(attr, rw, comment, singleton: @singleton)
        a.store = @store
        a.line = line_no
        record_location(a)
        @container.add_attribute(a)
        a.visibility = visibility
      end
    elsif line_no || node
      method_name ||= call_node_name_arguments(node).first if is_call_node
      if node
        tokens = syntax_highlighted_tokens(node)
        line_no = node.location.start_line
      else
        tokens = []
      end
      internal_add_method(
        method_name,
        @container,
        comment: comment,
        directives: directives,
        dont_rename_initialize: false,
        line_no: line_no,
        visibility: visibility,
        singleton: @singleton || singleton_method,
        params: nil,
        calls_super: false,
        block_params: nil,
        tokens: tokens,
      )
    end
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

  def handle_standalone_consecutive_comment_directive(comment, directives, start_with_sharp_sharp, line_no, start_line) # :nodoc:
    if start_with_sharp_sharp && start_line != @first_non_meta_comment_start_line
      node = @line_nodes[line_no]
      handle_meta_method_comment(comment, directives, node)
    elsif normal_comment_treat_as_ghost_method_for_now?(directives, line_no) && start_line != @first_non_meta_comment_start_line
      handle_meta_method_comment(comment, directives, nil)
    else
      handle_code_object_directives(@container, directives)
    end
  end

  # Processes consecutive comments that were not linked to any documentable code until the given line number

  def process_comments_until(line_no_until)
    while !@unprocessed_comments.empty? && @unprocessed_comments.first[0] <= line_no_until
      line_no, start_line, text = @unprocessed_comments.shift
      if @markup == 'tomdoc'
        comment = RDoc::Comment.new(text, @top_level, :ruby)
        comment.format = 'tomdoc'
        parse_comment_tomdoc(@container, comment, line_no, start_line)
        @preprocess.run_post_processes(comment, @container)
      elsif (comment_text, directives = parse_comment_text_to_directives(text, start_line))
        handle_standalone_consecutive_comment_directive(comment_text, directives, text.start_with?(/#\#$/), line_no, start_line)
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

  # Returns consecutive comment linked to the given line number

  def consecutive_comment(line_no)
    return unless @unprocessed_comments.first&.first == line_no
    _line_no, start_line, text = @unprocessed_comments.shift
    parse_comment_text_to_directives(text, start_line)
  end

  # Parses comment text and returns +[RDoc::Comment, directives, type_signature_lines]+,
  # or +nil+ if the comment is a section header (which has no associated code
  # object).

  def parse_comment_text_to_directives(comment_text, start_line) # :nodoc:
    type_signature_lines = extract_type_signature!(comment_text, start_line)
    comment_text, directives = @preprocess.parse_comment(comment_text, start_line, :ruby)
    comment = RDoc::Comment.new(comment_text, @top_level, :ruby)
    comment.normalized = true
    comment.line = start_line
    markup, = directives['markup']
    comment.format = markup&.downcase || @markup
    if (section, directive_line = directives['section'])
      # If comment has :section:, it is not a documentable comment for a code object
      comment.text = extract_section_comment(comment_text, directive_line - start_line)
      @container.set_current_section(section, comment)
      return
    end
    @preprocess.run_post_processes(comment, @container)
    [comment, directives, type_signature_lines]
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
    new_methods = []
    @container.methods_matching(names, singleton) do |m|
      if m.parent != @container
        m = m.dup
        record_location(m)
        new_methods << m
      else
        m.visibility = visibility
      end
    end
    new_methods.each do |method|
      case method
      when RDoc::AnyMethod then
        @container.add_method(method)
      when RDoc::Attr then
        @container.add_attribute(method)
      end
      method.visibility = visibility
    end
  end

  # Handles `module_function :foo, :bar`

  def change_method_to_module_function(names)
    @container.set_visibility_for(names, :private, false)
    new_methods = []
    @container.methods_matching(names) do |m|
      s_m = m.dup
      record_location(s_m)
      s_m.singleton = true
      new_methods << s_m
    end
    new_methods.each do |method|
      case method
      when RDoc::AnyMethod then
        @container.add_method(method)
      when RDoc::Attr then
        @container.add_attribute(method)
      end
      method.visibility = :public
    end
  end

  def handle_code_object_directives(code_object, directives) # :nodoc:
    directives.each do |directive, (param)|
      @preprocess.handle_directive('', directive, param, code_object)
    end
  end

  # Handles `alias foo bar` and `alias_method :foo, :bar`

  def add_alias_method(old_name, new_name, line_no)
    comment, directives = consecutive_comment(line_no)
    handle_code_object_directives(@container, directives) if directives
    visibility = @container.find_method(old_name, @singleton)&.visibility || :public
    a = RDoc::Alias.new(old_name, new_name, comment, singleton: @singleton)
    handle_modifier_directive(a, line_no)
    a.store = @store
    a.line = line_no
    record_location(a)
    if should_document?(a)
      @container.add_alias(a)
      @container.find_method(new_name, @singleton)&.visibility = visibility
    end
  end

  # Handles `attr :a, :b`, `attr_reader :a, :b`, `attr_writer :a, :b` and `attr_accessor :a, :b`

  def add_attributes(names, rw, line_no)
    comment, directives, type_signature_lines = consecutive_comment(line_no)
    handle_code_object_directives(@container, directives) if directives
    return unless @container.document_children

    names.each do |symbol|
      a = RDoc::Attr.new(symbol.to_s, rw, comment, singleton: @singleton)
      a.store = @store
      a.line = line_no
      a.type_signature_lines = type_signature_lines
      record_location(a)
      handle_modifier_directive(a, line_no)
      @container.add_attribute(a) if should_document?(a)
      a.visibility = visibility # should set after adding to container
    end
  end

  # Adds includes/extends. Module name is resolved to full before adding.

  def add_includes_extends(names, rdoc_class, line_no) # :nodoc:
    comment, directives = consecutive_comment(line_no)
    handle_code_object_directives(@container, directives) if directives
    names.each do |name|
      resolved_name = resolve_constant_path(name)
      ie = @container.add(rdoc_class, resolved_name || name, '')
      ie.store = @store
      ie.line = line_no
      ie.comment = comment
      record_location(ie)
    end
  end

  # Handle `include Foo, Bar`

  def add_includes(names, line_no) # :nodoc:
    add_includes_extends(names, RDoc::Include, line_no)
  end

  # Handle `extend Foo, Bar`

  def add_extends(names, line_no) # :nodoc:
    add_includes_extends(names, RDoc::Extend, line_no)
  end

  # Adds a method defined by `def` syntax

  def add_method(method_name, receiver_name:, receiver_fallback_type:, visibility:, singleton:, params:, calls_super:, block_params:, tokens:, start_line:, args_end_line:, end_line:)
    receiver = receiver_name ? find_or_create_lexical_module_path(receiver_name, receiver_fallback_type) : @container
    comment, directives, type_signature_lines = consecutive_comment(start_line)
    handle_code_object_directives(@container, directives) if directives

    internal_add_method(
      method_name,
      receiver,
      comment: comment,
      directives: directives,
      modifier_comment_lines: [start_line, args_end_line, end_line].uniq,
      line_no: start_line,
      visibility: visibility,
      singleton: singleton,
      params: params,
      calls_super: calls_super,
      block_params: block_params,
      tokens: tokens,
      type_signature_lines: type_signature_lines
    )
  end

  private def internal_add_method(method_name, container, comment:, dont_rename_initialize: false, directives:, modifier_comment_lines: nil, line_no:, visibility:, singleton:, params:, calls_super:, block_params:, tokens:, type_signature_lines: nil) # :nodoc:
    meth = RDoc::AnyMethod.new(method_name, singleton: singleton)
    meth.comment = comment
    handle_code_object_directives(meth, directives) if directives
    modifier_comment_lines&.each do |line|
      handle_modifier_directive(meth, line)
    end
    return unless should_document?(meth)

    if directives && (call_seq, = directives['call-seq'])
      meth.call_seq = call_seq.lines.map(&:chomp).reject(&:empty?).join("\n") if call_seq
    end
    meth.name ||= meth.call_seq[/\A[^()\s]+/] if meth.call_seq
    meth.name ||= 'unknown'
    meth.store = @store
    meth.line = line_no
    container.add_method(meth) # should add after setting singleton and before setting visibility
    meth.visibility = visibility
    meth.params ||= params || '()'
    meth.calls_super = calls_super
    meth.block_params ||= block_params if block_params
    meth.type_signature_lines = type_signature_lines
    record_location(meth)
    meth.start_collecting_tokens(:ruby)
    tokens.each do |token|
      meth.token_stream << token
    end

    # Rename after add_method to register duplicated 'new' and 'initialize'
    # defined in c and ruby.
    if !dont_rename_initialize && method_name == 'initialize' && !singleton
      if meth.dont_rename_initialize
        meth.visibility = :protected
      else
        meth.name = 'new'
        meth.singleton = true
        meth.visibility = :public
      end
    end
  end

  # Find or create module or class from a given module name using Ruby lexical
  # nesting. If module or class does not exist, creates a module or a class
  # according to `create_mode` argument.

  def find_or_create_lexical_module_path(module_name, create_mode)
    root_name, *path, name = module_name.split('::')
    add_module = ->(mod, name, mode) {
      case mode
      when :class
        mod.add_class(RDoc::NormalClass, name, 'Object').tap { |m| m.store = @store }
      when :module
        mod.add_module(RDoc::NormalModule, name).tap { |m| m.store = @store }
      end
    }
    if root_name.empty?
      mod = @top_level
    else
      @module_nesting.reverse_each do |nesting, singleton|
        next if singleton
        mod = nesting.get_module_named(root_name)
        break if mod
        # If a constant is found and it is not a module or class, RDoc can't document about it.
        # Return an anonymous module to avoid wrong document creation.
        return RDoc::NormalModule.new(nil) if nesting.find_constant_named(root_name)
      end
      last_nesting, = @module_nesting.reverse_each.find { |_, singleton| !singleton }
      return mod || add_module.call(last_nesting, root_name, create_mode) unless name
      mod ||= add_module.call(last_nesting, root_name, :module)
    end
    path.each do |name|
      mod = mod.get_module_named(name) || add_module.call(mod, name, :module)
    end
    mod.get_module_named(name) || add_module.call(mod, name, create_mode)
  end

  # Resolves constant path to a full path by searching module nesting

  def resolve_constant_path(constant_path)
    owner_name, path = constant_path.split('::', 2)
    return constant_path if owner_name.empty? # ::Foo, ::Foo::Bar
    mod = nil
    @module_nesting.reverse_each do |nesting, singleton|
      next if singleton
      mod = nesting.get_module_named(owner_name)
      break if mod
    end
    mod ||= @top_level.get_module_named(owner_name)
    [mod.full_name, path].compact.join('::') if mod
  end

  # Returns a pair of owner module and constant name from a given constant path
  # using Ruby lexical nesting. Creates owner module if it does not exist.

  def find_or_create_lexical_constant_owner_name(constant_path)
    const_path, colon, name = constant_path.rpartition('::')
    if colon.empty? # class Foo
      # Owner is the cref (innermost module nesting), not `@container`.
      # They differ inside a class-body-like block: `A = Struct.new { C = 1 }`
      # defines ::C, not A::C.
      # Within `class <<C`, owner is C.singleton_class
      # but RDoc don't track constants of a singleton class of module
      container, singleton = @module_nesting.last
      [(singleton ? nil : container), name]
    elsif const_path.empty? # class ::Foo
      [@top_level, name]
    else # `class Foo::Bar` or `class ::Foo::Bar`
      [find_or_create_lexical_module_path(const_path, :module), name]
    end
  end

  # Adds a constant

  def add_constant(constant_name, rhs_name, start_line, end_line, alias_path: nil)
    comment, directives = consecutive_comment(start_line)
    handle_code_object_directives(@container, directives) if directives
    owner, name = find_or_create_lexical_constant_owner_name(constant_name)
    return unless owner

    constant = RDoc::Constant.new(name, rhs_name, comment)
    constant.store = @store
    constant.line = start_line
    constant.is_alias_for_path = alias_path
    record_location(constant)
    handle_modifier_directive(constant, start_line)
    handle_modifier_directive(constant, end_line)
    owner.add_constant(constant)
    return unless alias_path
    mod =
      if alias_path.start_with?('::')
        @store.find_class_or_module(alias_path)
      else
        full_name = resolve_constant_path(alias_path)
        @store.find_class_or_module(full_name)
      end
    if mod && constant.document_self
      a = owner.add_module_alias(mod, alias_path, constant, @top_level)
      a.store = @store
      a.line = start_line
      record_location(a)
    end
  end

  # Adds module or class

  def add_module_or_class(module_name, start_line, end_line, is_class: false, superclass_name: nil, superclass_expr: nil)
    comment, directives = consecutive_comment(start_line)
    handle_code_object_directives(@container, directives) if directives
    return unless @container.document_children

    owner, name = find_or_create_lexical_constant_owner_name(module_name)
    return unless owner

    if is_class
      # RDoc::NormalClass resolves superclass name despite of the lack of module nesting information.
      # We need to fix it when RDoc::NormalClass resolved to a wrong constant name
      if superclass_name
        superclass_full_path = resolve_constant_path(superclass_name)
        superclass = @store.find_class_or_module(superclass_full_path) if superclass_full_path
        superclass_full_path ||= superclass_name
        superclass_full_path = superclass_full_path.sub(/^::/, '')
      end
      # add_class should be done after resolving superclass
      mod = owner.classes_hash[name] || owner.add_class(RDoc::NormalClass, name, superclass_name || superclass_expr || '::Object')
      if superclass_name
        if superclass
          mod.superclass = superclass
        elsif (mod.superclass.is_a?(String) || mod.superclass.name == 'Object') && mod.superclass != superclass_full_path
          mod.superclass = superclass_full_path
        end
      end
    else
      mod = owner.modules_hash[name] || owner.add_module(RDoc::NormalModule, name)
    end

    mod.store = @store
    mod.line = start_line
    record_location(mod)
    handle_modifier_directive(mod, start_line)
    handle_modifier_directive(mod, end_line)
    mod.add_comment(comment, @top_level) if comment
    mod
  end

  private

  # Extracts RBS type signature lines (#: ...) from raw comment text.
  # Mutates the input text to remove the extracted lines.
  # Returns an array of extracted type signature lines, or nil if none are
  # found. The array may contain multiple lines for overloaded signatures.

  def extract_type_signature!(text, start_line)
    return nil unless text.include?('#:')

    lines = text.lines
    sig_lines, doc_lines = lines.partition { |l| l.match?(RBS_SIG_LINE) }
    return nil if sig_lines.empty?

    first_sig_line = start_line + lines.index(sig_lines.first)
    text.replace(doc_lines.join)
    type_signature_lines = sig_lines.map { |l| l.sub(RBS_SIG_LINE, '').strip }.reject(&:empty?)
    return nil if type_signature_lines.empty?

    warn_invalid_type_signature(type_signature_lines, first_sig_line)
    type_signature_lines
  end

  def warn_invalid_type_signature(type_signature_lines, line_no)
    type_signature_lines.each_with_index do |line, i|
      next if RDoc::RbsHelper.valid_method_type?(line)
      next if RDoc::RbsHelper.valid_type?(line)
      @options.warn "#{@top_level.relative_name}:#{line_no + i}: invalid RBS type signature: #{line.inspect}"
    end
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
      @scanner.with_unknown_definee_block do
        super
      end
    end

    def visit_alias_method_node(node)
      return if @scanner.in_unknown_definee_block
      @scanner.process_comments_until(node.location.start_line - 1)
      return unless node.old_name.is_a?(Prism::SymbolNode) && node.new_name.is_a?(Prism::SymbolNode)
      @scanner.add_alias_method(node.old_name.value.to_s, node.new_name.value.to_s, node.location.start_line)
    end

    def visit_module_node(node)
      node.constant_path.accept(self)
      @scanner.process_comments_until(node.location.start_line - 1)
      module_name = constant_path_string(node.constant_path)
      mod = @scanner.add_module_or_class(module_name, node.location.start_line, node.location.end_line) if module_name
      if mod
        @scanner.with_container(mod) do
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
      klass = @scanner.add_module_or_class(class_name, node.location.start_line, node.location.end_line, is_class: true, superclass_name: superclass_name, superclass_expr: superclass_expr) if class_name
      if klass
        @scanner.with_container(klass) do
          # `class A < Struct.new(:foo)` inherits member accessors
          superclass_info = anonymous_module_or_class_info(node.superclass)
          if (members = superclass_info&.dig(:members)) && !members.empty?
            @scanner.add_attributes(members, superclass_info[:rw], node.superclass.location.start_line)
          end
          node.body&.accept(self)
          @scanner.process_comments_until(node.location.end_line)
        end
      else
        @scanner.skip_comments_until(node.location.end_line)
      end
    end

    def visit_singleton_class_node(node)
      @scanner.process_comments_until(node.location.start_line - 1)

      if @scanner.has_modifier_nodoc?(node.location.start_line)
        # Skip visiting inside the singleton class. Also skips creation of node.expression as a module
        @scanner.skip_comments_until(node.location.end_line)
        return
      end

      expression = node.expression
      expression = expression.body.body.first if expression.is_a?(Prism::ParenthesesNode) && expression.body&.body&.size == 1

      expression.accept(self)
      case expression
      when Prism::ConstantWriteNode
        # Accept `class << (NameErrorCheckers = Object.new)` as a module which is not actually a module.
        # When visiting the expression defined a class or module (`class << (X = Struct.new)`), reuse it.
        name = expression.name.to_s
        mod = @scanner.container.classes_hash[name] || @scanner.container.modules_hash[name] ||
              @scanner.container.add_module(RDoc::NormalModule, name)
      when Prism::ConstantPathNode, Prism::ConstantReadNode
        expression_name = constant_path_string(expression)
        # If a constant_path does not exist, RDoc creates a module
        mod = @scanner.find_or_create_lexical_module_path(expression_name, :module) if expression_name
      when Prism::SelfNode
        mod = @scanner.container if @scanner.container != @top_level
      end
      if mod
        @scanner.with_container(mod, singleton: true) do
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

      return if @scanner.in_unknown_definee_block

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

      _visit_constant_write(path, node.value, node.location)
      @scanner.skip_comments_until(node.location.end_line)
    end

    def visit_constant_write_node(node)
      @scanner.process_comments_until(node.location.start_line - 1)
      _visit_constant_write(node.name.to_s, node.value, node.location)
      @scanner.skip_comments_until(node.location.end_line)
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

    def _visit_constant_write(path, value_node, location)
      if (info = anonymous_module_or_class_info(value_node))
        mod = @scanner.add_module_or_class(
          path,
          location.start_line,
          location.end_line,
          is_class: info[:is_class],
          superclass_name: info[:superclass_name],
          superclass_expr: info[:superclass_expr]
        )
        return unless mod

        @scanner.with_container(mod, push_nesting: false) do
          members = info[:members]
          @scanner.add_attributes(members, info[:rw], location.start_line) if members && !members.empty?
          info[:block]&.body&.accept(self)
          @scanner.process_comments_until(location.end_line)
        end
      else
        alias_path = constant_path_string(value_node)
        @scanner.add_constant(
          path,
          alias_path || value_node.slice,
          location.start_line,
          location.end_line,
          alias_path: alias_path
        )
        # Do not traverse rhs not to document `A = some_dsl { def undocumentable_method; end }`
      end
    end

    # Returns add_module_or_class arguments if the expression creates an
    # anonymous class or module (`Struct.new`, `Data.define`, `Class.new`,
    # `Module.new`) which the constant assignment will name, otherwise nil.

    def anonymous_module_or_class_info(expression)
      return unless expression.is_a?(Prism::CallNode)

      receiver_name =
        case (receiver = expression.receiver)
        when Prism::ConstantReadNode
          receiver.name
        when Prism::ConstantPathNode
          receiver.name if receiver.parent.nil? # `::Struct.new`
        end

      block = expression.block
      block = nil unless block.is_a?(Prism::BlockNode)
      arguments = expression.arguments&.arguments || []

      case [receiver_name, expression.name]
      when [:Struct, :new], [:Data, :define]
        # In `Struct.new('Name', :member)`, the string argument is a class name under Struct, not a member
        members = arguments.grep(Prism::SymbolNode).map(&:value)
        rw = receiver_name == :Struct ? 'RW' : 'R'
        { is_class: true, superclass_name: receiver_name.to_s, members: members, rw: rw, block: block }
      when [:Class, :new]
        superclass = arguments.first
        superclass_name = constant_path_string(superclass) if superclass
        superclass_expr = superclass.slice if superclass && !superclass_name
        { is_class: true, superclass_name: superclass_name, superclass_expr: superclass_expr, block: block }
      when [:Module, :new]
        { is_class: false, block: block }
      end
    end

    def _visit_call_require(call_node)
      return unless call_node.arguments&.arguments&.size == 1
      arg = call_node.arguments.arguments.first
      return unless arg.is_a?(Prism::StringNode)
      @scanner.container.add_require(RDoc::Require.new(arg.unescaped, nil))
    end

    def _visit_call_module_function(call_node)
      return if @scanner.in_unknown_definee_block || @scanner.singleton
      names = visibility_method_arguments(call_node, singleton: false)&.map(&:to_s)
      @scanner.change_method_to_module_function(names) if names
    end

    def _visit_call_public_private_class_method(call_node, visibility)
      return if @scanner.in_unknown_definee_block || @scanner.singleton
      names = visibility_method_arguments(call_node, singleton: true)
      @scanner.change_method_visibility(names, visibility, singleton: true) if names
    end

    def _visit_call_public_private_protected(call_node, visibility)
      return if @scanner.in_unknown_definee_block
      arguments_node = call_node.arguments
      if arguments_node.nil? # `public` `private`
        @scanner.visibility = visibility
      else # `public :foo, :bar`, `private def foo; end`
        names = visibility_method_arguments(call_node, singleton: false)
        @scanner.change_method_visibility(names, visibility) if names
      end
    end

    def _visit_call_alias_method(call_node)
      return if @scanner.in_unknown_definee_block

      new_name, old_name, *rest = symbol_arguments(call_node)
      return unless old_name && new_name && rest.empty?
      @scanner.add_alias_method(old_name.to_s, new_name.to_s, call_node.location.start_line)
    end

    def _visit_call_include(call_node)
      return if @scanner.in_unknown_definee_block

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
      return if @scanner.in_unknown_definee_block

      names = constant_arguments_names(call_node)
      @scanner.add_extends(names, call_node.location.start_line) if names && !@scanner.singleton
    end

    def _visit_call_public_constant(call_node)
      return if @scanner.in_unknown_definee_block || @scanner.singleton
      names = symbol_arguments(call_node)
      @scanner.container.set_constant_visibility_for(names.map(&:to_s), :public) if names
    end

    def _visit_call_private_constant(call_node)
      return if @scanner.in_unknown_definee_block || @scanner.singleton
      names = symbol_arguments(call_node)
      @scanner.container.set_constant_visibility_for(names.map(&:to_s), :private) if names
    end

    def _visit_call_attr_reader_writer_accessor(call_node, rw)
      return if @scanner.in_unknown_definee_block
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
