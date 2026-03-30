# frozen_string_literal: true

require 'erb'
require 'pathname'
require 'rbs'
require 'rdoc/markup/formatter'

##
# RBS type signature support.
# Loads type information from .rbs files, validates inline annotations,
# and converts type signatures to HTML with linked type names.

module RDoc
  module RbsHelper
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
      # Converts type signature lines to HTML with type names linked to
      # their documentation pages. Uses the RBS parser to extract type
      # name locations precisely.
      #
      # +lines+ is an Array of signature line strings.
      # +lookup+ is a Hash mapping type names to their doc paths.
      # +from_path+ is the current page path for generating relative URLs.
      #
      # Returns escaped HTML with +->+ replaced by +→+.

      def signature_to_html(lines, lookup:, from_path:)
        lines.map { |line|
          link_type_names_in_line(line, lookup, from_path).gsub('-&gt;', '&rarr;')
        }.join("\n")
      end

      private

      def link_type_names_in_line(line, lookup, from_path)
        escaped = ERB::Util.html_escape(line)

        locs = collect_type_name_locations(line)
        return escaped if locs.empty?

        result = escaped.dup

        # Replace type names with links, working backwards to preserve positions.
        # HTML escaping (e.g. -> becomes -&gt;) shifts positions, so we
        # re-escape the prefix to find the correct offset in the result.
        locs.sort_by { |l| -l[:start] }.each do |loc|
          name = loc[:name]
          next unless (target_path = lookup[name])

          prefix = ERB::Util.html_escape(line[0...loc[:start]])
          escaped_name = ERB::Util.html_escape(name)
          start_in_escaped = prefix.length
          end_in_escaped = start_in_escaped + escaped_name.length

          href = ::RDoc::Markup::Formatter.gen_relative_url(from_path, target_path)
          result[start_in_escaped...end_in_escaped] =
            "<a href=\"#{href}\" class=\"rbs-type\">#{escaped_name}</a>"
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
            locs << { name: name, start: name_loc.end_pos - name.length }
          end
          type.args.each { |a| collect_from_type(a, locs) }
        when RBS::Types::Union, RBS::Types::Intersection, RBS::Types::Tuple
          type.types.each { |t| collect_from_type(t, locs) }
        when RBS::Types::Optional
          collect_from_type(type.type, locs)
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
