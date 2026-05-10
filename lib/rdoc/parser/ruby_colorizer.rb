# frozen_string_literal: true

require 'prism'
require 'set'

# Ruby code syntax highlighter.
# Colorize result is an array of +RDoc::Parser::RubyColorizer::ColoredToken+
# Actual color for each token kind is determined elsewhere (e.g., HTML generator)
module RDoc::Parser::RubyColorizer

  ColoredToken = Struct.new(:kind, :text)

  # Prism operator token types except assignment '='
  OP_TOKENS = %i[
    AMPERSAND AMPERSAND_AMPERSAND
    BANG BANG_EQUAL BANG_TILDE CARET COLON COLON_COLON
    EQUAL_EQUAL EQUAL_GREATER EQUAL_TILDE
    GREATER GREATER_GREATER
    LESS LESS_EQUAL LESS_EQUAL_GREATER LESS_LESS
    MINUS MINUS_GREATER PERCENT PIPE PIPE_PIPE PLUS
    QUESTION_MARK SLASH STAR STAR_STAR TILDE
    UAMPERSAND UMINUS UPLUS USTAR USTAR_STAR
  ].to_set

  # Prism token type to ColoredToken kind map
  TOKEN_TYPE_MAP = {
    IDENTIFIER: :identifier,
    METHOD_NAME: :identifier,
    INSTANCE_VARIABLE: :ivar,
    CLASS_VARIABLE: :identifier,
    GLOBAL_VARIABLE: :identifier,
    BACK_REFERENCE: :identifier,
    NUMBERED_REFERENCE: :identifier,
    CONSTANT: :constant,
    LABEL: :value,
    INTEGER: :value,
    FLOAT: :value,
    RATIONAL: :value,
    IMAGINARY: :value,
    COMMENT: :comment,
    EMBDOC_BEGIN: :comment,
    EMBDOC_LINE: :comment,
    EMBDOC_END: :comment
  }

  class << self

    # Colorize the entire +code+ and returns colored token stream.
    def colorize(code)
      result = Prism.parse_lex(code)
      program_node, unordered_tokens = result.value
      prism_tokens = unordered_tokens.map(&:first).sort_by! { |token| token.location.start_offset }
      partial_colorize(code, program_node, prism_tokens, 0, code.bytesize)
    end

    # Colorize partial +node+ in +whole_code+ and returns colored token stream.
    def partial_colorize(whole_code, node, prism_tokens, start_offset = nil, end_offset = nil)
      start_offset ||= node.location.start_offset
      end_offset ||= node.location.end_offset
      visitor = NodeColorizeVisitor.new
      node.accept(visitor)
      prior_tokens = visitor.tokens.sort_by {|_, start_offset, _| start_offset }
      normal_tokens = normal_tokens(slice_by_location(prism_tokens, start_offset, end_offset))
      colored_tokens = unify_tokens(whole_code, prior_tokens, normal_tokens, start_offset, end_offset)
      colored_tokens.unshift(ColoredToken.new(:plain, ' ' * node.location.start_column)) if node.location.start_column > 0
      colored_tokens
    end

    private

    def slice_by_location(items, start_offset, end_offset)
      start_index = items.bsearch_index { |item| item.location.end_offset > start_offset } || items.size
      end_index = items.bsearch_index { |item| item.location.start_offset >= end_offset } || items.size
      items[start_index...end_index]
    end

    # Unify prior tokens and normal tokens into a single token stream.
    # Prior tokens have higher priority than normal tokens.
    # Also adds missing text (spaces, newlines, etc.) as :plain tokens
    # so that the entire range is covered.
    def unify_tokens(whole_code, prior_tokens, normal_tokens, start_offset, end_offset)
      tokens = []
      offset = start_offset

      # Add missing text such as spaces and newlines as a separate :plain token
      flush = -> next_offset {
        return if offset == next_offset

        whole_code.byteslice(offset...next_offset).scan(/\n|\s+|[^\s]+/) do |text|
          tokens << ColoredToken.new(:plain, text)
        end
      }

      until prior_tokens.empty? && normal_tokens.empty?
        ptok = prior_tokens.first
        ntok = normal_tokens.first
        if ntok && (!ptok || ntok[2] <= ptok[1])
          token = normal_tokens.shift
        else
          token = prior_tokens.shift
        end
        kind, start_pos, end_pos = token
        next if start_pos < offset

        flush.call(start_pos)
        tokens << ColoredToken.new(kind, whole_code.byteslice(start_pos...end_pos))
        offset = end_pos
      end
      flush.call(end_offset)
      tokens
    end

    # Convert normal Prism tokens to [kind, start_offset, end_offset]
    def normal_tokens(tokens)
      tokens.map do |token,|
        kind =
          if token.type.start_with?('KEYWORD_')
            :keyword
          elsif OP_TOKENS.include?(token.type.to_sym)
            :operator
          else
            TOKEN_TYPE_MAP[token.type] || :plain
          end
        [kind, token.location.start_offset, token.location.end_offset]
      end
    end
  end

  # Visitor to determine node colorizing which can't be determined by tokens.
  # STRING_CONTENT/EMBEXPR_BEGIN/EMBEXPR_END in string/regexp/symbol have different colorizing
  class NodeColorizeVisitor < Prism::Visitor # :nodoc:
    attr_reader :tokens

    def initialize
      @tokens = []
    end

    def visit_symbol_node(node)
      # SymbolNode#location may contain heredoc content and closing
      # e.g., `<<A; :\\\nA\nsymbol`
      # So we need to colorize opening, content and closing separately.
      push_location(:symbol, node.opening_loc)
      push_location(:symbol, node.value_loc)
      push_location(:symbol, node.closing_loc)
    end

    def visit_interpolated_symbol_node(node)
      push_location(:symbol, node.opening_loc)
      handle_interpolated_parts(:symbol, node.parts)
      push_location(:symbol, node.closing_loc)
    end

    def visit_regular_expression_node(node)
      push_location(:regexp, node.location)
    end

    def visit_interpolated_regular_expression_node(node)
      push_location(:regexp, node.opening_loc)
      handle_interpolated_parts(:regexp, node.parts)
      push_location(:regexp, node.closing_loc)
    end

    alias visit_match_last_line_node visit_regular_expression_node
    alias visit_interpolated_match_last_line_node visit_interpolated_regular_expression_node

    def visit_string_node(node)
      # Node's location may not cover the entire string literal.
      # For example, in a heredoc string, the node's location covers only the heredoc opening.
      # We need to colorize opening, content and closing separately.
      push_location(:string, node.opening_loc)
      push_location(:string, node.content_loc)
      push_location(:string, node.closing_loc)
    end

    def visit_interpolated_string_node(node)
      push_location(:string, node.opening_loc)
      handle_interpolated_parts(:string, node.parts)
      push_location(:string, node.closing_loc)
    end

    def visit_x_string_node(node)
      # Same as visit_string_node, node.location of <<`X` only covers opening,
      # so we need to colorize opening, content and closing separately.
      push_location(:x_string, node.opening_loc)
      push_location(:x_string, node.content_loc)
      push_location(:x_string, node.closing_loc)
    end

    def visit_interpolated_x_string_node(node)
      push_location(:x_string, node.opening_loc)
      handle_interpolated_parts(:x_string, node.parts)
      push_location(:x_string, node.closing_loc)
    end

    def visit_array_node(node)
      super
      # Colorize %w[...] array literal like string literals, and %i[...] like symbol literals
      case node.opening
      when /\A%[wW].\z/
        push_location(:string, node.opening_loc)
        push_location(:string, node.closing_loc)
      when /\A%[iI].\z/
        push_location(:symbol, node.opening_loc)
        push_location(:symbol, node.closing_loc)
      end
    end

    def visit_def_node(node)
      # For special colorizing of method name in def node
      # e.g., `def <=>; end`
      push_location(:identifier, node.name_loc)
      super
    end

    private

    def push_location(kind, location)
      # Only push tokens that have a non-zero length
      if location && location.start_offset < location.end_offset
        @tokens << [kind, location.start_offset, location.end_offset]
      end
    end

    def handle_interpolated_parts(kind, parts)
      # StringNode, EmbeddedStatementsNode brackets, and EmbeddedVariableNode hash in
      # interpolated regexp/symbol/string parts should be colored as regexp/symbol/string respectively.
      parts.each do |part|
        case part
        when Prism::StringNode
          # InterpolatedStringNode#parts may have its own opening/closing. e.g., `'a' "b"`
          push_location(kind, part.opening_loc)
          push_location(kind, part.content_loc)
          push_location(kind, part.closing_loc)
        when Prism::InterpolatedStringNode
          # InterpolatedStringNode#parts may contain InterpolatedStringNode. e.g., `'a' "#{}"`
          part.accept(self)
        when Prism::EmbeddedStatementsNode
          push_location(kind, part.opening_loc)
          push_location(kind, part.closing_loc)
          part.accept(self)
        when Prism::EmbeddedVariableNode
          push_location(kind, part.operator_loc)
        end
      end
    end
  end

  private_constant :NodeColorizeVisitor
end
