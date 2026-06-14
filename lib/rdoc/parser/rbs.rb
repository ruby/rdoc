# frozen_string_literal: true

require 'rbs'

##
# Parse RBS signature files as first-class RDoc input.

class RDoc::Parser::RBS < RDoc::Parser
  RBS_FILE_EXTENSION = /\.rbs$/

  parse_files_matching RBS_FILE_EXTENSION

  def scan
    _, _, decls = ::RBS::Parser.parse_signature(@content)
    decls.each do |decl|
      parse_decl decl, @top_level
    end
    @top_level
  end

  private

  def record_object_location(object, location)
    object.line = location.start_line if location

    if RDoc::ClassModule === object
      @top_level.add_to_classes_or_modules object unless
        @top_level.classes_or_modules.include? object
      object.record_location @top_level
    else
      object.record_location @top_level
    end

    object
  end

  def rdoc_comment_for(decl, context)
    rbs_comment = decl.comment if decl.respond_to?(:comment)
    return unless rbs_comment

    # TODO: Run RBS comments through RDoc's directive preprocessor so
    # directives like :nodoc: affect the documented object.
    comment = RDoc::Comment.new rbs_comment.string, context
    comment.format = 'markdown'
    comment
  end

  def local_module_name(type_name, namespace)
    name = type_name.to_s
    return name if name.start_with?('::')

    namespace_names = namespace ? namespace.to_s.split('::') : []

    namespace_names.length.downto(1) do |length|
      qualified_name = namespace_names.take(length).join('::')
      if module_name = @top_level.find_module_named("#{qualified_name}::#{name}")
        return module_name.full_name
      end
    end

    name
  end

  def merge_attr_rw(existing_rw, new_rw)
    rw = +''
    rw << 'R' if existing_rw.include?('R') || new_rw.include?('R')
    rw << 'W' if existing_rw.include?('W') || new_rw.include?('W')
    rw
  end

  def merge_documentation(object, comment, type_signature_lines)
    if comment
      object.comment = if object.comment.empty?
                         comment
                       else
                         "#{object.comment}\n---\n#{comment}"
                       end
    end

    # TODO: Track RBS-owned documentation overlays so incremental reparsing can
    # replace stale comments and signatures from the previous RBS parse.
    object.type_signature_lines ||= type_signature_lines
  end

  def rdoc_method_name(decl)
    rbs_constructor_decl?(decl) ? 'new' : decl.name.to_s
  end

  def rdoc_method_singleton?(decl)
    # TODO: RBS `self?` methods are :singleton_instance and should add both a
    # singleton method and a private instance method.
    rbs_constructor_decl?(decl) || decl.singleton?
  end

  def rdoc_method_visibility(decl)
    rbs_constructor_decl?(decl) ? :public : decl.visibility
  end

  def rbs_constructor_decl?(decl)
    decl.kind == :instance && decl.name == :initialize
  end

  def parse_attr_decl(decl, context)
    rw = case decl
         when ::RBS::AST::Members::AttrReader
           'R'
         when ::RBS::AST::Members::AttrWriter
           'W'
         when ::RBS::AST::Members::AttrAccessor
           'RW'
         end

    comment = rdoc_comment_for(decl, context)
    type_signature_lines = [decl.type.to_s]
    if attribute = context.find_attribute(decl.name.to_s, decl.kind == :singleton)
      merge_documentation attribute, comment, type_signature_lines
      attribute.rw = merge_attr_rw attribute.rw, rw
      return
    end

    attribute = RDoc::Attr.new(
      decl.name.to_s,
      rw,
      comment,
      singleton: decl.kind == :singleton
    )
    record_object_location attribute, decl.location
    attribute.type_signature_lines = type_signature_lines
    context.add_attribute attribute
    attribute.visibility = decl.visibility if decl.visibility
  end

  def parse_class_decl(decl, context, namespace)
    name = context == @top_level && namespace ? namespace + decl.name : decl.name
    superclass = decl.super_class&.name&.to_s || '::Object'
    klass = context.add_class RDoc::NormalClass, name.to_s, superclass
    record_object_location klass, decl.location
    klass.add_comment rdoc_comment_for(decl, @top_level), @top_level if decl.comment

    nested_namespace = namespace ? namespace + decl.name : decl.name
    decl.members.each { |member| parse_decl member, klass, nested_namespace }
  end

  def parse_constant_decl(decl, context)
    constant = RDoc::Constant.new decl.name.to_s, decl.type.to_s,
                                  rdoc_comment_for(decl, context)
    record_object_location constant, decl.location
    context.add_constant constant
  end

  def parse_decl(decl, context, namespace = nil)
    case decl
    when ::RBS::AST::Declarations::Class
      parse_class_decl decl, context, namespace
    when ::RBS::AST::Declarations::Module, ::RBS::AST::Declarations::Interface
      parse_module_decl decl, context, namespace
    when ::RBS::AST::Declarations::ClassAlias,
         ::RBS::AST::Declarations::ModuleAlias
      # TODO: Add RBS class and module aliases to the RDoc store.
      nil
    else
      parse_member_decl decl, context, namespace
    end
  end

  def parse_extend_decl(decl, context, namespace)
    extend_decl = RDoc::Extend.new local_module_name(decl.name, namespace),
                                   rdoc_comment_for(decl, context)
    record_object_location extend_decl, decl.location
    context.add_extend extend_decl
  end

  def parse_include_decl(decl, context, namespace)
    include_decl = RDoc::Include.new local_module_name(decl.name, namespace),
                                    rdoc_comment_for(decl, context)
    record_object_location include_decl, decl.location
    context.add_include include_decl
  end

  def parse_member_decl(decl, context, namespace)
    case decl
    when ::RBS::AST::Declarations::Constant
      parse_constant_decl decl, context
    when ::RBS::AST::Members::MethodDefinition
      parse_method_decl decl, context
    when ::RBS::AST::Members::Alias
      parse_method_alias_decl decl, context
    when ::RBS::AST::Members::AttrReader,
         ::RBS::AST::Members::AttrWriter,
         ::RBS::AST::Members::AttrAccessor
      parse_attr_decl decl, context
    when ::RBS::AST::Members::Include
      parse_include_decl decl, context, namespace
    when ::RBS::AST::Members::Extend
      parse_extend_decl decl, context, namespace
    when ::RBS::AST::Members::Private,
         ::RBS::AST::Members::Public
      # TODO: Track standalone RBS visibility members.
      nil
    end
  end

  def parse_method_alias_decl(decl, context)
    alias_def = RDoc::Alias.new(
      decl.old_name.to_s,
      decl.new_name.to_s,
      rdoc_comment_for(decl, context),
      singleton: decl.kind == :singleton
    )
    record_object_location alias_def, decl.location
    context.add_alias alias_def
  end

  def parse_method_decl(decl, context)
    comment = rdoc_comment_for(decl, context)
    type_signature_lines = decl.overloads.map { |overload| overload.method_type.to_s }
    method_name = rdoc_method_name(decl)
    singleton = rdoc_method_singleton?(decl)
    visibility = rdoc_method_visibility(decl)

    if method = context.find_method(method_name, singleton)
      merge_documentation method, comment, type_signature_lines
      return
    end

    method = RDoc::AnyMethod.new method_name, singleton: singleton
    record_object_location method, decl.location
    method.type_signature_lines = type_signature_lines

    if loc = decl.location
      method.start_collecting_tokens :ruby
      method.add_token line_no: loc.start_line, char_no: 1, text: loc.source
    end

    method.comment = comment if decl.comment
    context.add_method method
    method.visibility = visibility if visibility
  end

  def parse_module_decl(decl, context, namespace)
    name = context == @top_level && namespace ? namespace + decl.name : decl.name
    mod = context.add_module RDoc::NormalModule, name.to_s
    record_object_location mod, decl.location
    mod.add_comment rdoc_comment_for(decl, @top_level), @top_level if decl.comment

    nested_namespace = namespace ? namespace + decl.name : decl.name
    decl.members.each { |member| parse_decl member, mod, nested_namespace }
  end
end
