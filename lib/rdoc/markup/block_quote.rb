##
# A quoted section of text

class RDoc::Markup::BlockQuote < RDoc::Markup::Raw

  ##
  # Calls #accept_block_quote on +visitor+

  def accept visitor
    visitor.accept_block_quote self
  end

end

