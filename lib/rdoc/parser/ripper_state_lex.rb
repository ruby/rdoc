require 'ripper'

class RipperStateLex
  EXPR_NONE = 0
  EXPR_BEG = 1
  EXPR_END = 2
  EXPR_ENDARG = 4
  EXPR_ENDFN = 8
  EXPR_ARG = 16
  EXPR_CMDARG = 32
  EXPR_MID = 64
  EXPR_FNAME = 128
  EXPR_DOT = 256
  EXPR_CLASS = 512
  EXPR_LABEL = 1024
  EXPR_LABELED = 2048
  EXPR_FITEM = 4096
  EXPR_VALUE = EXPR_BEG
  EXPR_BEG_ANY  =  (EXPR_BEG | EXPR_MID | EXPR_CLASS)
  EXPR_ARG_ANY  =  (EXPR_ARG | EXPR_CMDARG)
  EXPR_END_ANY  =  (EXPR_END | EXPR_ENDARG | EXPR_ENDFN)

  class InnerStateLex < Ripper::Filter
    include Enumerable

    def initialize(code)
      @lex_state = EXPR_BEG
      @in_fname = false
      @continue = false
      reset
      super(code)
    end

    def reset
      @command_start = false
      @cmd_state = @command_start
    end

    def on_nl(tok, data)
      case @lex_state
      when EXPR_FNAME, EXPR_DOT
        @continue = true
      else
        @continue = false
        @lex_state = EXPR_BEG
      end
      @callback.call({ :line_no => lineno, :char_no => column, :kind => __method__, :text => tok, :state => @lex_state})
    end

    def on_ignored_nl(tok, data)
      case @lex_state
      when EXPR_FNAME, EXPR_DOT
        @continue = true
      else
        @continue = false
        @lex_state = EXPR_BEG
      end
      @callback.call({ :line_no => lineno, :char_no => column, :kind => __method__, :text => tok, :state => @lex_state})
    end

    def on_op(tok, data)
      case tok
      when '!', '!=', '!~'
        @lex_state = EXPR_BEG
      when '<<'
        # TODO next token?
        case @lex_state
        when EXPR_FNAME, EXPR_DOT
          @lex_state = EXPR_ARG
        else
          @lex_state = EXPR_BEG
        end
      when '?'
        @lex_state = :EXPR_BEG
      when '&', '&&',
           '|', '||', '+=', '-=', '*=', '**=',
           '&=', '|=', '^=', '<<=', '>>=', '||=', '&&='
        @lex_state = EXPR_BEG
      when ')', ']', '}'
        @lex_state = EXPR_END
      else
        case @lex_state
        when EXPR_FNAME, EXPR_DOT
          @lex_state = EXPR_ARG
        else
          @lex_state = EXPR_BEG
        end
      end
      @callback.call({ :line_no => lineno, :char_no => column, :kind => __method__, :text => tok, :state => @lex_state})
    end

    def on_kw(tok, data)
      case tok
      when 'class'
        @lex_state = EXPR_CLASS
        @in_fname = true
      when 'def'
        @lex_state = EXPR_FNAME
        @continue = true
        @in_fname = true
      when 'if', 'unless'
        if ((EXPR_END | EXPR_ENDARG | EXPR_ENDFN | EXPR_CMDARG) & @lex_state) != 0 # postfix if
          @lex_state = EXPR_BEG | EXPR_LABEL
        else
          @lex_state = EXPR_BEG
        end
      else
        if @lex_state == EXPR_FNAME
          @lex_state = EXPR_END
        else
          @lex_state = EXPR_END
        end
      end
      @callback.call({ :line_no => lineno, :char_no => column, :kind => __method__, :text => tok, :state => @lex_state})
    end

    def on_tstring_beg(tok, data)
      @lex_state = EXPR_BEG
      @callback.call({ :line_no => lineno, :char_no => column, :kind => __method__, :text => tok, :state => @lex_state})
    end

    def on_tstring_end(tok, data)
      @lex_state = EXPR_END | EXPR_ENDARG
      @callback.call({ :line_no => lineno, :char_no => column, :kind => __method__, :text => tok, :state => @lex_state})
    end

    def on_CHAR(tok, data)
      @lex_state = EXPR_END
      @callback.call({ :line_no => lineno, :char_no => column, :kind => __method__, :text => tok, :state => @lex_state})
    end

    def on_period(tok, data)
      @lex_state = EXPR_DOT
      @callback.call({ :line_no => lineno, :char_no => column, :kind => __method__, :text => tok, :state => @lex_state})
    end

    def on_int(tok, data)
      @lex_state = EXPR_END | EXPR_ENDARG
      @callback.call({ :line_no => lineno, :char_no => column, :kind => __method__, :text => tok, :state => @lex_state})
    end

    def on_symbeg(tok, data)
      @lex_state = EXPR_FNAME
      @continue = true
      @in_fname = true
      @callback.call({ :line_no => lineno, :char_no => column, :kind => __method__, :text => tok, :state => @lex_state})
    end

    private def on_variables(event, tok, data)
      if @in_fname
        @lex_state = EXPR_ENDFN
        @in_fname = false
        @continue = false
      elsif @continue
        case @lex_state
        when EXPR_DOT
          @lex_state = EXPR_ARG
        else
          @lex_state = EXPR_ENDFN
          @continue = false
        end
      else
        @lex_state = EXPR_CMDARG
      end
      @callback.call({ :line_no => lineno, :char_no => column, :kind => event, :text => tok, :state => @lex_state})
    end

    def on_ident(tok, data)
      on_variables(__method__, tok, data)
    end

    def on_ivar(tok, data)
      on_variables(__method__, tok, data)
    end

    def on_cvar(tok, data)
      on_variables(__method__, tok, data)
    end

    def on_gvar(tok, data)
      on_variables(__method__, tok, data)
    end

    def on_lparen(tok, data)
      @lex_state = EXPR_LABEL | EXPR_BEG
      @callback.call({ :line_no => lineno, :char_no => column, :kind => __method__, :text => tok, :state => @lex_state})
    end

    def on_rparen(tok, data)
      @lex_state = EXPR_ENDFN
      @callback.call({ :line_no => lineno, :char_no => column, :kind => __method__, :text => tok, :state => @lex_state})
    end

    def on_const(tok, data)
      case @lex_state
      when EXPR_FNAME
        @lex_state = EXPR_ENDFN
      when EXPR_CLASS
        @lex_state = EXPR_ARG
      else
        @lex_state = EXPR_CMDARG
      end
      @callback.call({ :line_no => lineno, :char_no => column, :kind => __method__, :text => tok, :state => @lex_state})
    end

    def on_sp(tok, data)
      @callback.call({ :line_no => lineno, :char_no => column, :kind => __method__, :text => tok, :state => @lex_state})
    end

    def on_comment(tok, data)
      @lex_state = EXPR_BEG
      @callback.call({ :line_no => lineno, :char_no => column, :kind => __method__, :text => tok, :state => @lex_state})
    end

    def on_default(event, tok, data)
      reset
      @callback.call({ :line_no => lineno, :char_no => column, :kind => event, :text => tok, :state => @lex_state})
    end

    def each(&block)
      @callback = block
      parse
    end
  end

  def get_squashed_tk
    if @buf.empty?
      tk = @inner_lex.next
    else
      tk = @buf.shift
    end
    case tk[:kind]
    when :on_symbeg then
      is_symbol = true
      symbol_tk = { :line_no => tk[:line_no], :char_no => tk[:char_no], :kind => :on_symbol }
      case (tk1 = get_squashed_tk)[:kind]
      when :on_ident
        symbol_tk[:text] = ":#{tk1[:text]}"
        symbol_tk[:state] = tk1[:state]
      when :on_tstring_content
        symbol_tk[:text] = ":#{tk1[:text]}"
        symbol_tk[:state] = get_squashed_tk[:state] # skip :on_tstring_end
      when :on_tstring_end
        symbol_tk[:text] = ":#{tk1[:text]}"
        symbol_tk[:state] = tk1[:state]
      when :on_op
        symbol_tk[:text] = ":#{tk1[:text]}"
        symbol_tk[:state] = tk1[:state]
      #when :on_symbols_beg
      #when :on_qsymbols_beg
      else
        is_symbol = false
        tk = tk1
      end
      if is_symbol
        tk = symbol_tk
      end
    when :on_tstring_beg, :on_backtick then
      string = tk[:text]
      state = nil
      if :on_backtick == tk[:kind]
        expanded = true
      else
        expanded = false
      end
      loop do
        inner_str_tk = get_squashed_tk
        if inner_str_tk.nil?
          break
        elsif :on_tstring_end == inner_str_tk[:kind]
          string = string + inner_str_tk[:text]
          state = inner_str_tk[:state]
          break
        else
          string = string + inner_str_tk[:text]
          if :on_tstring_content != inner_str_tk[:kind] then
            expanded = true
          end
        end
      end
      tk = { :line_no => tk[:line_no], :char_no => tk[:char_no], :kind => expanded ? :on_dstring : :on_tstring, :text => string, :state => state }
    when :on_regexp_beg then
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
      tk = { :line_no => tk[:line_no], :char_no => tk[:char_no], :kind => :on_regexp, :text => string, :state => state }
    when :on_embdoc_beg then
      string = ''
      until :on_embdoc_end == (embdoc_tk = get_squashed_tk)[:kind] do
        string = string + embdoc_tk[:text]
      end
      tk = { :line_no => tk[:line_no], :char_no => tk[:char_no], :kind => :on_embdoc, :text => string, :state => embdoc_tk[:state] }
    when :on_op then
      if tk[:text] =~ /^[-+]$/ then
        tk_ahead = get_squashed_tk
        case tk_ahead[:kind]
        when :on_int, :on_float, :on_rational, :on_imaginary
          tk[:text] += tk_ahead[:text]
          tk[:kind] = tk_ahead[:kind]
          tk[:state] = tk_ahead[:state]
        else
          @buf.unshift tk_ahead
        end
      end
    end
    tk
  end

  def initialize(code)
    @buf = []
    @inner_lex = Enumerator.new do |y|
      InnerStateLex.new(code).each do |tk|
        y << tk
      end
    end
  end

  def self.parse(code)
    lex = RipperStateLex.new(code)
    tokens = []
    begin
      while tk = lex.get_squashed_tk
        tokens.push tk
      end
    rescue StopIteration
    end
    tokens
  end

  def self.end?(token)
    (token[:state] & EXPR_END)
  end
end
