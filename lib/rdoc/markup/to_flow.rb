require 'rdoc/markup/formatter'
require 'rdoc/markup/inline'
require 'cgi'

class RDoc::Markup

  module Flow

    ##
    # Paragraph

    P = Struct.new(:body)

    ##
    # Verbatim

    VERB = Struct.new(:body)

    ##
    # Horizontal rule

    RULE = Struct.new(:width)

    ##
    # List

    class LIST
      attr_reader :type, :contents

      def initialize type, *contents
        @type = type
        @contents = []
        @contents.push(*contents)
      end

      def == other
        other.class == self.class and
          other.type == @type and
          other.contents == @contents
      end

      def << stuff
        @contents << stuff
      end
    end

    ##
    # List item

    class LI
      attr_reader :label, :contents

      def initialize type, *contents
        @type = type
        @contents = []
        @contents.push(*contents)
      end

      def == other
        other.class == self.class and
          other.label == @label and
          other.contents == @contents
      end

      def << stuff
        @contents << stuff
      end

      def body
        raise 'no'
      end
    end

    ##
    # Heading

    H = Struct.new(:level, :text)

  end

  class ToFlow < RDoc::Markup::Formatter

    attr_reader :res
    attr_reader :list_stack

    def initialize
      super

      @res = nil
      @list_stack = nil

      init_tags
    end

    ##
    # :section: Visitor

    def start_accepting
      @res = []
      @list_stack = []
    end

    def end_accepting
      @res
    end

    def accept_paragraph(am, paragraph)
      @res << Flow::P.new((convert_flow(am.flow(paragraph.text))))
    end

    def accept_verbatim(am, verbatim)
      @res << Flow::VERB.new((convert_flow(am.flow(verbatim.text))))
    end

    def accept_rule(am, rule)
      size = [rule.weight, 10].min
      @res << Flow::RULE.new(size)
    end

    def accept_list_start(am, list)
      @list_stack.push(@res)
      flow_list = Flow::LIST.new(list.type)
      @res << flow_list
      @res = flow_list
    end

    def accept_list_end(am, list)
      @res = @list_stack.pop
    end

    def accept_list_item_start(am, list_item)
      @list_stack.push @res
      li = Flow::LI.new(list_item.label)
      @res << li
      @res = li
    end

    def accept_list_item_end(am, list_item)
      @res = @list_stack.pop
    end

    def accept_blank_line(am, blank_line)
    end

    def accept_heading(am, heading)
      @res << Flow::H.new(heading.level, convert_flow(am.flow(heading.text)))
    end

    private

    def convert_string(item)
      CGI.escapeHTML item
    end

  end

end

