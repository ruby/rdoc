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
  # Look for a 'call-seq' in the comment, and override the normal parameter
  # stuff
  #--
  # TODO handle undent

  def extract_call_seq method
    if @text.sub!(/:?call-seq:(.*?)(^\s*#?\s*$|\z)/m, '') then
      seq = $1
      seq.gsub!(/^\s*\#\s*/, '')
      method.call_seq = seq
    end

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

