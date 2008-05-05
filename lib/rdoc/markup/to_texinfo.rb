require 'rdoc/markup/formatter'
require 'rdoc/markup/fragments'
require 'rdoc/markup/inline'

require 'rdoc/markup'
require 'rdoc/markup/formatter'

##
# Convert SimpleMarkup to basic TexInfo format

class RDoc::Markup::ToTexInfo < RDoc::Markup::Formatter

  def start_accepting
    @text = []
  end

  def end_accepting
    @text.join("\n")
  end

  def accept_paragraph(attributes, text)
    @text << format(text.txt) + "\n"
  end

  def accept_verbatim(attributes, text)
    @text << "@verb{|#{format(text.txt)}|}"
  end

  def accept_list_start(attributes, text)
  end

  def accept_list_end(attributes, text)
  end

  def accept_list_item(attributes, text)
  end

  def accept_blank_line(attributes, text)
    @text << "\n"
  end

  def accept_heading(attributes, text)
  end

  def accept_rule(attributes, text)
    @text << '---'
  end

  def format(text)
    text.
      gsub(/@/, "\\@").
      gsub(/\{/, "\\{").
      gsub(/\}/, "\\}").
      gsub(/\+([\w]+)\+/, "@code{\\1}").
      gsub(/\<tt\>([^<]+)\<\/tt\>/, "@code{\\1}").
      gsub(/\*([\w]+)\*/, "@strong{\\1}").
      gsub(/\<b\>([^<]+)\<\/b\>/, "@strong{\\1}").
      gsub(/_([\w]+)_/, "@emph{\\1}").
      gsub(/\<em\>([^<]+)\<\/em\>/, "@emph{\\1}")
  end
end
