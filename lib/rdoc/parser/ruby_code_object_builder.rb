# frozen_string_literal: true

##
# Builds CodeObjects from the IR records emitted by RDoc::Parser::Ruby.
# Records are replayed in emission order.
#
# A scope-opening record may resolve to no container (for example inside a
# <tt>:nodoc: all</tt> region). Records inside such a scope are dropped,
# mirroring the traversal skip of the visitor before the IR split.

class RDoc::Parser::Ruby::CodeObjectBuilder # :nodoc:

  def initialize(top_level, store, options, stats, preprocess, track_visibility:)
    @top_level = top_level
    @store = store
    @options = options
    @stats = stats
    @preprocess = preprocess
    @track_visibility = track_visibility
    # Scope stack of [container, singleton] pairs representing Ruby lexical nesting
    @scope_stack = [[top_level, false]]
    # Scope id => resolved container (nil if the scope is not documentable)
    @scopes = {}
    @dead_scope_depth = 0
  end

  def run(records)
    records.each do |record|
      process(record)
    end
  end

  private

  def container
    @scope_stack.last[0]
  end

  def singleton?
    @scope_stack.last[1]
  end

  def process(record)
    case record[:type]
    when :scope_enter
      enter_scope(record)
      return
    when :scope_exit
      exit_scope
      return
    end
    return if @dead_scope_depth > 0

    case record[:type]
    when :scope_open then process_scope_open(record)
    when :singleton_scope_constant_write
      # Accept `class << (NameErrorCheckers = Object.new)` as a module which is not actually a module
      mod = container.add_module(RDoc::NormalModule, record[:name])
      mod.ignore if record[:suppressed] && mod.in_files.empty?
      @scopes[record[:id]] = mod
    when :singleton_scope_path
      # If a constant_path does not exist, RDoc creates a module
      @scopes[record[:id]] = find_or_create_lexical_module_path(record[:name], :module, suppressed: record[:suppressed])
    when :singleton_scope_self
      @scopes[record[:id]] = container
    when :method then process_method(record)
    when :constant then process_constant(record)
    when :attributes then process_attributes(record)
    when :include then process_include_extend(record, RDoc::Include)
    when :extend then process_include_extend(record, RDoc::Extend)
    when :alias_method then process_alias_method(record)
    when :change_method_visibility
      change_method_visibility(record[:names], record[:visibility], record[:singleton], record[:suppressed])
    when :module_function then change_method_to_module_function(record[:names], record[:suppressed])
    when :constant_visibility
      container.set_constant_visibility_for(record[:names], record[:visibility])
    when :require then container.add_require(RDoc::Require.new(record[:name], nil))
    when :section then process_section(record)
    when :container_directives then process_container_directives(record)
    when :meta_comment then process_meta_comment(record)
    when :tomdoc_comment then process_tomdoc_comment(record)
    end
  end

  def enter_scope(record)
    if @dead_scope_depth > 0 || (mod = @scopes[record[:id]]).nil?
      @dead_scope_depth += 1
    else
      @scope_stack.push([mod, record[:singleton]])
    end
  end

  def exit_scope
    if @dead_scope_depth > 0
      @dead_scope_depth -= 1
    else
      @scope_stack.pop
    end
  end

  # Builds an RDoc::Comment from a comment payload and returns
  # +[comment, directives, type_signature_lines]+. Type signature validation
  # and comment post-processes must run only when the consuming record is
  # replayed in a live scope, so they happen here and not at emission time.

  def materialize_comment(payload)
    return unless payload
    if payload[:type_signature_lines]
      warn_invalid_type_signature(payload[:type_signature_lines], payload[:type_signature_line_no])
    end
    comment = RDoc::Comment.new(payload[:text], @top_level, :ruby)
    comment.normalized = true
    comment.line = payload[:start_line]
    comment.format = payload[:format]
    @preprocess.run_post_processes(comment, container)
    if payload[:startdoc] && !container.ignored?
      # Compatibility: `module Net #:nodoc:` followed by :stopdoc:/:startdoc:
      # regions is a common pattern that expects :startdoc: to make the
      # container documentable again. Containers ignored here were created
      # in a suppressed region and need documentable contents to revive.
      container.start_doc
      container.force_documentation = true
    end
    [comment, payload[:directives], payload[:type_signature_lines]]
  end

  def warn_invalid_type_signature(type_signature_lines, line_no)
    type_signature_lines.each_with_index do |line, i|
      next if RDoc::RbsHelper.valid_method_type?(line)
      next if RDoc::RbsHelper.valid_type?(line)
      @options.warn "#{@top_level.relative_name}:#{line_no + i}: invalid RBS type signature: #{line.inspect}"
    end
  end

  def handle_code_object_directives(code_object, directives)
    directives.each do |directive, (param)|
      # startdoc/stopdoc/enddoc are handled by apply_document_control_directive.
      # They control the lexical scope of the parser, not the code object.
      next if directive == 'startdoc' || directive == 'stopdoc' || directive == 'enddoc'
      @preprocess.handle_directive('', directive, param, code_object)
    end
  end

  # Makes a container that was created inside a :stopdoc:/:enddoc: region
  # (thus ignored) documentable again when it receives documentable contents
  # outside the region, possibly from another file.

  def mark_container_documentable(container)
    return if container.received_nodoc || !container.ignored?
    record_location(container)
    container.start_doc
    mark_container_documentable(container.parent) if container.parent.is_a?(RDoc::ClassModule)
  end

  def should_document?(code_object)
    return true unless @track_visibility
    return false if code_object.parent&.document_children == false
    code_object.document_self
  end

  # Records the location of this +code_object+ in the file for this parser and
  # adds it to the list of classes and modules in the file.

  def record_location(code_object)
    case code_object
    when RDoc::ClassModule then
      @top_level.add_to_classes_or_modules code_object
    end

    code_object.record_location @top_level
  end

  def process_scope_open(record)
    comment, directives = materialize_comment(record[:comment])
    handle_code_object_directives(container, directives) if directives
    return unless container.document_children

    suppressed = record[:suppressed]
    owner, name = find_or_create_lexical_constant_owner_name(record[:name], suppressed: suppressed)
    return unless owner

    if record[:kind] == :class
      superclass_name = record[:superclass_name]
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
        # add_class may return an existing class created by another file
        # (in_files is not empty then), which must not be ignored here
        mod = owner.add_class(RDoc::NormalClass, name, superclass_name || record[:superclass_expr] || '::Object')
        mod.ignore if suppressed && mod.in_files.empty?
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
        mod.ignore if suppressed && mod.in_files.empty?
      end
    end

    mod.store = @store
    mod.line = record[:line_no]
    record[:modifier_directives_list].each do |modifier_directives|
      handle_code_object_directives(mod, modifier_directives)
    end
    unless suppressed
      # In a :stopdoc:/:enddoc: region, the container is still created as a
      # namespace but is not recorded to this file nor documented.
      # The body is also visited: an inner :startdoc: re-enables documentation
      # in a :stopdoc: region (not in an :enddoc: region), and nested
      # namespaces need to be created for later promotion from other files
      if mod.ignored?
        # Promotes the owner chain too, unless mod received :nodoc:
        mark_container_documentable(mod)
      else
        # A class/module marked :nodoc: must not make an ignored owner documentable
        mark_container_documentable(owner) if mod.document_self && owner.is_a?(RDoc::ClassModule)
        record_location(mod)
      end
      mod.add_comment(comment, @top_level) if comment
    end
    @scopes[record[:id]] = mod
  end

  def process_method(record)
    comment, directives, type_signature_lines = materialize_comment(record[:comment])
    handle_code_object_directives(container, directives) if directives
    # Resolve receiver after applying directives so that a namespace created
    # here is marked as ignored when the comment starts a :stopdoc: region
    receiver = record[:receiver_name] ? find_or_create_lexical_module_path(record[:receiver_name], record[:receiver_fallback_type], suppressed: record[:suppressed]) : container

    internal_add_method(
      record[:name],
      receiver,
      comment: comment,
      directives: directives,
      modifier_directives_list: record[:modifier_directives_list],
      line_no: record[:line_no],
      visibility: record[:visibility],
      singleton: record[:singleton],
      suppressed: record[:suppressed],
      params: record[:params],
      calls_super: record[:calls_super],
      block_params: record[:block_params],
      tokens: record[:tokens],
      type_signature_lines: type_signature_lines
    )
  end

  def internal_add_method(method_name, container, comment:, dont_rename_initialize: false, directives:, modifier_directives_list: nil, line_no:, visibility:, singleton:, suppressed:, params:, calls_super:, block_params:, tokens:, type_signature_lines: nil)
    meth = RDoc::AnyMethod.new(method_name, singleton: singleton)
    meth.comment = comment
    handle_code_object_directives(meth, directives) if directives
    modifier_directives_list&.each do |modifier_directives|
      handle_code_object_directives(meth, modifier_directives)
    end
    return if suppressed
    return unless should_document?(meth)

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

  def process_constant(record)
    comment, directives = materialize_comment(record[:comment])
    handle_code_object_directives(container, directives) if directives
    return if record[:suppressed]

    owner, name = find_or_create_lexical_constant_owner_name(record[:constant_name], suppressed: record[:suppressed])
    return unless owner

    constant = RDoc::Constant.new(name, record[:rhs_name], comment)
    constant.store = @store
    constant.line = record[:line_no]
    alias_path = record[:alias_path]
    constant.is_alias_for_path = alias_path
    record[:modifier_directives_list].each do |modifier_directives|
      handle_code_object_directives(constant, modifier_directives)
    end
    # A constant marked :nodoc: must not make an ignored owner documentable
    mark_container_documentable(owner) if constant.document_self && owner.is_a?(RDoc::ClassModule)
    record_location(constant)
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
      a.line = record[:line_no]
      record_location(a)
    end
  end

  def process_attributes(record)
    comment, directives, type_signature_lines = materialize_comment(record[:comment])
    handle_code_object_directives(container, directives) if directives
    return if record[:suppressed]
    return unless container.document_children

    record[:names].each do |name|
      a = RDoc::Attr.new(name, record[:rw], comment, singleton: record[:singleton])
      a.store = @store
      a.line = record[:line_no]
      a.type_signature_lines = type_signature_lines
      record_location(a)
      handle_code_object_directives(a, record[:modifier_directives]) if record[:modifier_directives]
      if should_document?(a)
        container.add_attribute(a)
        mark_container_documentable(container)
      end
      a.visibility = record[:visibility] # should set after adding to container
    end
  end

  def process_include_extend(record, rdoc_class)
    comment, directives = materialize_comment(record[:comment])
    handle_code_object_directives(container, directives) if directives
    return if record[:suppressed]

    mark_container_documentable(container)
    record[:names].each do |name|
      resolved_name = resolve_constant_path(name)
      ie = container.add(rdoc_class, resolved_name || name, '')
      ie.store = @store
      ie.line = record[:line_no]
      ie.comment = comment
      record_location(ie)
    end
  end

  def process_alias_method(record)
    comment, directives = materialize_comment(record[:comment])
    handle_code_object_directives(container, directives) if directives
    return if record[:suppressed]

    singleton = record[:singleton]
    visibility = container.find_method(record[:old_name], singleton)&.visibility || :public
    a = RDoc::Alias.new(record[:old_name], record[:new_name], comment, singleton: singleton)
    handle_code_object_directives(a, record[:modifier_directives]) if record[:modifier_directives]
    a.store = @store
    a.line = record[:line_no]
    record_location(a)
    if should_document?(a)
      mark_container_documentable(container)
      container.add_alias(a)
      container.find_method(record[:new_name], singleton)&.visibility = visibility
    end
  end

  # Handles `public :foo, :bar` `private :foo, :bar` and `protected :foo, :bar`

  def change_method_visibility(names, visibility, singleton, suppressed)
    new_methods = []
    container.methods_matching(names, singleton) do |m|
      if m.parent != container
        # A copy of an ancestor's method must not be documented
        # in a :stopdoc:/:enddoc: region
        next if suppressed
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
        container.add_method(method)
      when RDoc::Attr then
        container.add_attribute(method)
      end
      method.visibility = visibility
    end
  end

  # Handles `module_function :foo, :bar`

  def change_method_to_module_function(names, suppressed)
    container.set_visibility_for(names, :private, false)
    # In a :stopdoc:/:enddoc: region, the visibility of instance methods still
    # changes but the singleton method copies must not be documented
    return if suppressed

    new_methods = []
    container.methods_matching(names) do |m|
      s_m = m.dup
      record_location(s_m)
      s_m.singleton = true
      new_methods << s_m
    end
    new_methods.each do |method|
      case method
      when RDoc::AnyMethod then
        container.add_method(method)
      when RDoc::Attr then
        container.add_attribute(method)
      end
      method.visibility = :public
    end
  end

  def process_section(record)
    if record[:type_signature_lines]
      warn_invalid_type_signature(record[:type_signature_lines], record[:type_signature_line_no])
    end
    comment = RDoc::Comment.new(record[:text], @top_level, :ruby)
    comment.normalized = true
    comment.line = record[:start_line]
    comment.format = record[:format]
    container.set_current_section(record[:title], comment)
  end

  def process_container_directives(record)
    _comment, directives = materialize_comment(record[:comment])
    handle_code_object_directives(container, directives)
  end

  # Handles meta method comments

  def process_meta_comment(record)
    comment, directives = materialize_comment(record[:comment])
    handle_code_object_directives(container, directives)
    node = record[:node]
    singleton_method = false
    visibility = record[:visibility]
    attributes = rw = line_no = method_name = nil
    directives.each do |directive, (param, line)|
      case directive
      when 'attr', 'attr_reader', 'attr_writer', 'attr_accessor'
        attributes = [param] if param
        attributes ||= node[:name_arguments] if node&.[](:is_call_node)
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

    return if record[:suppressed]

    if attributes
      attributes.each do |attr|
        a = RDoc::Attr.new(attr, rw, comment, singleton: record[:singleton])
        a.store = @store
        a.line = line_no
        record_location(a)
        container.add_attribute(a)
        mark_container_documentable(container)
        a.visibility = visibility
      end
    elsif line_no || node
      method_name ||= node[:name_arguments].first if node&.[](:is_call_node)
      if node
        tokens = node[:tokens]
        line_no = node[:start_line]
      else
        tokens = []
      end
      internal_add_method(
        method_name,
        container,
        comment: comment,
        directives: directives,
        dont_rename_initialize: false,
        line_no: line_no,
        visibility: visibility,
        singleton: record[:singleton] || singleton_method,
        suppressed: record[:suppressed],
        params: nil,
        calls_super: false,
        block_params: nil,
        tokens: tokens,
      )
    end
  end

  # Creates an RDoc::Method if there is a Signature section in the tomdoc comment

  def process_tomdoc_comment(record)
    comment = RDoc::Comment.new(record[:text], @top_level, :ruby)
    comment.format = 'tomdoc'
    parse_comment_tomdoc(comment, record[:start_line], record[:tokens]) unless record[:suppressed]
    @preprocess.run_post_processes(comment, container)
  end

  def parse_comment_tomdoc(comment, start_line, tokens)
    return unless signature = RDoc::TomDoc.signature(comment)

    name, = signature.split %r%[ \(]%, 2

    meth = RDoc::AnyMethod.new name
    record_location(meth)
    meth.line = start_line
    meth.call_seq = signature
    return unless meth.name

    meth.start_collecting_tokens(:ruby)
    tokens.each { |token| meth.token_stream << token }

    container.add_method meth
    meth.comment = comment
    @stats.add_method meth
  end

  # Find or create module or class from a given module name using Ruby lexical
  # nesting. If module or class does not exist, creates a module or a class
  # according to `create_mode` argument.

  def find_or_create_lexical_module_path(module_name, create_mode, suppressed: false)
    root_name, *path, name = module_name.split('::')
    add_module = ->(mod, name, mode) {
      created =
        case mode
        when :class
          mod.add_class(RDoc::NormalClass, name, 'Object').tap { |m| m.store = @store }
        when :module
          mod.add_module(RDoc::NormalModule, name).tap { |m| m.store = @store }
        end
      # add_class/add_module may return an existing object created by another
      # file (in_files is not empty then), which must not be ignored here.
      # Documentable again when reopened or receiving contents outside the region.
      created.ignore if suppressed && created.in_files.empty?
      created
    }
    if root_name.empty?
      mod = @top_level
    else
      @scope_stack.reverse_each do |nesting, singleton|
        next if singleton
        mod = nesting.get_module_named(root_name)
        break if mod
        # If a constant is found and it is not a module or class, RDoc can't document about it.
        # Return an anonymous module to avoid wrong document creation.
        return RDoc::NormalModule.new(nil) if nesting.find_constant_named(root_name)
      end
      last_nesting, = @scope_stack.reverse_each.find { |_, singleton| !singleton }
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
    @scope_stack.reverse_each do |nesting, singleton|
      next if singleton
      mod = nesting.get_module_named(owner_name)
      break if mod
    end
    mod ||= @top_level.get_module_named(owner_name)
    [mod.full_name, path].compact.join('::') if mod
  end

  # Returns a pair of owner module and constant name from a given constant path
  # using Ruby lexical nesting. Creates owner module if it does not exist.

  def find_or_create_lexical_constant_owner_name(constant_path, suppressed: false)
    const_path, colon, name = constant_path.rpartition('::')
    if colon.empty? # class Foo
      # Within `class C` or `module C`, owner is C(== current container)
      # Within `class <<C`, owner is C.singleton_class
      # but RDoc don't track constants of a singleton class of module
      [(singleton? ? nil : container), name]
    elsif const_path.empty? # class ::Foo
      [@top_level, name]
    else # `class Foo::Bar` or `class ::Foo::Bar`
      [find_or_create_lexical_module_path(const_path, :module, suppressed: suppressed), name]
    end
  end
end
