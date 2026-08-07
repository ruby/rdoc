# frozen_string_literal: true

##
# Resolves the namespaces declared by the IR of all Ruby files in a batch and
# creates them in the store before any file is built, so that name resolution
# during the build sees the declarations of all files instead of only the
# files built so far.
#
# Resolution is a pure function of the declaration table: it iterates the
# per-file lexical simulation until the table reaches a fixed point, because
# resolving one declaration's owner can depend on the names another
# declaration introduces (shadowing).
#
# An implicit namespace - the owner of `class B::C` when no B is declared
# anywhere - is never invented while a real declaration could resolve the
# name: in real Ruby such code raises NameError unless something defined B
# first, so preferring a real declaration matches every load order that
# works. Nested undeclared roots stay pending until the table is stable and
# are then pinned as implicit namespaces, outermost first.
#
# Namespaces are created as ignored ghosts with no recorded location.
# A ghost that receives documentable contents during the build is revived by
# the same mechanism that revives namespaces created inside a :stopdoc:
# region; a ghost that receives nothing stays out of the documentation.
# Unlike the build, the solver intentionally ignores documentation
# suppression (:nodoc: all regions and :enddoc:): those declarations still
# define real Ruby constants, so they participate in name resolution.

class RDoc::Parser::Ruby::NamespaceResolver # :nodoc:

  # Pass count backstop for adversarially nested inputs. Real code needs two
  # or three passes to converge, plus one pass per nesting depth of pinned
  # implicit namespaces.
  MAX_PASSES = 10

  def initialize(store)
    @store = store
  end

  def preload_namespaces(parsers)
    return if parsers.empty?
    irs = parsers.map(&:ir)
    namespaces, aliases = solve(irs)
    create_ghosts(namespaces, aliases, parsers.first.top_level)
  end

  private

  # The derived table is rebuilt every pass (a resolution may move when a
  # name declared elsewhere becomes visible), while pins are kept: an
  # implicit namespace is a decision, not a derivation, so re-deriving it
  # would make the iteration oscillate.

  def solve(irs)
    pins = {}
    namespaces = {}
    constants = {}
    aliases = {}
    MAX_PASSES.times do
      pass = Pass.new(@store, namespaces, constants, aliases, pins)
      irs.each { |ir| pass.simulate(ir) }
      converged = namespaces == pass.namespaces && constants == pass.constants && aliases == pass.aliases
      namespaces = pass.namespaces
      constants = pass.constants
      aliases = pass.aliases
      if converged
        break if pass.pending.empty?
        pin_shallowest_pending(pins, pass.pending)
      end
    end
    namespaces = pins.merge(namespaces) { |_full_name, pin_kind, kind| Pass.merge_kind(pin_kind, kind) }
    [namespaces, aliases]
  end

  # Pins the pending implicit namespaces at the shallowest depth, all at
  # once. A pending root has no real declaration anywhere in its frames (the
  # table is stable), so an outer implicit namespace can never hide a real
  # name, only let deeper pendings resolve to it instead of inventing their
  # own. Batching per depth bounds the pass count by the nesting depth
  # instead of the number of pendings.

  def pin_shallowest_pending(pins, pending)
    min_depth = pending.keys.map { |full_name| full_name.count(':') }.min
    pending.each do |full_name, kind|
      pins[full_name] = kind if full_name.count(':') == min_depth
    end
  end

  # Creates not-yet-existing namespaces in depth order so that parents are
  # created before children. Names whose parent chain goes through an alias
  # are skipped: their identity is provided by the module alias registration
  # during the build.

  def create_ghosts(namespaces, aliases, top_level)
    # The index tiebreak makes the depth sort stable: same-depth ghosts are
    # created in declaration order regardless of the sort algorithm
    namespaces.keys.sort_by.with_index { |full_name, index| [full_name.count(':'), index] }.each do |full_name|
      next if aliases.include?(full_name)
      next if @store.find_class_or_module(full_name)

      parent_name, colon, name = full_name.rpartition('::')
      if colon.empty?
        parent = top_level
      else
        parent = @store.find_class_or_module(parent_name)
        next unless parent
      end

      ghost =
        if namespaces[full_name] == :class
          parent.add_class(RDoc::NormalClass, name, 'Object')
        else
          # A namespace whose kind never became known falls back to a module
          parent.add_module(RDoc::NormalModule, name)
        end
      ghost.store = @store
      ghost.ignore
      ghost.namespace_ghost = true
    end
  end

  ##
  # One fixpoint pass: simulates the lexical scopes of every file and
  # accumulates the resolved names of all declarations. Lookups consult the
  # previous pass's table, the store (for namespaces of non-Ruby parsers)
  # and the names accumulated so far in this pass.

  class Pass # :nodoc:
    # How certain the kind of a namespace is: :unknown is promoted by either
    # concrete kind. A class declaration wins over a conflicting module
    # declaration of the same name, matching Context#add_class.
    KIND_STRENGTH = { unknown: 0, module: 1, class: 2 }.freeze

    def self.merge_kind(kind, other)
      return other unless kind
      return kind unless other
      KIND_STRENGTH[kind] >= KIND_STRENGTH[other] ? kind : other
    end

    attr_reader :namespaces, :constants, :aliases, :pending

    def initialize(store, prev_namespaces, prev_constants, prev_aliases, pins)
      @store = store
      @prev_namespaces = prev_namespaces
      @prev_constants = prev_constants
      @prev_aliases = prev_aliases
      @pins = pins
      @namespaces = {}
      @constants = {}
      @aliases = {}
      # Roots of nested declarations that no real declaration resolves,
      # candidates for pinning as implicit namespaces
      @pending = {}
    end

    # Simulates the lexical scopes of one file, accumulating declared names
    # and annotating each record with its resolved names. Records are
    # annotated on every pass; the fixpoint loop stops after a pass whose
    # lookup table equals its input, so the last annotations are the
    # converged ones.
    # Every resolved_* annotation is a full name String (or nil when
    # unresolvable) - the IR never references CodeObjects.

    def simulate(ir)
      # Frames are [full_name or nil, singleton]. A nil full_name marks an
      # unresolvable subtree (constant shadowing) whose declarations don't
      # introduce store-visible names, like the anonymous-module subtree of
      # the build.
      frames = [['', false]]
      scopes = {}
      ir.each do |record|
        case record[:type]
        when :scope_enter
          frames.push([scopes[record[:id]], record[:singleton]])
        when :scope_exit
          frames.pop
        when :scope_open
          resolved = declare_constant_owner_path(record[:name], record[:kind], frames)
          record[:resolved_full_name] = resolved
          if record[:superclass_name]
            # `class Cipher < Cipher` must not resolve the right-hand side to
            # the class the clause is defining
            record[:resolved_superclass] = resolve_reference(record[:superclass_name], frames, exclude: resolved)
          end
          scopes[record[:id]] = resolved
        when :singleton_scope_path
          scopes[record[:id]] = record[:resolved_full_name] = declare_module_path(record[:name], :unknown, frames)
        when :singleton_scope_constant_write
          frame_full_name, = frames.last
          if frame_full_name
            full_name = child_name(frame_full_name, record[:name])
            register_namespace(full_name, :unknown)
            scopes[record[:id]] = full_name
          else
            scopes[record[:id]] = nil
          end
        when :method
          if record[:receiver_name]
            # The :module fallback of a constant path receiver is a guess,
            # unlike the :class of the NilClass/TrueClass/FalseClass receivers
            kind = record[:receiver_fallback_type] == :class ? :class : :unknown
            record[:resolved_receiver] = declare_module_path(record[:receiver_name], kind, frames)
          end
        when :constant
          declare_constant(record, frames)
        when :include, :extend
          record[:resolved_names] = record[:names].map { |name| resolve_reference(name, frames) }
        end
      end
    end

    private

    def child_name(parent_full_name, name)
      parent_full_name.empty? ? name : "#{parent_full_name}::#{name}"
    end

    def namespace_kind(full_name)
      @namespaces[full_name] || @prev_namespaces[full_name] || @aliases[full_name] || @prev_aliases[full_name] ||
        @pins[full_name] ||
        (:class if @store.classes_hash[full_name]) || (:module if @store.modules_hash[full_name])
    end

    def constant?(full_name)
      @constants[full_name] || @prev_constants[full_name] || !@store.find_class_or_module(full_name) && store_constant?(full_name)
    end

    def store_constant?(full_name)
      owner_name, colon, name = full_name.rpartition('::')
      return false if colon.empty? # top level constants belong to Object, which the Ruby parser does not consult
      owner = @store.find_class_or_module(owner_name)
      owner ? !owner.constants_hash[name].nil? : false
    end

    def register_namespace(full_name, kind)
      @namespaces[full_name] = self.class.merge_kind(namespace_kind(full_name), kind)
    end

    # Resolves a module path with Ruby lexical nesting semantics and returns
    # its full name, declaring the not-yet-known parts: the innermost
    # non-singleton frame that has the root name wins, a same-named
    # non-namespace constant makes the path unresolvable (nil), and an
    # unknown root is declared at the innermost frame.

    # The names this path derives (the root of a top-level declaration and
    # everything below the root) are re-registered on every pass, whether
    # already known or not: the derived table is rebuilt per pass, so an
    # entry stays alive only while some record still derives it. Lookups
    # decide only which resolution is derived.

    def declare_module_path(module_name, create_mode, frames)
      root_name, *path, name = module_name.split('::')
      if root_name.empty?
        current = ''
      else
        root_kind = name ? :unknown : create_mode
        innermost_full_name, = frames.reverse_each.find { |_, singleton| !singleton }
        return nil if innermost_full_name.nil?
        if innermost_full_name.empty?
          # A top-level declaration resolves its root to ::root whether it is
          # declared or not, so the outcome is independent of the table.
          # A same-named non-namespace constant still makes it unresolvable.
          return nil if !namespace_kind(root_name) && constant?(root_name)
          register_namespace(root_name, namespace_kind(root_name) ? :unknown : root_kind)
          current = root_name
        else
          found = nil
          frames.reverse_each do |full_name, singleton|
            # An unresolvable (nil) frame corresponds to the build's anonymous
            # module: lookups pass through it to outer frames, but a name
            # created inside it does not become store-visible
            next if singleton || full_name.nil?
            candidate = child_name(full_name, root_name)
            if namespace_kind(candidate)
              found = candidate
              break
            end
            # If a constant is found and it is not a module or class, the
            # declaration cannot be resolved
            return nil if constant?(candidate)
          end
          unless found
            # A nested undeclared root must not be invented while a real
            # declaration could still resolve it; it stays pending until the
            # table is stable and is then pinned by the solve loop
            pending_name = child_name(innermost_full_name, root_name)
            @pending[pending_name] = self.class.merge_kind(@pending[pending_name], root_kind)
            return nil
          end
          current = found
        end
        return current unless name
      end
      path.each do |part|
        candidate = child_name(current, part)
        register_namespace(candidate, :unknown)
        current = candidate
      end
      candidate = child_name(current, name)
      register_namespace(candidate, namespace_kind(candidate) ? :unknown : create_mode)
      candidate
    end

    # Returns the resolved [owner full name, name] pair of a constant path.
    # The owner of a bare name is the current frame, except in a singleton
    # class, whose constants RDoc does not track.

    def resolve_constant_owner(constant_path, frames)
      const_path, colon, name = constant_path.rpartition('::')
      if colon.empty?
        full_name, singleton = frames.last
        singleton ? nil : full_name && [full_name, name]
      elsif const_path.empty?
        ['', name]
      else
        owner = declare_module_path(const_path, :unknown, frames)
        owner && [owner, name]
      end
    end

    def declare_constant_owner_path(constant_path, kind, frames)
      owner, name = resolve_constant_owner(constant_path, frames)
      return nil unless owner
      full_name = child_name(owner, name)
      register_namespace(full_name, kind)
      full_name
    end

    def declare_constant(record, frames)
      # The owner of a bare-named constant is the current container object of
      # the build (a specific TopLevel or an anonymous module), so only
      # `A::B = ...` forms are annotated with a resolved owner
      record[:resolved_owner] = nil
      owner, name = resolve_constant_owner(record[:constant_name], frames)
      return unless owner
      record[:resolved_owner] = owner if record[:constant_name].include?('::')
      full_name = child_name(owner, name)
      @constants[full_name] = true
      alias_path = record[:alias_path]
      return unless alias_path
      target = resolve_reference(alias_path, frames)
      record[:resolved_alias_target] = target
      if target && (kind = namespace_kind(target))
        # A module alias name resolves like a namespace but is registered by
        # the build, not created as a ghost
        @aliases[full_name] = kind
      end
    end

    # Resolves a reference (an include/extend target, a superclass or a
    # constant alias right-hand side) without creating anything

    def resolve_reference(constant_path, frames, exclude: nil)
      root_name, path = constant_path.split('::', 2)
      return constant_path.delete_prefix('::') if root_name.empty?
      found = nil
      frames.reverse_each do |full_name, singleton|
        next if singleton || full_name.nil?
        candidate = child_name(full_name, root_name)
        if candidate != exclude && namespace_kind(candidate)
          found = candidate
          break
        end
      end
      found = root_name if !found && root_name != exclude && namespace_kind(root_name)
      found && (path ? "#{found}::#{path}" : found)
    end
  end
end
