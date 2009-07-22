##
# Definitions of all tokens involved in the lexical analysis

module RDoc::RubyToken

  EXPR_BEG   = :EXPR_BEG
  EXPR_MID   = :EXPR_MID
  EXPR_END   = :EXPR_END
  EXPR_ARG   = :EXPR_ARG
  EXPR_FNAME = :EXPR_FNAME
  EXPR_DOT   = :EXPR_DOT
  EXPR_CLASS = :EXPR_CLASS

  class Token
    NO_TEXT = "??".freeze

    attr_accessor :text
    attr_reader :line_no
    attr_reader :char_no

    def initialize(line_no, char_no)
      @line_no = line_no
      @char_no = char_no
      @text    = NO_TEXT
    end

    def ==(other)
      self.class == other.class and
        other.line_no == @line_no and
        other.char_no == @char_no and
        other.text == @text
    end

    ##
    # Because we're used in contexts that expect to return a token, we set the
    # text string and then return ourselves

    def set_text(text)
      @text = text
      self
    end

  end

  class TkNode < Token
    attr :node
  end

  class TkId < Token
    def initialize(line_no, char_no, name)
      super(line_no, char_no)
      @name = name
    end
    attr :name
  end

  class TkKW < TkId
  end

  class TkVal < Token
    def initialize(line_no, char_no, value = nil)
      super(line_no, char_no)
      set_text(value)
    end
  end

  class TkOp < Token
    def name
      self.class.op_name
    end
  end

  class TkOPASGN < TkOp
    def initialize(line_no, char_no, op)
      super(line_no, char_no)
      op = TkReading2Token[op] unless Symbol === op
      @op = op
    end
    attr :op
  end

  class TkUnknownChar < Token
    def initialize(line_no, char_no, id)
      super(line_no, char_no)
      @name = char_no.chr
    end
    attr :name
  end

  class TkError < Token
  end

  def set_token_position(line, char)
    @prev_line_no = line
    @prev_char_no = char
  end

  def Token(token, value = nil)
    tk = nil
    case token
    when String, Symbol
      source = String === token ? TkReading2Token : TkSymbol2Token
      raise TkReading2TokenNoKey, token if (tk = source[token]).nil?
      tk = Token(tk[0], value)
    else
      tk = if (token.ancestors & [TkId, TkVal, TkOPASGN, TkUnknownChar]).empty?
             token.new(@prev_line_no, @prev_char_no)
           else
             token.new(@prev_line_no, @prev_char_no, value)
           end
    end
    tk
  end

  TokenDefinitions = [
    [:TkCLASS,      TkKW,  "class",  EXPR_CLASS],
    [:TkMODULE,     TkKW,  "module", EXPR_CLASS],
    [:TkDEF,        TkKW,  "def",    EXPR_FNAME],
    [:TkUNDEF,      TkKW,  "undef",  EXPR_FNAME],
    [:TkBEGIN,      TkKW,  "begin",  EXPR_BEG],
    [:TkRESCUE,     TkKW,  "rescue", EXPR_MID],
    [:TkENSURE,     TkKW,  "ensure", EXPR_BEG],
    [:TkEND,        TkKW,  "end",    EXPR_END],
    [:TkIF,         TkKW,  "if",     EXPR_BEG, :TkIF_MOD],
    [:TkUNLESS,     TkKW,  "unless", EXPR_BEG, :TkUNLESS_MOD],
    [:TkTHEN,       TkKW,  "then",   EXPR_BEG],
    [:TkELSIF,      TkKW,  "elsif",  EXPR_BEG],
    [:TkELSE,       TkKW,  "else",   EXPR_BEG],
    [:TkCASE,       TkKW,  "case",   EXPR_BEG],
    [:TkWHEN,       TkKW,  "when",   EXPR_BEG],
    [:TkWHILE,      TkKW,  "while",  EXPR_BEG, :TkWHILE_MOD],
    [:TkUNTIL,      TkKW,  "until",  EXPR_BEG, :TkUNTIL_MOD],
    [:TkFOR,        TkKW,  "for",    EXPR_BEG],
    [:TkBREAK,      TkKW,  "break",  EXPR_END],
    [:TkNEXT,       TkKW,  "next",   EXPR_END],
    [:TkREDO,       TkKW,  "redo",   EXPR_END],
    [:TkRETRY,      TkKW,  "retry",  EXPR_END],
    [:TkIN,         TkKW,  "in",     EXPR_BEG],
    [:TkDO,         TkKW,  "do",     EXPR_BEG],
    [:TkRETURN,     TkKW,  "return", EXPR_MID],
    [:TkYIELD,      TkKW,  "yield",  EXPR_END],
    [:TkSUPER,      TkKW,  "super",  EXPR_END],
    [:TkSELF,       TkKW,  "self",   EXPR_END],
    [:TkNIL,        TkKW,  "nil",    EXPR_END],
    [:TkTRUE,       TkKW,  "true",   EXPR_END],
    [:TkFALSE,      TkKW,  "false",  EXPR_END],
    [:TkAND,        TkKW,  "and",    EXPR_BEG],
    [:TkOR,         TkKW,  "or",     EXPR_BEG],
    [:TkNOT,        TkKW,  "not",    EXPR_BEG],
    [:TkIF_MOD,     TkKW],
    [:TkUNLESS_MOD, TkKW],
    [:TkWHILE_MOD,  TkKW],
    [:TkUNTIL_MOD,  TkKW],
    [:TkALIAS,      TkKW,  "alias",    EXPR_FNAME],
    [:TkDEFINED,    TkKW,  "defined?", EXPR_END],
    [:TklBEGIN,     TkKW,  "BEGIN",    EXPR_END],
    [:TklEND,       TkKW,  "END",      EXPR_END],
    [:Tk__LINE__,   TkKW,  "__LINE__", EXPR_END],
    [:Tk__FILE__,   TkKW,  "__FILE__", EXPR_END],

    [:TkIDENTIFIER, TkId],
    [:TkFID,        TkId],
    [:TkGVAR,       TkId],
    [:TkIVAR,       TkId],
    [:TkCONSTANT,   TkId],

    [:TkINTEGER,    TkVal],
    [:TkFLOAT,      TkVal],
    [:TkSTRING,     TkVal],
    [:TkXSTRING,    TkVal],
    [:TkREGEXP,     TkVal],
    [:TkCOMMENT,    TkVal],

    [:TkDSTRING,    TkNode],
    [:TkDXSTRING,   TkNode],
    [:TkDREGEXP,    TkNode],
    [:TkNTH_REF,    TkId],
    [:TkBACK_REF,   TkId],

    [:TkUPLUS,      TkOp,   "+@"],
    [:TkUMINUS,     TkOp,   "-@"],
    [:TkPOW,        TkOp,   "**"],
    [:TkCMP,        TkOp,   "<=>"],
    [:TkEQ,         TkOp,   "=="],
    [:TkEQQ,        TkOp,   "==="],
    [:TkNEQ,        TkOp,   "!="],
    [:TkGEQ,        TkOp,   ">="],
    [:TkLEQ,        TkOp,   "<="],
    [:TkANDOP,      TkOp,   "&&"],
    [:TkOROP,       TkOp,   "||"],
    [:TkMATCH,      TkOp,   "=~"],
    [:TkNMATCH,     TkOp,   "!~"],
    [:TkDOT2,       TkOp,   ".."],
    [:TkDOT3,       TkOp,   "..."],
    [:TkAREF,       TkOp,   "[]"],
    [:TkASET,       TkOp,   "[]="],
    [:TkLSHFT,      TkOp,   "<<"],
    [:TkRSHFT,      TkOp,   ">>"],
    [:TkCOLON2,     TkOp],
    [:TkCOLON3,     TkOp],
#   [:OPASGN,       TkOp],               # +=, -=  etc. #
    [:TkASSOC,      TkOp,   "=>"],
    [:TkQUESTION,   TkOp,   "?"],        #?
    [:TkCOLON,      TkOp,   ":"],        #:

    [:TkfLPAREN],         # func( #
    [:TkfLBRACK],         # func[ #
    [:TkfLBRACE],         # func{ #
    [:TkSTAR],            # *arg
    [:TkAMPER],           # &arg #
    [:TkSYMBOL,     TkId],          # :SYMBOL
    [:TkSYMBEG,     TkId],
    [:TkGT,         TkOp,   ">"],
    [:TkLT,         TkOp,   "<"],
    [:TkPLUS,       TkOp,   "+"],
    [:TkMINUS,      TkOp,   "-"],
    [:TkMULT,       TkOp,   "*"],
    [:TkDIV,        TkOp,   "/"],
    [:TkMOD,        TkOp,   "%"],
    [:TkBITOR,      TkOp,   "|"],
    [:TkBITXOR,     TkOp,   "^"],
    [:TkBITAND,     TkOp,   "&"],
    [:TkBITNOT,     TkOp,   "~"],
    [:TkNOTOP,      TkOp,   "!"],

    [:TkBACKQUOTE,  TkOp,   "`"],

    [:TkASSIGN,     Token,  "="],
    [:TkDOT,        Token,  "."],
    [:TkLPAREN,     Token,  "("],  #(exp)
    [:TkLBRACK,     Token,  "["],  #[arry]
    [:TkLBRACE,     Token,  "{"],  #{hash}
    [:TkRPAREN,     Token,  ")"],
    [:TkRBRACK,     Token,  "]"],
    [:TkRBRACE,     Token,  "}"],
    [:TkCOMMA,      Token,  ","],
    [:TkSEMICOLON,  Token,  ";"],

    [:TkRD_COMMENT],
    [:TkSPACE],
    [:TkNL],
    [:TkEND_OF_SCRIPT],

    [:TkBACKSLASH,  TkUnknownChar,  "\\"],
    [:TkAT,         TkUnknownChar,  "@"],
    [:TkDOLLAR,     TkUnknownChar,  "\$"], #"
  ]

  # {reading => token_class}
  # {reading => [token_class, *opt]}
  TkReading2Token = {}
  TkSymbol2Token = {}

  def self.def_token(token_n, super_token = Token, reading = nil, *opts)
    token_n = token_n.id2name unless String === token_n

    fail AlreadyDefinedToken, token_n if const_defined?(token_n)

    token_c =  Class.new super_token
    const_set token_n, token_c
#    token_c.inspect

    if reading
      if TkReading2Token[reading]
        fail TkReading2TokenDuplicateError, token_n, reading
      end
      if opts.empty?
        TkReading2Token[reading] = [token_c]
      else
        TkReading2Token[reading] = [token_c].concat(opts)
      end
    end
    TkSymbol2Token[token_n.intern] = token_c

    if token_c <= TkOp
      token_c.class_eval %{
        def self.op_name; "#{reading}"; end
      }
    end
  end

  for defs in TokenDefinitions
    def_token(*defs)
  end

  NEWLINE_TOKEN = TkNL.new(0,0)
  NEWLINE_TOKEN.set_text("\n")

  class TkSYMBOL

    def to_sym
      @sym ||= text[1..-1].intern
    end

  end

end

