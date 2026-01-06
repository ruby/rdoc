# frozen_string_literal: true

require 'set'

# Parses inline markup in RDoc text.
# THis parser handles em, bold, strike, tt, hard break, and tidylink.
# Block-level constructs are handled in RDoc::Markup::Parser.

class RDoc::Markup::InlineParser

  # TT, BOLD_WORD, EM_WORD: regexp-handling(example: crossref) is disabled
  WORD_PAIRS = {
    '*' => :BOLD_WORD,
    '**' => :BOLD_WORD,
    '_' => :EM_WORD,
    '__' => :EM_WORD,
    '+' => :TT,
    '++' => :TT,
    '`' => :TT,
    '``' => :TT
  } # :nodoc:

  # Other types: regexp-handling(example: crossref) is enabled
  TAGS = {
    'em' => :EM,
    'i' => :EM,
    'b' => :BOLD,
    's' => :STRIKE,
    'del' => :STRIKE,
  } # :nodoc:

  STANDALONE_TAGS = { 'br' => :HARD_BREAK } # :nodoc:

  TOKENS = {
    **WORD_PAIRS.transform_values { [:word_pair, nil] },
    **TAGS.keys.to_h {|tag| ["<#{tag}>", [:open_tag, tag]] },
    **TAGS.keys.to_h {|tag| ["</#{tag}>", [:close_tag, tag]] },
    **%w[tt code].to_h {|tag| ["<#{tag}>", [:code_start, tag]] },
    **STANDALONE_TAGS.keys.to_h {|tag| ["<#{tag}>", [:standalone_tag, tag]] },
    '{' => [:tidylink_start, nil],
    '}' => [:tidylink_mid, nil],
    '\\' => [:escape, nil],
    '[' => nil # To make `label[url]` scan as separate tokens
  } # :nodoc:

  multi_char_tokens_regexp = Regexp.union(TOKENS.keys.select {|s| s.size > 1 }).source
  token_starts_regexp = TOKENS.keys.map {|s| s[0] }.uniq.map {|s| Regexp.escape(s) }.join

  SCANNER_REGEXP =
    /\G(?:
      #{multi_char_tokens_regexp}
      |[^#{token_starts_regexp}\sa-zA-Z0-9\.]+ # chunk of normal text
      |\s+|[a-zA-Z0-9\.]+|.
    )/x # :nodoc:

  def initialize(string)
    @string = string
    @pos = 0
    @scan_failure_cache = Set.new
    @stack = []
    @current = nil
    @delimiters = {}
  end

  # Parse and return an array of nodes.
  # Node format:
  #   {
  #     type: :EM | :BOLD | :BOLD_WORD | :EM_WORD | :TT | :STRIKE | :HARD_BREAK | :TIDYLINK,
  #     url: string # only for :TIDYLINK
  #     children: [string_or_node, ...]
  #   }

  def parse
    stack_push(:root, nil)
    while true
      type, token, value = scan_token
      close = nil
      tidylink_url = nil
      case type
      when :node
        @current[:children] << value
        invalidate_open_tidylinks if value[:type] == :TIDYLINK
      when :eof
        close = :root
      when :tidylink_open
        stack_push(:tidylink, token)
      when :tidylink_close
        close = :tidylink
        if value
          tidylink_url = value
        else
          # Tidylink closing brace without URL part. Treat opening and closing braces as normal text
          # `{labelnodes}...` case.
          @current[:children] << token
        end
      when :invalidated_tidylink_close
        # `{...{label}[url]...}` case. Nested tidylink invalidates outer one. The last `}` closes the invalidated tidylink.
        @current[:children] << token
        close = :invalidated_tidylink
      when :text
        @current[:children] << token
      when :open
        stack_push(value, token)
      when :close
        if @delimiters[value]
          close = value
        else
          # closing tag without matching opening tag. Treat as normal text.
          @current[:children] << token
        end
      end

      next unless close

      while @current[:delimiter] != close
        children = @current[:children]
        open_token = @current[:token]
        stack_pop
        @current[:children] << open_token if open_token
        @current[:children].concat(children)
      end

      token = @current[:token]
      children = compact_string(@current[:children])
      stack_pop

      return children if close == :root

      if close == :tidylink || close == :invalidated_tidylink
        if tidylink_url
          @current[:children] << { type: :TIDYLINK, children: children, url: tidylink_url }
          invalidate_open_tidylinks
        else
          @current[:children] << token
          @current[:children].concat(children)
        end
      else
        @current[:children] << { type: TAGS[close], children: children }
      end
    end
  end

  private

  # When a valid tidylink node is encountered, invalidate all nested tidylinks.

  def invalidate_open_tidylinks
    return unless @delimiters[:tidylink]

    @delimiters[:invalidated_tidylink] ||= []
    @delimiters[:tidylink].each do |idx|
      @delimiters[:invalidated_tidylink] << idx
      @stack[idx][:delimiter] = :invalidated_tidylink
    end
    @delimiters.delete(:tidylink)
  end

  # Pop the top node off the stack when node is closed by a closing delimiter or an error.

  def stack_pop
    delimiter = @current[:delimiter]
    @delimiters[delimiter].pop
    @delimiters.delete(delimiter) if @delimiters[delimiter].empty?
    @stack.pop
    @current = @stack.last
  end

  # Push a new node onto the stack when encountering an opening delimiter.

  def stack_push(delimiter, token)
    @current = { delimiter: delimiter, token: token, children: [] }
    (@delimiters[delimiter] ||= []) << @stack.size
    @stack << @current
  end

  # Compacts adjacent strings in +nodes+ into a single string.

  def compact_string(nodes)
    nodes.chunk {|e| String === e }.flat_map do |is_str, elems|
      is_str ? elems.join : elems
    end
  end

  # Scan from the current position with a regexp that starts with \G.

  def scan_string(pattern)
    if (res = @string.match(pattern, @pos))
      @pos = res.end(0)
      res[0]
    end
  end

  # Read +len+ characters from the current position.

  def read(len)
    s = @string[@pos, len]
    @pos += len if s
    s
  end

  # Match +pattern+ from the current position.
  # Returns nil if not found, and caches the failure.
  # Be careful to use a pair of pattern and position that is cache-safe.

  def failure_cached_match(pattern)
    # Cache notfound information to avoid O(N^2) search of missing closing tags
    return if @scan_failure_cache.include?(pattern)

    match = @string.match(pattern, @pos)
    @scan_failure_cache << pattern unless match
    match
  end

  # Scan and return the next token for parsing.
  # Returns <tt>[token_type, token_string_or_nil, extra_info]</tt>

  def scan_token
    token = scan_string(SCANNER_REGEXP)
    type, name = TOKENS[token]
    case type
    when :word_pair
      pair = read_word_pair(token)
      pair ? [:node, nil, { type: WORD_PAIRS[token], children: [pair]}] : [:text, token]
    when :open_tag
      [:open, token, name]
    when :close_tag
      [:close, token, name]
    when :code_start
      if name == 'tt'
        close_pattern = /\G((?:\\.|[^\\])*?)<\/tt>/
      else
        close_pattern = /\G((?:\\.|[^\\])*?)<\/code>/
      end
      if (match = failure_cached_match(close_pattern))
        @pos = match.end(0)
        # Need to unescape `\\` and `\<`.
        # RDoc also unescapes backslash + word separators, but this is not really necessary.
        content = match[1].gsub(/\\(.)/) { '\\<*+_`'.include?($1) ? $1 : $& }
        [:node, nil, { type: :TT, children: content.empty? ? [] : [content] }]
      else
        [:text, token, nil]
      end
    when :standalone_tag
      [:node, nil, { type: STANDALONE_TAGS[name], children: [] }]
    when :tidylink_start
      [:tidylink_open, token, nil]
    when :tidylink_mid
      if @delimiters[:tidylink]
        if (url = read_tidylink_url)
          [:tidylink_close, nil, url]
        else
          [:tidylink_close, token, nil]
        end
      elsif @delimiters[:invalidated_tidylink]
        [:invalidated_tidylink_close, token, nil]
      else
        [:text, token, nil]
      end
    when :escape
      crossref = scan_string(/\G[a-zA-Z#][a-zA-Z\d_.:#]*[!?=]?/)
      # Escaped crossref: keep backslash
      # Other escaped characters: remove backslash
      [:text, crossref ? "\\#{crossref}" : read(1) || '\\', nil]
    else
      if token.nil?
        [:eof, nil, nil]
      elsif token.match?(/\A[A-Za-z0-9]*\z/) && (url = read_tidylink_url)
        # Simplified tidylink: label[url]
        [:node, nil, { type: :TIDYLINK, children: [token], url: url }]
      else
        [:text, token, nil]
      end
    end
  end

  # Read the URL part of a tidylink from the current position.
  # Returns nil if no valid URL part is found.
  # URL part is enclosed in square brackets and may contain escaped brackets.
  # Example: <tt>[http://example.com/?q=\[\]]</tt> represents <tt>http://example.com/?q=[]</tt>.

  def read_tidylink_url
    bracketed_url = scan_string(/\G\[([^\s\[\]\\]|\\[\[\]\\])+\]/)
    bracketed_url[1...-1].gsub(/\\(.)/, '\1') if bracketed_url
  end

  # Word contains alphanumeric and <tt>_./:[]-</tt> characters.
  # Word may start with <tt>#</tt> and may end with any non-space character. (e.g. <tt>#eql?</tt>).
  # Underscore delimiter have special rules.

  WORD_REGEXPS = {
    # Words including _, longest match.
    # Example: `_::A_` `_-42_` `_A::B::C.foo_bar[baz]_` `_kwarg:_`
    # Content must not include _ followed by non-alphanumeric character
    # Example: `_host_:_port_` will be `_host_` + `:` + `_port_`
    '_' => /\G#?([a-zA-Z0-9.\/:\[\]-]|_+[a-zA-Z0-9])+[^\s]?(?=_[^a-zA-Z0-9_]|_\z)/,
    # Words allowing _ but not allowing __
    '__' => /\G#?[a-zA-Z0-9.\/:\[\]-]*(_[a-zA-Z0-9.\/:\[\]-]+)*[^\s]?(?=__)/,
    **%w[* ** + ++ ` ``].to_h do |s|
      # normal words that can be used within +word+ or *word*
      [s, /\G#?[a-zA-Z0-9_.\/:\[\]-]+[^\s]?(?=#{Regexp.escape(s)})/]
    end
  } # :nodoc:

  # Read a word surrounded by +delimiter+ from the current position.

  def read_word_pair(delimiter)
    invalid_adjascent_char_pattern = /[a-zA-Z0-9]/
    return if @pos != delimiter.size && invalid_adjascent_char_pattern.match?(@string[@pos - delimiter.size - 1])
    return unless (m = @string.match(WORD_REGEXPS[delimiter], @pos))

    word = m[0]
    # Special exception: __FILE__, __LINE__, __send__ should not be treated as emphasis
    return if delimiter == '__' && word.match?(/\A[a-zA-Z]+\z/)

    pos = m.end(0)
    unless invalid_adjascent_char_pattern.match?(@string[pos + delimiter.size])
      @pos = pos + delimiter.size
      word
    end
  end
end
