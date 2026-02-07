# frozen_string_literal: true
require 'prism'

##
# Wrapper for Prism lex with Ripper-compatible API

class RDoc::Parser::RipperStateLex
  Token = Struct.new(:line_no, :char_no, :kind, :text, :state)

  # Lexer states from Ripper
  EXPR_END   = 0x2    # 2 - Expression ends
  EXPR_ENDFN = 0x8    # 8 - Function definition ends
  EXPR_ARG   = 0x10   # 16 - Inside argument list
  EXPR_FNAME = 0x80   # 128 - Inside function name
  EXPR_LABEL = 0x400  # 1024 - Label in hash literal

  REDEFINABLE_OPERATORS = %w[! != !~ % & * ** + +@ - -@ / < << <= <=> == === =~ > >= >> [] []= ^ ` | ~].freeze

  # Returns tokens parsed from +code+.
  def self.parse(code)
    lex = self.new(code)
    tokens = []
    begin
      while tk = lex.get_squashed_tk
        tokens.push tk
      end
    rescue StopIteration
    end
    tokens
  end

  # Returns +true+ if lex state will be +END+ after +token+.
  def self.end?(token)
    (token[:state] & EXPR_END)
  end

  # New lexer for +code+.
  def initialize(code)
    @buf = []
    @heredoc_queue = []
    # Use Prism.lex_compat for Ripper-compatible tokenization
    lex_result = Prism.lex_compat(code)
    prism_tokens = lex_result.value.map do |(pos, kind, text, state)|
      line_no, char_no = pos
      # Convert Ripper::Lexer::State to integer to avoid Ripper dependency
      state_int = state.respond_to?(:to_i) ? state.to_i : state
      Token.new(line_no, char_no, kind, text, state_int)
    end

    # Prism.lex_compat omits :on_sp tokens, so we need to insert them for proper
    # syntax highlighting and token stream reconstruction
    tokens_with_spaces = insert_space_tokens(prism_tokens, code)

    # Fix Prism incompatibility: Prism returns :on_ignored_nl after `def foo; end`
    # but parsers expect :on_nl for proper token collection in single-line methods
    @tokens = normalize_ignored_nl_for_single_line_methods(tokens_with_spaces)
  end

  def get_squashed_tk
    if @buf.empty?
      tk = @tokens.shift
    else
      tk = @buf.shift
    end
    return nil if tk.nil?
    case tk[:kind]
    when :on_symbeg
      tk = get_symbol_tk(tk)
    when :on_tstring_beg
      tk = get_string_tk(tk)
    when :on_backtick
      if (tk[:state] & (EXPR_FNAME | EXPR_ENDFN)) != 0
        tk[:kind] = :on_ident
        tk[:state] = EXPR_ARG
      else
        tk = get_string_tk(tk)
      end
    when :on_regexp_beg
      tk = get_regexp_tk(tk)
    when :on_embdoc_beg
      tk = get_embdoc_tk(tk)
    when :on_heredoc_beg
      @heredoc_queue << retrieve_heredoc_info(tk)
    when :on_nl, :on_ignored_nl, :on_comment, :on_heredoc_end
      if !@heredoc_queue.empty?
        get_heredoc_tk(*@heredoc_queue.shift)
      elsif tk[:text].nil? # :on_ignored_nl sometimes gives nil
        tk[:text] = ''
      end
    when :on_words_beg, :on_qwords_beg, :on_symbols_beg, :on_qsymbols_beg
      tk = get_words_tk(tk)
    when :on_op
      if '&.' == tk[:text]
        tk[:kind] = :on_period
      else
        tk = get_op_tk(tk)
      end
    end
    tk
  end

  private

  def get_symbol_tk(tk)
    is_symbol = true
    symbol_tk = Token.new(tk.line_no, tk.char_no, :on_symbol)
    if ":'" == tk[:text] or ':"' == tk[:text] or tk[:text].start_with?('%s')
      tk1 = get_string_tk(tk)
      symbol_tk[:text] = tk1[:text]
      symbol_tk[:state] = tk1[:state]
    else
      case (tk1 = get_squashed_tk)[:kind]
      when :on_tstring_content
        symbol_tk[:text] = ":#{tk1[:text]}"
        symbol_tk[:state] = get_squashed_tk[:state] # skip :on_tstring_end
      when :on_ident, :on_tstring_end, :on_op, :on_ivar, :on_cvar, :on_const, :on_kw
        symbol_tk[:text] = ":#{tk1[:text]}"
        symbol_tk[:state] = tk1[:state]
      else
        is_symbol = false
        tk = tk1
      end
    end
    if is_symbol
      tk = symbol_tk
    end
    tk
  end

  def get_string_tk(tk)
    string = tk[:text]
    state = nil
    kind = :on_tstring
    loop do
      inner_str_tk = get_squashed_tk
      if inner_str_tk.nil?
        break
      elsif :on_tstring_end == inner_str_tk[:kind]
        string = string + inner_str_tk[:text]
        state = inner_str_tk[:state]
        break
      elsif :on_label_end == inner_str_tk[:kind]
        string = string + inner_str_tk[:text]
        state = inner_str_tk[:state]
        kind = :on_symbol
        break
      else
        string = string + inner_str_tk[:text]
        if :on_embexpr_beg == inner_str_tk[:kind]
          kind = :on_dstring if :on_tstring == kind
        end
      end
    end
    Token.new(tk.line_no, tk.char_no, kind, string, state)
  end

  def get_regexp_tk(tk)
    string = tk[:text]
    state = nil
    loop do
      inner_str_tk = get_squashed_tk
      if inner_str_tk.nil?
        break
      elsif :on_regexp_end == inner_str_tk[:kind]
        string = string + inner_str_tk[:text]
        state = inner_str_tk[:state]
        break
      else
        string = string + inner_str_tk[:text]
      end
    end
    Token.new(tk.line_no, tk.char_no, :on_regexp, string, state)
  end

  def get_embdoc_tk(tk)
    string = tk[:text]
    until :on_embdoc_end == (embdoc_tk = get_squashed_tk)[:kind] do
      string = string + embdoc_tk[:text]
    end
    string = string + embdoc_tk[:text]
    Token.new(tk.line_no, tk.char_no, :on_embdoc, string, embdoc_tk.state)
  end

  def get_heredoc_tk(heredoc_name, indent)
    string = +''
    start_tk = nil
    prev_tk = nil
    until heredoc_end?(heredoc_name, indent, tk = @tokens.shift) do
      start_tk = tk unless start_tk
      if (prev_tk.nil? or "\n" == prev_tk[:text][-1]) and 0 != tk[:char_no]
        string << (' ' * tk[:char_no])
      end
      string << tk[:text]
      prev_tk = tk
    end
    start_tk = tk unless start_tk
    prev_tk = tk unless prev_tk
    @buf.unshift tk # closing heredoc
    heredoc_tk = Token.new(start_tk.line_no, start_tk.char_no, :on_heredoc, string, prev_tk.state)
    @buf.unshift heredoc_tk
  end

  def retrieve_heredoc_info(tk)
    name = tk[:text].gsub(/\A<<[-~]?(['"`]?)(.+)\1\z/, '\2')
    indent = tk[:text] =~ /\A<<[-~]/
    [name, indent]
  end

  def heredoc_end?(name, indent, tk)
    result = false
    if :on_heredoc_end == tk[:kind]
      tk_name = tk[:text].chomp
      tk_name.lstrip! if indent
      if name == tk_name
        result = true
      end
    end
    result
  end

  def get_words_tk(tk)
    string = +''
    start_token = tk[:text]
    start_quote = tk[:text].rstrip[-1]
    line_no = tk[:line_no]
    char_no = tk[:char_no]
    state = tk[:state]
    end_quote =
      case start_quote
      when ?( then ?)
      when ?[ then ?]
      when ?{ then ?}
      when ?< then ?>
      else start_quote
      end
    end_token = nil
    loop do
      tk = get_squashed_tk
      if tk.nil?
        end_token = end_quote
        break
      elsif :on_tstring_content == tk[:kind]
        string << tk[:text]
      elsif :on_words_sep == tk[:kind] or :on_tstring_end == tk[:kind]
        if end_quote == tk[:text].strip
          end_token = tk[:text]
          break
        else
          string << tk[:text]
        end
      else
        string << tk[:text]
      end
    end
    text = "#{start_token}#{string}#{end_token}"
    Token.new(line_no, char_no, :on_dstring, text, state)
  end

  def get_op_tk(tk)
    if REDEFINABLE_OPERATORS.include?(tk[:text]) and tk[:state] == EXPR_ARG
      tk[:state] = EXPR_ARG
      tk[:kind] = :on_ident
    elsif tk[:text] =~ /^[-+]$/
      tk_ahead = get_squashed_tk
      case tk_ahead[:kind]
      when :on_int, :on_float, :on_rational, :on_imaginary, :on_heredoc_beg, :on_tstring, :on_dstring
        tk[:text] += tk_ahead[:text]
        tk[:kind] = tk_ahead[:kind]
        tk[:state] = tk_ahead[:state]
      else
        @buf.unshift tk_ahead
      end
    end
    tk
  end

  def normalize_ignored_nl_for_single_line_methods(tokens)
    tokens.each_cons(2) do |prev_token, token|
      # Convert :on_ignored_nl to :on_nl when it follows an `end` keyword on the same line
      # This ensures proper token collection for single-line method definitions
      if token.kind == :on_ignored_nl &&
         prev_token.kind == :on_kw && prev_token.text == 'end' &&
         prev_token.line_no == token.line_no
        token[:kind] = :on_nl
      end
    end
    tokens
  end

  def insert_space_tokens(tokens, code)
    return tokens if tokens.empty?

    lines = code.lines
    result = []
    prev_token = nil

    tokens.each_with_index do |token, i|
      # Check for leading spaces at the start of a line
      # (when current token is not on the same line as previous token and doesn't start at column 0)
      if prev_token && prev_token.line_no < token.line_no && token.char_no > 0
        # There are leading spaces on this line
        line_text = lines[token.line_no - 1]
        if line_text
          leading_spaces = line_text[0...token.char_no]
          if leading_spaces && !leading_spaces.empty? && leading_spaces.match?(/\A\s+\z/)
            space_token = Token.new(token.line_no, 0, :on_sp, leading_spaces, prev_token.state)
            result << space_token
          end
        end
      end

      result << token

      next_token = tokens[i + 1]
      current_end_col = token.char_no + token.text.length

      # Insert space tokens for gaps between tokens on the same line
      if next_token && next_token.line_no == token.line_no && current_end_col < next_token.char_no
        space_text = lines[token.line_no - 1][current_end_col...next_token.char_no]
        if space_text && !space_text.empty?
          space_token = Token.new(token.line_no, current_end_col, :on_sp, space_text, token.state)
          result << space_token
        end
      # Handle backslash-newline line continuations for proper display
      elsif next_token && next_token.line_no > token.line_no
        rest_of_line = lines[token.line_no - 1][current_end_col..-1]
        if rest_of_line&.match?(/\A\s*\\\n?\z/)
          # Insert space tokens for whitespace and backslash-newline
          space_token = Token.new(token.line_no, current_end_col, :on_sp, rest_of_line, token.state)
          result << space_token
        end
      end

      prev_token = token
    end

    result
  end
end
