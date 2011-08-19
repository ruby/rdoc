##
# Parse a RD format file.  The parsed RDoc::Markup::Document is attached as a
# file comment.

class RDoc::Parser::RD < RDoc::Parser

  include RDoc::Parser::Text

  parse_files_matching(/\.rd(?:\.[^.]+)?$/)

  def scan
    document = RDoc::RD.parse @content

    @top_level.comment = document
  end

end

