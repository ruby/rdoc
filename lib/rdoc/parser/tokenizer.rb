require 'prism'
require 'set'

# Tokenize Ruby code as RDoc::Parser::RipperStateLex style types and token squashing.
# Token squashing is required by RDoc::TokenStream's syntax highlighting.
module RDoc::Parser::Tokenizer
  # This constants and token type map are for compatibility with RDoc::Parser::RipperStateLex.
  OTHER = :other
  SPACE = :on_sp
  NEWLINE = :on_nl
  KEYWORD = :on_kw
  OP = :on_op
  HEREDOC_BEG = :on_heredoc_beg
  HEREDOC_CONTENT = :on_heredoc
  HEREDOC_END = :on_heredoc_end
  COMMENT = :on_comment
  INTEGER = :on_int
  FLOAT = :on_float
  RATIONAL = :on_rational
  IMAGINARY = :on_imaginary
  SYMBOL = :on_symbol
  REGEXP = :on_regexp
  STRING = :on_tstring
  WORDS = :on_dstring
  DEF_METHOD_NAME = :on_ident
  DSTRING = :on_dstring

  OP_TOKENS = %i[
    AMPERSAND AMPERSAND_AMPERSAND
    BANG BANG_EQUAL BANG_TILDE CARET COLON COLON_COLON
    EQUAL EQUAL_EQUAL EQUAL_GREATER EQUAL_TILDE
    GREATER GREATER_GREATER
    LESS LESS_EQUAL LESS_EQUAL_GREATER LESS_LESS
    MINUS MINUS_GREATER PERCENT PIPE PIPE_PIPE PLUS
    QUESTION_MARK SLASH STAR STAR_STAR TILDE
    UAMPERSAND UMINUS UPLUS USTAR USTAR_STAR
  ].to_set

  TOKEN_TYPE_MAP = {
    IDENTIFIER: :on_ident,
    METHOD_NAME: :on_ident,
    INSTANCE_VARIABLE: :on_ivar,
    CLASS_VARIABLE: :on_cvar,
    GLOBAL_VARIABLE: :on_gvar,
    BACK_REFERENCE: :on_backref,
    NUMBERED_REFERENCE: :on_backref,
    CONSTANT: :on_const,
    LABEL: :on_label,
    INTEGER: :on_int,
    FLOAT: :on_float,
    RATIONAL: :on_rational,
    IMAGINARY: :on_imaginary,
  }

  class << self
    def tokenize(code)
      result = Prism.parse_lex(code)
      program_node, unordered_tokens = result.value
      prism_tokens = unordered_tokens.map(&:first).sort_by! { |token| token.location.start_offset }
      partial_tokenize(code, program_node, prism_tokens, result.comments, 0, code.bytesize)
    end

    def partial_tokenize(whole_code, node, prism_tokens, prism_comments, start_offset = nil, end_offset = nil)
      start_offset ||= node.location.start_offset
      end_offset ||= node.location.end_offset
      visitor = SquashTokenVisitor.new
      node.accept(visitor)
      squashed_tokens = visitor.tokens
      comment_tokens = comment_tokens(slice_by_location(prism_comments, start_offset, end_offset))
      normal_tokens = normal_tokens(slice_by_location(prism_tokens, start_offset, end_offset))
      prior_tokens = (squashed_tokens + comment_tokens).sort_by {|_, start_offset, _| start_offset }
      unify_tokens(whole_code, prior_tokens, normal_tokens, start_offset, end_offset)
    end

    private

    def slice_by_location(items, start_offset, end_offset)
      start_index = items.bsearch_index { |item| item.location.end_offset > start_offset } || items.size
      end_index = items.bsearch_index { |item| item.location.start_offset >= end_offset } || items.size
      items[start_index...end_index]
    end

    # Unify prior tokens and normal tokens into a token stream.
    # Prior tokens have higher priority than normal tokens.
    # Also adds missing text (spaces, newlines, etc.) as separate tokens
    # so that the entire code is covered.
    def unify_tokens(code, prior_tokens, normal_tokens, start_offset, end_offset)
      tokens = []
      offset = start_offset

      # Add missing text such as spaces and newlines as a separate token
      flush = -> next_offset {
        return if offset == next_offset

        code.byteslice(offset...next_offset).scan(/\n|\s+|[^\s]+/) do |text|
          type =
            if text == "\n"
              NEWLINE
            elsif /\A\s+\z/.match?(text)
              SPACE
            else
              OTHER
            end
          tokens << [type, text]
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
        type, start_pos, end_pos = token
        next if start_pos < offset

        flush.call(start_pos)
        tokens << [type, code.byteslice(start_pos...end_pos)]
        offset = end_pos
      end
      flush.call(end_offset)
      tokens
    end

    # Extract normal comment and embdoc comment (consists of multiple tokens) as a single token
    def comment_tokens(comments)
      comments.map do |comment|
        [COMMENT, comment.location.start_offset, comment.location.end_offset]
      end
    end

    # Convert normal Prism tokens to [type, start_offset, end_offset]
    def normal_tokens(tokens)
      tokens.map do |token,|
        type =
          if token.type.start_with?('KEYWORD_')
            KEYWORD
          elsif OP_TOKENS.include?(token.type.to_sym)
            OP
          else
            TOKEN_TYPE_MAP[token.type] || OTHER
          end
        [type, token.location.start_offset, token.location.end_offset]
      end
    end
  end

  # Visitor to squash several tokens that consist a single node into a single token
  class SquashTokenVisitor < Prism::Visitor
    attr_reader :tokens
    def initialize
      @tokens = []
    end

    # Squash UMINUS and its operand(integer, float, rational, imaginary) token into a single token
    def visit_integer_node(node)
      push_location(node.location, INTEGER)
    end

    def visit_float_node(node)
      push_location(node.location, FLOAT)
    end

    def visit_rational_node(node)
      push_location(node.location, RATIONAL)
    end

    def visit_imaginary_node(node)
      push_location(node.location, IMAGINARY)
    end

    def visit_symbol_node(node)
      push_location(node.location, SYMBOL)
    end
    alias visit_interpolated_symbol_node visit_symbol_node

    def visit_regular_expression_node(node)
      push_location(node.location, REGEXP)
    end
    alias visit_match_last_line_node visit_regular_expression_node
    alias visit_interpolated_regular_expression_node visit_regular_expression_node
    alias visit_interpolated_match_last_line_node visit_regular_expression_node

    def visit_string_node(node)
      # opening of StringNode inside InterpolatedStringNode might be nil
      if node.opening&.start_with?('<<')
        push_location(node.opening_loc, HEREDOC_BEG)
        push_location(node.content_loc, HEREDOC_CONTENT)
        push_location(node.closing_loc, HEREDOC_END)
      else
        push_location(node.location, STRING)
      end
    end
    alias visit_x_string_node visit_string_node

    def visit_array_node(node)
      # Right hand side of `a = 1,2` is an array node without opening
      if node.opening&.start_with?('%')
        # Percent array: squash entire node into a single token.
        # We don't handle embedded expressions inside yet.
        push_location(node.location, WORDS)
      else
        super
      end
    end

    def push_location(location, type)
      @tokens << [type, location.start_offset, location.end_offset]
    end

    def visit_def_node(node)
      # For special colorizing of method name in def node
      push_location(node.name_loc, DEF_METHOD_NAME)
      super
    end

    def visit_interpolated_string_node(node)
      # `"a" "b"` is an interpolated string node without opening
      if node.opening&.start_with?('<<')
        # Heredocs. Squash content into a single token.
        # We don't tokenize embedded expressions inside, and don't handle nested heredocs yet.
        push_location(node.opening_loc, HEREDOC_BEG)
        unless node.parts.empty?
          # Squash heredoc content into a single token
          part_locations = node.parts.map(&:location)
          @tokens << [
            HEREDOC_CONTENT,
            part_locations.map(&:start_offset).min,
            part_locations.map(&:end_offset).max
          ]
        end
        # incomplete heredoc might not have closing_loc
        push_location(node.closing_loc, HEREDOC_END) if node.closing_loc
      else
        # Squash entire node into a single token
        push_location(node.location, DSTRING)
      end
    end
    alias visit_interpolated_x_string_node visit_interpolated_string_node
  end
end
