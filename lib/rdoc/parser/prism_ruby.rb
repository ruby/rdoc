# frozen_string_literal: true

require 'prism'
require_relative 'ripper_state_lex'

# Unlike lib/rdoc/parser/ruby.rb, this file is not based on rtags and does not contain code from
#   rtags.rb -
#   ruby-lex.rb - ruby lexcal analyzer
#   ruby-token.rb - ruby tokens

# Parse and collect document from Ruby source code.
# RDoc::Parser::PrismRuby is compatible with RDoc::Parser::Ruby and aims to replace it.

class RDoc::Parser::PrismRuby < RDoc::Parser
  parse_files_matching(/\.rbw?$/) if ENV['RDOC_USE_PRISM_PARSER']

  # Nesting information
  # container: ClassModule or TopLevel
  # singleton: true(container is a singleton class) or false
  # nodoc: true(in shallow nodoc) or false
  # state: :startdoc, :stopdoc, :enddoc
  # visibility: :public, :private, :protected
  # block_level: block nesting level within current container. > 0 means in block
  Nesting = Struct.new(:container, :singleton, :block_level, :visibility, :nodoc, :doc_state)

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

    # Names of constant/class/module marked as nodoc in this file local scope
    @file_local_nodoc_names = Set.new
    # Represent module_nesting, visibility, block nesting level and startdoc/stopdoc/enddoc/nodoc for each module_nesting
    @nestings = [Nesting.new(top_level, false, 0, :public, false, :startdoc)]
  end

  # Mark the given const/class/module full name as nodoc in current file local scope.
  def locally_mark_const_name_as_nodoc(const_name)
    @file_local_nodoc_names << const_name
  end

  # Returns true if the given container is marked as nodoc in current file local scope.
  def locally_marked_as_nodoc?(container)
    @file_local_nodoc_names.include?(container.full_name)
  end

  def current_nesting # :nodoc:
    @nestings.last
  end

  # Current container code object (ClassModule or TopLevel) being processed
  def current_container
    current_nesting.container
  end

  # Returns true if current container is a singleton class
  # False when in a normal class/module <tt>class A; end</tt>, true when in a singleton class <tt>class << A; end</tt>
  def singleton?
    current_nesting.singleton
  end

  # Returns true if currently inside a proc or block
  # When true, `self` may not be the current container
  def in_proc_block?
    current_nesting.block_level > 0
  end

  # Current method visibility (:public, :private, :protected)
  def current_visibility
    current_nesting.visibility
  end

  def current_visibility=(v)
    current_nesting.visibility = v
  end

  # Mark this container as documentable.
  # When creating a container within nodoc scope, or creating intermediate modules when reached `class A::Intermediate::D`,
  # the created container is marked as ignored. Documentable or not will be determined later.
  # It may be undocumented if the container doesn't have any comment or documentable children,
  # and will be documentable when receiving comment or documentable children later.
  def mark_container_documentable(container)
    return if container.received_nodoc || !container.ignored?
    record_location(container)
    container.start_doc
    mark_container_documentable(container.parent) if container.parent.is_a?(RDoc::ClassModule)
  end

  def container_accept_document?(container) # :nodoc:
    !current_nesting.nodoc && current_nesting.doc_state == :startdoc && !container.received_nodoc && !locally_marked_as_nodoc?(container)
  end

  # Suppress `extend` and `include` within block
  # because they might be a metaprogramming block
  # example: `Module.new { include M }` `M.module_eval { include N }`

  def with_in_proc_block
    current_nesting.block_level += 1
    yield
    current_nesting.block_level -= 1
  end

  # Dive into another container

  def with_container(container, singleton: false)
    nesting = current_nesting
    nodoc = locally_marked_as_nodoc?(container) || container.received_nodoc
    @nestings << Nesting.new(
      container,
      singleton,
      0,
      :public,
      nodoc, # Set to true if container is marked as nodoc file-locally or globally. Not inherited from parene nesting.
      nesting.doc_state # state(stardoc/stopdoc/enddoc) is inherited
    )
    yield container
  ensure
    @nestings.pop
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
    @tokens = RDoc::Parser::RipperStateLex.parse(@content)
    @lines = @content.lines
    result = Prism.parse(@content)
    @program_node = result.value
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

  # Apply document control directive such as :startdoc:, :stopdoc: and :enddoc: to the current container
  def apply_document_control_directive(directives)
    directives.each do |key, (value, _loc)|
      case key
      when 'startdoc', 'stopdoc'
        state = key.to_sym
        if current_nesting.doc_state == state || current_nesting.doc_state == :enddoc
          warn "Already in :#{state}: state, ignoring"
        else
          current_nesting.doc_state = state
        end
      when 'enddoc'
        if current_nesting.doc_state == :enddoc
          warn "Already in :enddoc: state, ignoring"
        else
          current_nesting.doc_state = :enddoc
        end
      when 'nodoc'
        if value == 'all'
          current_nesting.doc_state = :enddoc
          current_nesting.nodoc = true
          # Globally mark container as nodoc
          current_container.document_self = nil
        elsif current_nesting.nodoc
          warn "Already in :nodoc: state, ignoring"
        elsif current_nesting.doc_state == :enddoc
          warn "Already in :enddoc: state, ignoring"
        else
          # Mark this shallow scope as nodoc: methods and constants are not documented
          current_nesting.nodoc = true
          # And mark this scope as enddoc: nested containers are not documented
          current_nesting.doc_state = :enddoc
          # Mark container as nodoc in this file. When this container is reopened later,
          # `nodoc!` will be applied again but `enddoc!` will not be applied.
          locally_mark_const_name_as_nodoc(current_container.full_name) unless current_container.is_a?(RDoc::TopLevel)
        end
      end
    end
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

    meth = RDoc::GhostMethod.new comment.text, name
    record_location(meth)
    meth.line = start_line
    meth.call_seq = signature
    return unless meth.name

    meth.start_collecting_tokens(:ruby)
    node = @line_nodes[line_no]
    tokens = node ? visible_tokens_from_location(node.location) : [file_line_comment_token(start_line)]
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
      if (value, = directives['nodoc'])
        if value == 'all'
          nodoc_state = :nodoc_all
        else
          nodoc_state = :nodoc
        end
      end
      handle_code_object_directives(code_object, directives.except('nodoc'))
      nodoc_state
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
    apply_document_control_directive(directives)
    handle_code_object_directives(current_container, directives)
    is_call_node = node.is_a?(Prism::CallNode)
    singleton_method = false
    visibility = current_visibility
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

    return unless container_accept_document?(current_container)

    if attributes
      attributes.each do |attr|
        a = RDoc::Attr.new(current_container, attr, rw, comment, singleton: singleton?)
        a.store = @store
        a.line = line_no
        record_location(a)
        current_container.add_attribute(a)
        mark_container_documentable(current_container)
        a.visibility = visibility
      end
    elsif line_no || node
      method_name ||= call_node_name_arguments(node).first if is_call_node
      if node
        tokens = visible_tokens_from_location(node.location)
        line_no = node.location.start_line
      else
        tokens = [file_line_comment_token(line_no)]
      end
      internal_add_method(
        method_name,
        current_container,
        comment: comment,
        directives: directives,
        dont_rename_initialize: false,
        line_no: line_no,
        visibility: visibility,
        singleton: singleton? || singleton_method,
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
      apply_document_control_directive(directives)
      handle_code_object_directives(current_container, directives)
    end
  end

  # Processes consecutive comments that were not linked to any documentable code until the given line number

  def process_comments_until(line_no_until)
    while !@unprocessed_comments.empty? && @unprocessed_comments.first[0] <= line_no_until
      line_no, start_line, text = @unprocessed_comments.shift
      if @markup == 'tomdoc'
        comment = RDoc::Comment.new(text, @top_level, :ruby)
        comment.format = 'tomdoc'
        parse_comment_tomdoc(current_container, comment, line_no, start_line)
        @preprocess.run_post_processes(comment, current_container)
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

  # Parses comment text and retuns a pair of RDoc::Comment and directives

  def parse_comment_text_to_directives(comment_text, start_line) # :nodoc:
    comment_text, directives = @preprocess.parse_comment(comment_text, start_line, :ruby)
    comment = RDoc::Comment.new(comment_text, @top_level, :ruby)
    comment.normalized = true
    comment.line = start_line
    markup, = directives['markup']
    comment.format = markup&.downcase || @markup
    if (section, = directives['section'])
      # If comment has :section:, it is not a documentable comment for a code object
      current_container.set_current_section(section, comment.dup)
      return
    end
    @preprocess.run_post_processes(comment, current_container)
    [comment, directives]
  end

  def slice_tokens(start_pos, end_pos) # :nodoc:
    start_index = @tokens.bsearch_index { |t| ([t.line_no, t.char_no] <=> start_pos) >= 0 }
    end_index = @tokens.bsearch_index { |t| ([t.line_no, t.char_no] <=> end_pos) >= 0 }
    tokens = @tokens[start_index...end_index]
    tokens.pop if tokens.last&.kind == :on_nl
    tokens
  end

  def file_line_comment_token(line_no) # :nodoc:
    position_comment = RDoc::Parser::RipperStateLex::Token.new(line_no - 1, 0, :on_comment)
    position_comment[:text] = "# File #{@top_level.relative_name}, line #{line_no}"
    position_comment
  end

  # Returns tokens from the given location

  def visible_tokens_from_location(location)
    position_comment = file_line_comment_token(location.start_line)
    newline_token = RDoc::Parser::RipperStateLex::Token.new(0, 0, :on_nl, "\n")
    indent_token = RDoc::Parser::RipperStateLex::Token.new(location.start_line, 0, :on_sp, ' ' * location.start_character_column)
    tokens = slice_tokens(
      [location.start_line, location.start_character_column],
      [location.end_line, location.end_character_column]
    )
    [position_comment, newline_token, indent_token, *tokens]
  end

  # Handles `public :foo, :bar` `private :foo, :bar` and `protected :foo, :bar`

  def change_method_visibility(names, visibility, singleton: singleton?)
    new_methods = []
    current_container.methods_matching(names, singleton) do |m|
      if m.parent != current_container
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
        current_container.add_method(method)
      when RDoc::Attr then
        current_container.add_attribute(method)
      end
      method.visibility = visibility
    end
  end

  # Handles `module_function :foo, :bar`

  def change_method_to_module_function(names)
    current_container.set_visibility_for(names, :private, false)
    new_methods = []
    current_container.methods_matching(names) do |m|
      s_m = m.dup
      record_location(s_m)
      s_m.singleton = true
      new_methods << s_m
    end
    new_methods.each do |method|
      case method
      when RDoc::AnyMethod then
        current_container.add_method(method)
      when RDoc::Attr then
        current_container.add_attribute(method)
      end
      method.visibility = :public
    end
  end

  def handle_code_object_directives(code_object, directives) # :nodoc:
    directives.each do |directive, (param)|
      next if directive in 'nodoc' | 'startdoc' | 'stopdoc' | 'enddoc'
      @preprocess.handle_directive('', directive, param, code_object)
    end
  end

  # Handles `alias foo bar` and `alias_method :foo, :bar`

  def add_alias_method(old_name, new_name, line_no)
    comment, directives = consecutive_comment(line_no)
    apply_document_control_directive(directives) if directives
    handle_code_object_directives(current_container, directives) if directives
    visibility = current_container.find_method(old_name, singleton?)&.visibility || :public
    a = RDoc::Alias.new(nil, old_name, new_name, comment, singleton: singleton?)
    modifier_nodoc = handle_modifier_directive(a, line_no)

    return unless container_accept_document?(current_container) && !(@track_visibility && modifier_nodoc)

    a.store = @store
    a.line = line_no
    mark_container_documentable(current_container)
    record_location(a)
    current_container.add_alias(a)
    current_container.find_method(new_name, singleton?)&.visibility = visibility
  end

  # Handles `attr :a, :b`, `attr_reader :a, :b`, `attr_writer :a, :b` and `attr_accessor :a, :b`

  def add_attributes(names, rw, line_no)
    comment, directives = consecutive_comment(line_no)
    apply_document_control_directive(directives) if directives
    handle_code_object_directives(current_container, directives) if directives
    return unless container_accept_document?(current_container)

    names.each do |symbol|
      a = RDoc::Attr.new(nil, symbol.to_s, rw, comment, singleton: singleton?)
      a.store = @store
      a.line = line_no
      modifier_nodoc = handle_modifier_directive(a, line_no)
      next if @track_visibility && modifier_nodoc
      record_location(a)
      current_container.add_attribute(a)
      mark_container_documentable(current_container)
      a.visibility = current_visibility # should set after adding to container
    end
  end

  # Adds includes/extends. Module name is resolved to full before adding.

  def add_includes_extends(names, rdoc_class, line_no) # :nodoc:
    comment, directives = consecutive_comment(line_no)
    apply_document_control_directive(directives) if directives
    handle_code_object_directives(current_container, directives) if directives

    return unless container_accept_document?(current_container)

    mark_container_documentable(current_container)

    names.each do |name|
      resolved_name = resolve_constant_path(name)
      ie = current_container.add(rdoc_class, resolved_name || name, '')
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
    receiver = receiver_name ? find_or_create_module_path(receiver_name, receiver_fallback_type) : current_container
    comment, directives = consecutive_comment(start_line)
    apply_document_control_directive(directives) if directives
    handle_code_object_directives(current_container, directives) if directives

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
      tokens: tokens
    )
  end

  private def internal_add_method(method_name, container, comment:, dont_rename_initialize: false, directives:, modifier_comment_lines: nil, line_no:, visibility:, singleton:, params:, calls_super:, block_params:, tokens:) # :nodoc:
    meth = RDoc::AnyMethod.new(nil, method_name, singleton: singleton)
    meth.comment = comment
    handle_code_object_directives(meth, directives) if directives
    modifier_nodoc = nil
    modifier_comment_lines&.each do |line|
      modifier_nodoc ||= handle_modifier_directive(meth, line)
    end

    return unless container_accept_document?(container)
    if modifier_nodoc
      return if @track_visibility
      meth.document_self = nil
    end

    mark_container_documentable(container)

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
    record_location(meth)
    meth.start_collecting_tokens(:ruby)
    tokens.each do |token|
      meth.token_stream << token
    end

    # Rename after add_method to register duplicated 'new' and 'initialize'
    # defined in c and ruby just like the old parser did.
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

  # Find or create module or class from a given module name.
  # If module or class does not exist, creates a module or a class according to `create_mode` argument.

  def find_or_create_module_path(module_name, create_mode)
    root_name, *path, name = module_name.split('::')

    # Creates intermediate modules/classes if they do not exist.
    # The created module may not be documented if it does not have comment nor documentable children.
    add_module = ->(mod, name, mode) {
      created =
        case mode
        when :class
          mod.add_class(RDoc::NormalClass, name, 'Object').tap { |m| m.store = @store }
        when :module
          mod.add_module(RDoc::NormalModule, name).tap { |m| m.store = @store }
        end
      # Set to true later if this module receives comment or documentable children
      created.ignore
      created
    }
    if root_name.empty?
      mod = @top_level
    else
      @nestings.reverse_each do |nesting|
        next if nesting.singleton
        mod = nesting.container.get_module_named(root_name)
        break if mod
        # If a constant is found and it is not a module or class, RDoc can't document about it.
        # Return an anonymous module to avoid wrong document creation.
        return RDoc::NormalModule.new(nil) if nesting.container.find_constant_named(root_name)
      end
      last_nesting = @nestings.reverse_each.find { |nesting| !nesting.singleton }
      return mod || add_module.call(last_nesting.container, root_name, create_mode) unless name
      mod ||= add_module.call(last_nesting.container, root_name, :module)
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
    @nestings.reverse_each do |nesting|
      next if nesting.singleton
      mod = nesting.container.get_module_named(owner_name)
      break if mod
    end
    mod ||= @top_level.get_module_named(owner_name)
    [mod.full_name, path].compact.join('::') if mod
  end

  # Returns a pair of owner module and constant name from a given constant path.
  # Creates owner module if it does not exist.

  def find_or_create_constant_owner_name(constant_path)
    const_path, colon, name = constant_path.rpartition('::')
    if colon.empty? # class Foo
      # Within `class C` or `module C`, owner is C(== current container)
      # Within `class <<C`, owner is C.singleton_class
      # but RDoc don't track constants of a singleton class of module
      [(singleton? ? nil : current_container), name]
    elsif const_path.empty? # class ::Foo
      [@top_level, name]
    else # `class Foo::Bar` or `class ::Foo::Bar`
      [find_or_create_module_path(const_path, :module), name]
    end
  end

  # Adds a constant

  def add_constant(constant_name, rhs_name, start_line, end_line)
    comment, directives = consecutive_comment(start_line)
    apply_document_control_directive(directives) if directives
    handle_code_object_directives(current_container, directives) if directives
    owner, name = find_or_create_constant_owner_name(constant_name)
    return unless owner

    constant = RDoc::Constant.new(name, rhs_name, comment)
    constant.store = @store
    constant.line = start_line
    constant.parent = owner
    modifier_nodocs = [
      handle_modifier_directive(constant, start_line),
      handle_modifier_directive(constant, end_line)
    ].compact

    if @track_visibility && modifier_nodocs.include?(:nodoc_all)
      constant.document_self = nil
      owner.add_constant(constant)
    elsif @track_visibility && modifier_nodocs.include?(:nodoc)
      locally_mark_const_name_as_nodoc(constant.full_name)
      constant.ignore
    elsif container_accept_document?(owner)
      mark_container_documentable(owner)
      record_location(constant)
    else
      constant.ignore
    end

    owner.add_constant(constant)
    mod =
      if rhs_name =~ /^::/
        @store.find_class_or_module(rhs_name)
      else
        full_name = resolve_constant_path(rhs_name)
        @store.find_class_or_module(full_name)
      end
    if mod
      a = current_container.add_module_alias(mod, rhs_name, constant, @top_level)
      a.store = @store
      a.line = start_line
      record_location(a)
    end
  end

  # Adds module or class

  def add_module_or_class(module_name, start_line, end_line, is_class: false, superclass_name: nil, superclass_expr: nil)
    comment, directives = consecutive_comment(start_line)
    apply_document_control_directive(directives) if directives
    handle_code_object_directives(current_container, directives) if directives

    owner, name = find_or_create_constant_owner_name(module_name)
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
      mod = owner.classes_hash[name]
      unless mod
        mod = owner.add_class(RDoc::NormalClass, name, superclass_name || superclass_expr || '::Object')
        mod.ignore
      end

      if superclass_name
        if superclass
          mod.superclass = superclass
        elsif (mod.superclass.is_a?(String) || mod.superclass.name == 'Object') && mod.superclass != superclass_full_path
          mod.superclass = superclass_full_path
        end
      end
    else
      mod = owner.modules_hash[name]
      unless mod
        mod = owner.add_module(RDoc::NormalModule, name)
        mod.ignore
      end
    end

    mod.store = @store
    mod.line = start_line
    modifier_nodocs = [
      handle_modifier_directive(mod, start_line),
      handle_modifier_directive(mod, end_line)
    ]

    nodoc = false
    if @track_visibility && modifier_nodocs.include?(:nodoc_all)
      mod.document_self = nil
      nodoc = true
    elsif @track_visibility && modifier_nodocs.include?(:nodoc)
      locally_mark_const_name_as_nodoc(mod.full_name)
      nodoc = true
    elsif container_accept_document?(owner) && !locally_marked_as_nodoc?(mod)
      mark_container_documentable(owner)
      mark_container_documentable(mod)
      record_location(mod)
      mod.add_comment(comment, @top_level) if comment
    end

    [mod, nodoc]
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
      return if @scanner.in_proc_block?
      @scanner.process_comments_until(node.location.start_line - 1)
      return unless node.old_name.is_a?(Prism::SymbolNode) && node.new_name.is_a?(Prism::SymbolNode)
      @scanner.add_alias_method(node.old_name.value.to_s, node.new_name.value.to_s, node.location.start_line)
    end

    def visit_module_node(node)
      node.constant_path.accept(self)
      @scanner.process_comments_until(node.location.start_line - 1)
      module_name = constant_path_string(node.constant_path)
      mod, nodoc = @scanner.add_module_or_class(module_name, node.location.start_line, node.location.end_line) if module_name
      if mod
        @scanner.with_container(mod) do
          @scanner.current_nesting.doc_state = :enddoc if nodoc
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
      klass, nodoc = @scanner.add_module_or_class(class_name, node.location.start_line, node.location.end_line, is_class: true, superclass_name: superclass_name, superclass_expr: superclass_expr) if class_name
      if klass
        @scanner.with_container(klass) do
          @scanner.current_nesting.doc_state = :enddoc if nodoc
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

      case expression
      when Prism::ConstantWriteNode
        # Accept `class << (NameErrorCheckers = Object.new)` as a module which is not actually a module
        mod = @scanner.current_container.add_module(RDoc::NormalModule, expression.name.to_s)
      when Prism::ConstantPathNode, Prism::ConstantReadNode
        expression_name = constant_path_string(expression)
        # If a constant_path does not exist, RDoc creates a module
        mod = @scanner.find_or_create_module_path(expression_name, :module) if expression_name
      when Prism::SelfNode
        mod = @scanner.current_container if @scanner.current_container != @top_level
      end
      expression.accept(self)
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

      return if @scanner.in_proc_block?

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
        return if @scanner.singleton?
        visibility = :public
        singleton = true
      when Prism::ConstantReadNode, Prism::ConstantPathNode
        visibility = :public
        singleton = true
        receiver_name = constant_path_string(node.receiver)
        receiver_fallback_type = :module
        return unless receiver_name
      when nil
        visibility = @scanner.current_visibility
        singleton = @scanner.singleton?
      else
        # `def (unknown expression).method_name` is not documentable
        return
      end
      name = node.name.to_s
      params, block_params, calls_super = MethodSignatureVisitor.scan_signature(node)
      tokens = @scanner.visible_tokens_from_location(node.location)

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

      @scanner.add_constant(
        path,
        constant_path_string(node.value) || node.value.slice,
        node.location.start_line,
        node.location.end_line
      )
      @scanner.skip_comments_until(node.location.end_line)
      # Do not traverse rhs not to document `A::B = Struct.new{def undocumentable_method; end}`
    end

    def visit_constant_write_node(node)
      @scanner.process_comments_until(node.location.start_line - 1)
      @scanner.add_constant(
        node.name.to_s,
        constant_path_string(node.value) || node.value.slice,
        node.location.start_line,
        node.location.end_line
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
      return unless call_node.arguments&.arguments&.size == 1
      arg = call_node.arguments.arguments.first
      return unless arg.is_a?(Prism::StringNode)
      @scanner.current_container.add_require(RDoc::Require.new(arg.unescaped, nil))
    end

    def _visit_call_module_function(call_node)
      return if @scanner.in_proc_block? || @scanner.singleton?
      names = visibility_method_arguments(call_node, singleton: false)&.map(&:to_s)
      @scanner.change_method_to_module_function(names) if names
    end

    def _visit_call_public_private_class_method(call_node, visibility)
      return if @scanner.in_proc_block? || @scanner.singleton?
      names = visibility_method_arguments(call_node, singleton: true)
      @scanner.change_method_visibility(names, visibility, singleton: true) if names
    end

    def _visit_call_public_private_protected(call_node, visibility)
      return if @scanner.in_proc_block?
      arguments_node = call_node.arguments
      if arguments_node.nil? # `public` `private`
        @scanner.current_visibility = visibility
      else # `public :foo, :bar`, `private def foo; end`
        names = visibility_method_arguments(call_node, singleton: false)
        @scanner.change_method_visibility(names, visibility) if names
      end
    end

    def _visit_call_alias_method(call_node)
      return if @scanner.in_proc_block?

      new_name, old_name, *rest = symbol_arguments(call_node)
      return unless old_name && new_name && rest.empty?
      @scanner.add_alias_method(old_name.to_s, new_name.to_s, call_node.location.start_line)
    end

    def _visit_call_include(call_node)
      return if @scanner.in_proc_block?

      names = constant_arguments_names(call_node)
      line_no = call_node.location.start_line
      return unless names

      if @scanner.singleton?
        @scanner.add_extends(names, line_no)
      else
        @scanner.add_includes(names, line_no)
      end
    end

    def _visit_call_extend(call_node)
      return if @scanner.in_proc_block?

      names = constant_arguments_names(call_node)
      @scanner.add_extends(names, call_node.location.start_line) if names && !@scanner.singleton?
    end

    def _visit_call_public_constant(call_node)
      return if @scanner.in_proc_block? || @scanner.singleton?
      names = symbol_arguments(call_node)
      @scanner.current_container.set_constant_visibility_for(names.map(&:to_s), :public) if names
    end

    def _visit_call_private_constant(call_node)
      return if @scanner.in_proc_block? || @scanner.singleton?
      names = symbol_arguments(call_node)
      @scanner.current_container.set_constant_visibility_for(names.map(&:to_s), :private) if names
    end

    def _visit_call_attr_reader_writer_accessor(call_node, rw)
      return if @scanner.in_proc_block?
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
