class RDoc::Comment

  include RDoc::Text

  attr_accessor :location
  attr_accessor :text

  def initialize text = nil, location = nil
    @location = location
    @text     = text
  end

  def initialize_copy copy
    @text = copy.text.dup
  end

  def == other # :nodoc:
    self.class === other and
      other.text == @text and other.location == @location
  end

  ##
  # Look for a 'call-seq' in the comment to override the normal parameter
  # handling.  The call-seq is indented from the baseline.  All lines of the
  # same indentation level and prefix are consumed.
  #
  # For example, all of the following will be used as the call-seq:
  #
  #   call-seq:
  #     ARGF.readlines(sep=$/)     -> array
  #     ARGF.readlines(limit)      -> array
  #     ARGF.readlines(sep, limit) -> array
  #
  #     ARGF.to_a(sep=$/)     -> array
  #     ARGF.to_a(limit)      -> array
  #     ARGF.to_a(sep, limit) -> array

  def extract_call_seq method
    # we must handle situations like the above followed by an unindented first
    # comment.  The difficulty is to make sure not to match lines starting
    # with ARGF at the same indent, but that are after the first description
    # paragraph.
    if @text =~ /call-seq:(.*?(?:\S).*?)^\s*$/m then
      all_start, all_stop = $~.offset(0)
      seq_start, seq_stop = $~.offset(1)

      # we get the following lines that start with the leading word at the
      # same indent, even if they have blank lines before
      if $1 =~ /(^\s*\n)+^(\s*\w+)/m then
        leading = $2 # ' *    ARGF' in the example above
        re = %r%
          \A(
             (^\s*\n)+
             (^#{Regexp.escape leading}.*?\n)+
            )+
          ^\s*$
        %xm

        if @text[seq_stop..-1] =~ re then
          all_stop = seq_stop + $~.offset(0).last
          seq_stop = seq_stop + $~.offset(1).last
        end
      end

      seq = @text[seq_start..seq_stop]
      seq.gsub!(/^\s*(\S|\n)/m, '\1')
      @text.slice! all_start...all_stop

      method.call_seq = seq.chomp

    elsif @text.sub!(/:?call-seq:(.*?)(^\s*$|\z)/m, '') then
      seq = $1
      seq.gsub!(/^\s*/, '')
      method.call_seq = seq
    end
    #elsif @text.sub!(/\A\/\*\s*call-seq:(.*?)\*\/\Z/, '') then
    #  method.call_seq = $1.strip
    #end

    method
  end

  def empty?
    @text.empty?
  end

  ##
  # HACK dubious

  def force_encoding encoding
    @text.force_encoding encoding
  end

  def normalize
    @text = normalize_comment @text

    self
  end

  def remove_private
    # Workaround for gsub encoding for Ruby 1.9.2 and earlier
    empty = ''
    empty.force_encoding @text.encoding if Object.const_defined? :Encoding

    @text = @text.gsub(/^#--.*?^#\+\+\n?/m, empty)
    @text = @text.sub(/^#--.*/m, '')
  end

end

