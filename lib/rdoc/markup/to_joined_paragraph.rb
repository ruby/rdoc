##
# Joins the parts of an RDoc::Markup::Paragraph into a single String.
#
# This allows for easier testing of Markdown support as Paragraphs are split
# up piecemeal to allow later replacing.

class RDoc::Markup::ToJoinedParagraph < RDoc::Markup::Formatter

  def start_accepting
  end

  def end_accepting
  end

  def accept_paragraph paragraph
    paragraph.parts.replace [paragraph.parts.join]
  end

  alias accept_block_quote     ignore
  alias accept_heading         ignore
  alias accept_list_end        ignore
  alias accept_list_item_end   ignore
  alias accept_list_item_start ignore
  alias accept_list_start      ignore
  alias accept_raw             ignore
  alias accept_rule            ignore
  alias accept_verbatim        ignore

end

