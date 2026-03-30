# frozen_string_literal: true

require 'erb'
require 'rbs'

##
# RBS type signature support.
# Loads type information from .rbs files, validates inline annotations,
# and converts type signatures to HTML with linked type names.

module RDoc
  module RbsSupport
    class << self

      ##
      # Validates an RBS method type signature string.
      # Returns nil if valid, or an error message string if invalid.

      def validate_method_type(sig)
        RBS::Parser.parse_method_type(sig, require_eof: true)
        nil
      rescue RBS::ParsingError => e
        e.message
      end

      ##
      # Validates an RBS type signature string.
      # Returns nil if valid, or an error message string if invalid.

      def validate_type(sig)
        RBS::Parser.parse_type(sig, require_eof: true)
        nil
      rescue RBS::ParsingError => e
        e.message
      end

      ##
      # Loads RBS signatures from the given directories.
      # Returns a Hash mapping "ClassName#method_name" => "type sig string".

      def load_signatures(*dirs)
        loader = RBS::EnvironmentLoader.new
        dirs.each { |dir| loader.add(path: Pathname(dir)) }

        env = RBS::Environment.new
        loader.load(env: env)

        signatures = {}

        env.class_decls.each do |type_name, entry|
          class_name = type_name.to_s.delete_prefix('::')

          entry.each_decl do |decl|
            decl.members.each do |member|
              case member
              when RBS::AST::Members::MethodDefinition
                key = member.singleton? ? "#{class_name}::#{member.name}" : "#{class_name}##{member.name}"
                sigs = member.overloads.map { |o| o.method_type.to_s }
                signatures[key] = sigs.join("\n")
              when RBS::AST::Members::AttrReader, RBS::AST::Members::AttrWriter, RBS::AST::Members::AttrAccessor
                key = "#{class_name}.#{member.name}"
                signatures[key] = member.type.to_s
              end
            end
          end
        end

        signatures
      end

      ##
      # Merges loaded RBS signatures into the store's code objects.
      # Inline #: annotations take priority and are not overwritten.

      def merge_into_store(store, signatures)
        store.all_classes_and_modules.each do |cm|
          cm.method_list.each do |method|
            next if method.type_signature

            key = method.singleton ? "#{cm.full_name}::#{method.name}" : "#{cm.full_name}##{method.name}"
            if (sig = signatures[key])
              method.type_signature = sig
            end
          end

          cm.attributes.each do |attr|
            next if attr.type_signature

            if (sig = signatures["#{cm.full_name}.#{attr.name}"])
              attr.type_signature = sig
            end
          end
        end
      end

      ##
      # Converts a type signature string to HTML with type names linked
      # to their documentation pages. Uses the RBS parser to extract type
      # name locations precisely.
      #
      # +lookup+ is a Hash mapping type names to their doc paths.
      # +&resolve_link+ is a block that receives (name, target_path) and
      # returns an HTML string for the link. This decouples RbsSupport
      # from the generator's URL resolution.
      #
      # Returns escaped HTML with +->+ replaced by +→+.

      def signature_to_html(signature, lookup: nil, &resolve_link)
        signature.split("\n").map { |line|
          html = link_type_names_in_line(line, lookup, &resolve_link)
          html.gsub('-&gt;', '&rarr;')
        }.join("\n")
      end

      private

      ##
      # Links type names in a single signature line using the RBS parser.
      # Falls back to plain HTML escaping if no lookup or block is given.

      def link_type_names_in_line(line, lookup, &resolve_link)
        escaped = ERB::Util.html_escape(line)
        return escaped unless lookup && resolve_link

        locs = collect_type_name_locations(line)
        return escaped if locs.empty?

        result = escaped.dup

        # Replace type names with links, working backwards to preserve positions
        locs.sort_by { |l| -l[:start] }.each do |loc|
          name = loc[:name]
          next unless lookup[name]

          # Map original string positions to escaped string positions.
          # HTML escaping (e.g. -> becomes -&gt;) shifts positions, so we
          # re-escape the prefix to find the correct offset in the result.
          prefix = ERB::Util.html_escape(line[0...loc[:start]])
          escaped_name = ERB::Util.html_escape(name)
          start_in_escaped = prefix.length
          end_in_escaped = start_in_escaped + escaped_name.length

          link = resolve_link.call(name, lookup[name])
          result[start_in_escaped...end_in_escaped] = link
        end

        result
      end

      ##
      # Extracts type name locations from a signature line using the RBS parser.

      def collect_type_name_locations(line)
        locs = []

        begin
          mt = RBS::Parser.parse_method_type(line, require_eof: true)
        rescue RBS::ParsingError
          begin
            type = RBS::Parser.parse_type(line, require_eof: true)
            collect_from_type(type, locs)
            return locs
          rescue RBS::ParsingError
            return locs
          end
        end

        mt.type.each_param { |p| collect_from_type(p.type, locs) }
        if mt.block
          mt.block.type.each_param { |p| collect_from_type(p.type, locs) }
          collect_from_type(mt.block.type.return_type, locs)
        end
        collect_from_type(mt.type.return_type, locs)

        locs
      end

      ##
      # Recursively collects type name locations from an RBS type AST node.

      def collect_from_type(type, locs)
        case type
        when RBS::Types::ClassInstance
          name = type.name.to_s.delete_prefix('::')
          if type.location
            name_loc = type.location[:name] || type.location
            locs << { name: name, start: name_loc.end_pos - name.length, stop: name_loc.end_pos }
          end
          type.args.each { |a| collect_from_type(a, locs) }
        when RBS::Types::Union, RBS::Types::Intersection
          type.types.each { |t| collect_from_type(t, locs) }
        when RBS::Types::Optional
          collect_from_type(type.type, locs)
        when RBS::Types::Tuple
          type.types.each { |t| collect_from_type(t, locs) }
        when RBS::Types::Record
          type.all_fields.each_value { |t| collect_from_type(t, locs) }
        when RBS::Types::Proc
          type.type.each_param { |p| collect_from_type(p.type, locs) }
          collect_from_type(type.type.return_type, locs)
        end
      end
    end
  end
end
