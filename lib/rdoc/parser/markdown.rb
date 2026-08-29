# frozen_string_literal: true
module RDoc
  class Parser
    ##
    # Parse a Markdown format file.  The parsed RDoc::Markup::Document is attached
    # as a file comment.

    class Markdown < Parser

      include Parser::Text

      parse_files_matching(/\.(md|markdown)(?:\.[^.]+)?$/)

      ##
      # Creates an Markdown-format TopLevel for the given file.

      def scan
        comment = Comment.new @content, @top_level
        comment.format = 'markdown'

        @top_level.comment = comment
      end

    end
  end
end
