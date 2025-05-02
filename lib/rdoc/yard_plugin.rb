# Yard type parser is inspired by the following code:
# https://github.com/lsegal/yard-types-parser/blob/master/lib/yard_types_parser.rb

require_relative 'base_plugin'
require 'strscan'

module RDoc
  class YardPlugin < BasePlugin
    listens_to :rdoc_store_complete do |env, store|
      store.all_classes_and_modules.each do |cm|
        cm.each_method do |meth|
          puts "Parsing #{meth.name}"
          parsed_comment = Parser.new(meth.comment.text).parse
          # meth.params = parsed_comment.param.map(&:to_s).join("\n")
          meth.comment.text = parsed_comment.plain.join("\n")
        end
      end
    end

    class Parser
      ParamData = Struct.new(:type, :name, :desc, keyword_init: true) do
        def append_desc(line)
          self[:desc] += line
        end

        def to_s
          "Name: #{self[:name]}, Type: #{self[:type].map(&:to_s).join(' or ')}, Desc: #{self[:desc]}"
        end
      end
      ReturnData = Struct.new(:type, :desc, keyword_init: true)
      RaiseData = Struct.new(:type, :desc, keyword_init: true)
      ParsedComment = Struct.new(:param, :return, :raise, :plain)

      TAG_PARSING_REGEXES = {
        param: /
        @param\s+
          (?:                                 # Match either of the following:
          \[(?<type1>[^\]]+)\]\s+(?<name1>\S+)\s*(?<desc1>.*)? |  # [Type] name desc
          (?<name2>\S+)\s+\[(?<type2>[^\]]+)\]\s*(?<desc2>.*)?   # name [Type] desc
          )
        /x,
          return: /@return\s+\[(?<type>[^\]]+)\]\s*(?<desc>.*)?/,
          raise: /@raise\s+\[(?<type>[^\]]+)\]\s*(?<desc>.*)?/
      }
      def initialize(comment)
        @comment = comment
        @parsed_comment = ParsedComment.new([], nil, [], [])
        @mode = :initial
        @base_indentation_level = 0 # @comment.lines.first[/^#\s*/].size
      end

      def parse
        @comment.each_line do |line|
          current_indentation_level = line[/^#\s*/]&.size || 0
          if current_indentation_level >= @base_indentation_level + 2
            # Append to the previous tag
            data = @mode == :param ? @parsed_comment[@mode].last : @parsed_comment[@mode]
            data.append_desc(line)
          else
            if (tag, matchdata = matching_any_tag(line))
              if tag == :param
                type = matchdata[:type1] || matchdata[:type2]
                name = matchdata[:name1] || matchdata[:name2]
                desc = matchdata[:desc1] || matchdata[:desc2]
                parsed_type = TypeParser.parse(type)
                @parsed_comment[:param] << ParamData.new(type: parsed_type, name: name, desc: desc)
                @mode = :param
              elsif tag == :return
                type = matchdata[:type]
                desc = matchdata[:desc]
                parsed_type = TypeParser.parse(type)
                @parsed_comment[:return] = ReturnData.new(type: parsed_type, desc: desc)
                @mode = :return
              elsif tag == :raise
                type = matchdata[:type]
                desc = matchdata[:desc]
                parsed_type = TypeParser.parse(type)
                @parsed_comment[:raise] << RaiseData.new(type: parsed_type, desc: desc)
                @mode = :raise
              end
            else
              @parsed_comment[:plain] << line
            end
          end
          @base_indentation_level = current_indentation_level
        end

        @parsed_comment
      end

      private

      def matching_any_tag(line)
        TAG_PARSING_REGEXES.each do |tag, regex|
          matchdata = line.match(regex)
          return [tag, matchdata] if matchdata
        end
        nil
      end
    end

    class Type
      attr_reader :name

      def initialize(name)
        @name = name
      end

      def to_s
        @name
      end
    end

    class CollectionType < Type
      attr_reader :type

      def initialize(name, type)
        super(name)
        @type = type
      end

      def to_s
        "#{@name}<#{@type}>"
      end
    end

    class FixedCollectionType < Type
      attr_reader :type

      def initialize(name, type)
        super(name)
        @type = type
      end

      def to_s
        "#{@name}(#{@type})"
      end
    end

    class HashCollectionType < Type
      attr_reader :key_type, :value_type

      def initialize(name, key_type, value_type)
        super(name)
        @key_type = key_type
        @value_type = value_type
      end

      def to_s
        "#{@name}<#{@key_type} => #{@value_type}>"
      end
    end

    class TypeParser
      TOKENS = {
        collection_start: /</,
        collection_end: />/,
        fixed_collection_start: /\(/,
        fixed_collection_end: /\)/,
        type_name: /#\w+|((::)?\w+)+/,
        literal: /(?:
           '(?:\\'|[^'])*' |
           "(?:\\"|[^"])*" |
           :[a-zA-Z_][a-zA-Z0-9_]*|
           \b(?:true|false|nil)\b |
           \b\d+(?:\.\d+)?\b
          )/x,
        type_next: /[,;]/,
        whitespace: /\s+/,
        hash_collection_start: /\{/,
        hash_collection_next: /=>/,
        hash_collection_end: /\}/,
        parse_end: nil
      }

      def self.parse(string)
        new(string).parse
      end

      def initialize(string)
        @scanner = StringScanner.new(string)
      end

      def parse
        types = []
        type = nil
        fixed = false
        name = nil
        loop do
          found = false
          TOKENS.each do |token_type, match|
            if (match.nil? && @scanner.eos?) || (match && token = @scanner.scan(match))
              found = true
              case token_type
              when :type_name, :literal
                raise SyntaxError, "expecting END, got name '#{token}'" if name
                name = token
              when :type_next
                raise SyntaxError, "expecting name, got '#{token}' at #{@scanner.pos}" if name.nil?
                unless type
                  type = Type.new(name)
                end
                types << type
                type = nil
                name = nil
              when :fixed_collection_start, :collection_start
                name ||= "Array"
                klass = token_type == :collection_start ? CollectionType : FixedCollectionType
                type = klass.new(name, parse)
              when :hash_collection_start
                name ||= "Hash"
                type = HashCollectionType.new(name, parse, parse)
              when :hash_collection_next, :hash_collection_end, :fixed_collection_end, :collection_end, :parse_end
                raise SyntaxError, "expecting name, got '#{token}'" if name.nil?
                unless type
                  type = Type.new(name)
                end
                types << type
                return types
              end
            end
          end
          raise SyntaxError, "invalid character at #{@scanner.peek(1)}" unless found
        end
      end
    end
  end
end
