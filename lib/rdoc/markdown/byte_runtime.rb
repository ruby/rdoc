# frozen_string_literal: true

require 'strscan'

class RDoc::Markdown

  ##
  # Byte-offset replacements for the position helpers of the kpeg-generated
  # parser runtime.
  #
  # The generated runtime addresses +@string+ by character index, which makes
  # every position lookup scan the string from its beginning when the input
  # contains non-ASCII characters, so parse time becomes quadratic in the
  # input size.  Generated rule bodies only save and restore +pos+ without
  # inspecting it, so replacing these helpers is enough to switch the whole
  # parser to byte offsets.
  #
  # get_byte (the grammar's `.`) consumes one character and returns its
  # codepoint, exactly like the character-index runtime, so positions always
  # stay on character boundaries and the only observable difference is the
  # position values themselves.  The input must be validly encoded in an
  # ASCII-compatible encoding.
  #
  # The error-reporting helpers of the generated runtime (+current_line+,
  # +current_column+, ...) are left as-is and would misreport locations when
  # given byte offsets.  They are unreachable: markdown is deliberately
  # designed to parse any input somehow rather than fail (the root rule
  # `Doc = BOM? Block*` cannot fail), so a parse failure means a bug in the
  # grammar itself, and nothing in RDoc invokes +raise_error+ or
  # +show_error+.  Make these helpers byte-aware before using them for
  # anything.

  module ByteRuntime
    def set_string(string, pos)
      @string = string
      @string_size = string ? string.bytesize : 0
      @pos = pos
      @position_line_offsets = nil
      @scanner = string ? StringScanner.new(string) : nil
    end

    def scan(reg)
      @scanner.pos = @pos
      if @scanner.skip(reg)
        @pos = @scanner.pos
        true
      end
    end

    def match_string(str)
      len = str.bytesize
      if @string.byteslice(@pos, len) == str
        @pos += len
        str
      end
    end

    def get_byte
      byte = @string.getbyte(@pos)
      return nil unless byte

      if byte < 0x80
        @pos += 1
        byte
      else
        @scanner.pos = @pos
        # /./ interprets the character in the string's own encoding
        char = @scanner.scan(/./m)
        @pos = @scanner.pos
        char.ord
      end
    end

    def get_text(start)
      @string.byteslice(start, @pos - start)
    end
  end
end
