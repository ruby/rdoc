##
# Methods for manipulating comment text

module RDoc::Text

  ##
  # Expands tab characters in +text+ to eight spaces

  def expand_tabs text
    expanded = []

    text.each_line do |line|
      line.gsub!(/^(.{8}*?)([^\t\r\n]{0,7})\t/) do
        "#{$1}#{$2}#{' ' * (8 - $2.size)}"
      end until line !~ /\t/

      expanded << line
    end

    expanded.join
  end

  ##
  # Flush +text+ left based on the shortest line

  def flush_left text
    indents = []

    text.each_line do |line|
      indents << (line =~ /[^\s]/ || 9999)
    end

    indent = indents.min

    flush = []

    text.each_line do |line|
      line[/^ {0,#{indent}}/] = ''
      flush << line
    end

    flush.join
  end

  ##
  # Strips hashes, expands tabs then flushes +text+ to the left

  def normalize_comment text
    return if text.empty?

    text = strip_hashes text
    text = expand_tabs text
    flush_left text
  end

  ##
  # Normalizes +text+ then builds a RDoc::Markup::Parser::Document from it

  def parse text
    return text if RDoc::Markup::Parser::Document === text
    return if text.empty?

    text = normalize_comment text

    RDoc::Markup::Parser.parse text
  rescue RDoc::Markup::Parser::Error => e
    $stderr.puts <<-EOF
While parsing markup, RDoc encountered a #{e.class}:

#{e}
\tfrom #{e.backtrace.join "\n\tfrom "}

---8<---
#{text}
---8<---

RDoc #{RDoc::VERSION}

Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL} #{RUBY_RELEASE_DATE}

Please file a bug report with the above information at:

http://rubyforge.org/tracker/?atid=2472&group_id=627&func=browse

    EOF
    raise
  end

  ##
  # Strips leading # characters from +text+

  def strip_hashes text
    return text if text =~ /^(?>\s*)[^\#]/
    text.gsub(/^\s*(#+)/) { $1.tr '#',' ' }
  end

end

