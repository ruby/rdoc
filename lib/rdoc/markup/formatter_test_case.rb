require 'minitest/unit'
require 'rdoc/markup/formatter'

class RDoc::Markup::FormatterTestCase < MiniTest::Unit::TestCase

  def setup
    super

    @m = RDoc::Markup.new
    @am = RDoc::Markup::AttributeManager.new
    @RMP = RDoc::Markup::Parser
  end

  def self.add_visitor_tests
    self.class_eval do
      def test_start_accepting
        @to.start_accepting

        start_accepting
      end

      def test_end_accepting
        @to.start_accepting
        @to.res << 'hi'

        end_accepting
      end

      def test_accept_blank_line
        @to.start_accepting

        @to.accept_blank_line @am, @RMP::BlankLine.new

        accept_blank_line
      end

      def test_accept_heading
        @to.start_accepting

        @to.accept_heading @am, @RMP::Heading.new(5, 'Hello')

        accept_heading
      end

      def test_accept_paragraph
        @to.start_accepting

        @to.accept_paragraph @am, @RMP::Paragraph.new('hi')

        accept_paragraph
      end

      def test_accept_verbatim
        @to.start_accepting

        @to.accept_verbatim @am, @RMP::Verbatim.new('  ', 'hi', "\n",
                                                    '  ', 'world', "\n")

        accept_verbatim
      end

      def test_accept_rule
        @to.start_accepting

        @to.accept_rule @am, @RMP::Rule.new(4)

        accept_rule
      end

      def test_accept_list_item_start_bullet
        @to.start_accepting

        @to.accept_list_start @am, @RMP::List.new('*')

        @to.accept_list_item_start @am, @RMP::ListItem.new(nil)

        accept_list_item_start_bullet
      end

      def test_accept_list_item_start_label
        @to.start_accepting

        @to.accept_list_start @am, @RMP::List.new('label')

        @to.accept_list_item_start @am, @RMP::ListItem.new('cat')

        accept_list_item_start_label
      end

      def test_accept_list_item_start_lalpha
        @to.start_accepting

        @to.accept_list_start @am, @RMP::List.new('a')

        @to.accept_list_item_start @am, @RMP::ListItem.new(nil)

        accept_list_item_start_lalpha
      end

      def test_accept_list_item_start_note
        @to.start_accepting

        @to.accept_list_start @am, @RMP::List.new('note')

        @to.accept_list_item_start @am, @RMP::ListItem.new('cat')

        accept_list_item_start_note
      end

      def test_accept_list_item_start_number
        @to.start_accepting

        @to.accept_list_start @am, @RMP::List.new('1')

        @to.accept_list_item_start @am, @RMP::ListItem.new(nil)

        accept_list_item_start_number
      end

      def test_accept_list_item_start_ualpha
        @to.start_accepting

        @to.accept_list_start @am, @RMP::List.new('A')

        @to.accept_list_item_start @am, @RMP::ListItem.new(nil)

        accept_list_item_start_ualpha
      end

      def test_accept_list_item_end_bullet
        @to.start_accepting

        @to.accept_list_start @am, @RMP::List.new('*')

        @to.accept_list_item_end @am, @RMP::ListItem.new(nil)

        accept_list_item_end_bullet
      end

      def test_accept_list_item_end_label
        @to.start_accepting

        @to.accept_list_start @am, @RMP::List.new('label')

        @to.accept_list_item_end @am, @RMP::ListItem.new('cat')

        accept_list_item_end_label
      end

      def test_accept_list_item_end_lalpha
        @to.start_accepting

        @to.accept_list_start @am, @RMP::List.new('a')

        @to.accept_list_item_end @am, @RMP::ListItem.new(nil)

        accept_list_item_end_lalpha
      end

      def test_accept_list_item_end_note
        @to.start_accepting

        @to.accept_list_start @am, @RMP::List.new('note')

        @to.accept_list_item_end @am, @RMP::ListItem.new('cat')

        accept_list_item_end_note
      end

      def test_accept_list_item_end_number
        @to.start_accepting

        @to.accept_list_start @am, @RMP::List.new('1')

        @to.accept_list_item_end @am, @RMP::ListItem.new(nil)

        accept_list_item_end_number
      end

      def test_accept_list_item_end_ualpha
        @to.start_accepting

        @to.accept_list_start @am, @RMP::List.new('A')

        @to.accept_list_item_end @am, @RMP::ListItem.new(nil)

        accept_list_item_end_ualpha
      end

      def test_accept_list_start_bullet
        @to.start_accepting

        @to.accept_list_start @am, @RMP::List.new('*')

        accept_list_start_bullet
      end

      def test_accept_list_start_label
        @to.start_accepting

        @to.accept_list_start @am, @RMP::List.new('label')

        accept_list_start_label
      end

      def test_accept_list_start_lalpha
        @to.start_accepting

        @to.accept_list_start @am, @RMP::List.new('a')

        accept_list_start_lalpha
      end

      def test_accept_list_start_note
        @to.start_accepting

        @to.accept_list_start @am, @RMP::List.new('note')

        accept_list_start_note
      end

      def test_accept_list_start_number
        @to.start_accepting

        @to.accept_list_start @am, @RMP::List.new('1')

        accept_list_start_number
      end

      def test_accept_list_start_ualpha
        @to.start_accepting

        @to.accept_list_start @am, @RMP::List.new('A')

        accept_list_start_ualpha
      end

      def test_accept_list_end_bullet
        @to.start_accepting

        @to.accept_list_end @am, @RMP::List.new('*')

        accept_list_end_bullet
      end

      def test_accept_list_end_label
        @to.start_accepting

        @to.accept_list_end @am, @RMP::List.new('label')

        accept_list_end_label
      end

      def test_accept_list_end_lalpha
        @to.start_accepting

        @to.accept_list_end @am, @RMP::List.new('a')

        accept_list_end_lalpha
      end

      def test_accept_list_end_number
        @to.start_accepting

        @to.accept_list_end @am, @RMP::List.new('1')

        accept_list_end_number
      end

      def test_accept_list_end_note
        @to.start_accepting

        @to.accept_list_end @am, @RMP::List.new('note')

        accept_list_end_note
      end

      def test_accept_list_end_ualpha
        @to.start_accepting

        @to.accept_list_end @am, @RMP::List.new('A')

        accept_list_end_ualpha
      end
    end
  end

end

