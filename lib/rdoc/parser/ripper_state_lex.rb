require 'ripper'

class RipperStateLex < Ripper::Filter
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
    data.push({ :line_no => lineno, :char_no => column, :kind => __method__, :text => tok, :state => @lex_state})
  end

  def on_ignored_nl(tok, data)
    case @lex_state
    when EXPR_FNAME, EXPR_DOT
      @continue = true
    else
      @continue = false
      @lex_state = EXPR_BEG
    end
    data.push({ :line_no => lineno, :char_no => column, :kind => __method__, :text => tok, :state => @lex_state})
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
    else
      case @lex_state
      when EXPR_FNAME, EXPR_DOT
        @lex_state = EXPR_ARG
      else
        @lex_state = EXPR_BEG
      end
    end
    data.push({ :line_no => lineno, :char_no => column, :kind => __method__, :text => tok, :state => @lex_state})
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
    when 'if'
      @lex_state = EXPR_BEG
    else
      if @lex_state == EXPR_FNAME
        @lex_state = EXPR_END
      else
        @lex_state = EXPR_END
      end
    end
    data.push({ :line_no => lineno, :char_no => column, :kind => __method__, :text => tok, :state => @lex_state})
  end

  def on_tstring_beg(tok, data)
    @lex_state = EXPR_BEG
    data.push({ :line_no => lineno, :char_no => column, :kind => __method__, :text => tok, :state => @lex_state})
  end

  def on_tstring_end(tok, data)
    @lex_state = EXPR_END
    data.push({ :line_no => lineno, :char_no => column, :kind => __method__, :text => tok, :state => @lex_state})
  end

  def on_CHAR(tok, data)
    @lex_state = EXPR_END
    data.push({ :line_no => lineno, :char_no => column, :kind => __method__, :text => tok, :state => @lex_state})
  end

  def on_period(tok, data)
    @lex_state = EXPR_DOT
    data.push({ :line_no => lineno, :char_no => column, :kind => __method__, :text => tok, :state => @lex_state})
  end

  def on_int(tok, data)
    @lex_state = EXPR_END | EXPR_ENDARG
    data.push({ :line_no => lineno, :char_no => column, :kind => __method__, :text => tok, :state => @lex_state})
  end

  def on_symbeg(tok, data)
    @lex_state = EXPR_FNAME
    @continue = true
    data.push({ :line_no => lineno, :char_no => column, :kind => __method__, :text => tok, :state => @lex_state})
  end

  def on_ident(tok, data)
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
    data.push({ :line_no => lineno, :char_no => column, :kind => __method__, :text => tok, :state => @lex_state})
  end

  def on_lparen(tok, data)
    @lex_state = EXPR_LABEL | EXPR_BEG
    data.push({ :line_no => lineno, :char_no => column, :kind => __method__, :text => tok, :state => @lex_state})
  end

  def on_rparen(tok, data)
    @lex_state = EXPR_ENDFN
    data.push({ :line_no => lineno, :char_no => column, :kind => __method__, :text => tok, :state => @lex_state})
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
    data.push({ :line_no => lineno, :char_no => column, :kind => __method__, :text => tok, :state => @lex_state})
  end

  def on_sp(tok, data)
    data.push({ :line_no => lineno, :char_no => column, :kind => __method__, :text => tok, :state => @lex_state})
  end

  def on_default(event, tok, data)
    reset
    data.push({ :line_no => lineno, :char_no => column, :kind => event, :text => tok, :state => @lex_state})
  end

  def self.parse(code)
    self.new(code).parse([])
  end
end
