require 'minitest/unit'
require 'rdoc/markup/formatter'

class RDoc::Markup::FormatterTestCase < MiniTest::Unit::TestCase

  def setup
    super

    @m = RDoc::Markup.new
    @am = RDoc::Markup::AttributeManager.new
    @RMP = RDoc::Markup::Parser

    @bullet_list = @RMP::List.new(:BULLET,
      @RMP::ListItem.new(nil, @RMP::Paragraph.new('l1')),
      @RMP::ListItem.new(nil, @RMP::Paragraph.new('l2')))

    @label_list = @RMP::List.new(:LABEL,
      @RMP::ListItem.new('cat', @RMP::Paragraph.new('cats are cool')),
      @RMP::ListItem.new('dog', @RMP::Paragraph.new('dogs are cool too')))

    @lalpha_list = @RMP::List.new(:LALPHA,
      @RMP::ListItem.new(nil, @RMP::Paragraph.new('l1')),
      @RMP::ListItem.new(nil, @RMP::Paragraph.new('l2')))

    @note_list = @RMP::List.new(:NOTE,
      @RMP::ListItem.new('cat', @RMP::Paragraph.new('cats are cool')),
      @RMP::ListItem.new('dog', @RMP::Paragraph.new('dogs are cool too')))

    @number_list = @RMP::List.new(:NUMBER,
      @RMP::ListItem.new(nil, @RMP::Paragraph.new('l1')),
      @RMP::ListItem.new(nil, @RMP::Paragraph.new('l2')))

    @ualpha_list = @RMP::List.new(:UALPHA,
      @RMP::ListItem.new(nil, @RMP::Paragraph.new('l1')),
      @RMP::ListItem.new(nil, @RMP::Paragraph.new('l2')))
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

        @to.accept_list_start @am, @bullet_list

        @to.accept_list_item_start @am, @bullet_list.items.first

        accept_list_item_start_bullet
      end

      def test_accept_list_item_start_label
        @to.start_accepting

        @to.accept_list_start @am, @label_list

        @to.accept_list_item_start @am, @label_list.items.first

        accept_list_item_start_label
      end

      def test_accept_list_item_start_lalpha
        @to.start_accepting

        @to.accept_list_start @am, @lalpha_list

        @to.accept_list_item_start @am, @lalpha_list.items.first

        accept_list_item_start_lalpha
      end

      def test_accept_list_item_start_note
        @to.start_accepting

        @to.accept_list_start @am, @note_list

        @to.accept_list_item_start @am, @note_list.items.first

        accept_list_item_start_note
      end

      def test_accept_list_item_start_number
        @to.start_accepting

        @to.accept_list_start @am, @number_list

        @to.accept_list_item_start @am, @number_list.items.first

        accept_list_item_start_number
      end

      def test_accept_list_item_start_ualpha
        @to.start_accepting

        @to.accept_list_start @am, @ualpha_list

        @to.accept_list_item_start @am, @ualpha_list.items.first

        accept_list_item_start_ualpha
      end

      def test_accept_list_item_end_bullet
        @to.start_accepting

        @to.accept_list_start @am, @bullet_list

        @to.accept_list_item_start @am, @bullet_list.items.first

        @to.accept_list_item_end @am, @bullet_list.items.first

        accept_list_item_end_bullet
      end

      def test_accept_list_item_end_label
        @to.start_accepting

        @to.accept_list_start @am, @label_list

        @to.accept_list_item_start @am, @label_list.items.first

        @to.accept_list_item_end @am, @label_list.items.first

        accept_list_item_end_label
      end

      def test_accept_list_item_end_lalpha
        @to.start_accepting

        @to.accept_list_start @am, @lalpha_list

        @to.accept_list_item_start @am, @lalpha_list.items.first

        @to.accept_list_item_end @am, @lalpha_list.items.first

        accept_list_item_end_lalpha
      end

      def test_accept_list_item_end_note
        @to.start_accepting

        @to.accept_list_start @am, @note_list

        @to.accept_list_item_start @am, @note_list.items.first

        @to.accept_list_item_end @am, @note_list.items.first

        accept_list_item_end_note
      end

      def test_accept_list_item_end_number
        @to.start_accepting

        @to.accept_list_start @am, @number_list

        @to.accept_list_item_start @am, @number_list.items.first

        @to.accept_list_item_end @am, @number_list.items.first

        accept_list_item_end_number
      end

      def test_accept_list_item_end_ualpha
        @to.start_accepting

        @to.accept_list_start @am, @ualpha_list

        @to.accept_list_item_start @am, @ualpha_list.items.first

        @to.accept_list_item_end @am, @ualpha_list.items.first

        accept_list_item_end_ualpha
      end

      def test_accept_list_start_bullet
        @to.start_accepting

        @to.accept_list_start @am, @bullet_list

        accept_list_start_bullet
      end

      def test_accept_list_start_label
        @to.start_accepting

        @to.accept_list_start @am, @label_list

        accept_list_start_label
      end

      def test_accept_list_start_lalpha
        @to.start_accepting

        @to.accept_list_start @am, @lalpha_list

        accept_list_start_lalpha
      end

      def test_accept_list_start_note
        @to.start_accepting

        @to.accept_list_start @am, @note_list

        accept_list_start_note
      end

      def test_accept_list_start_number
        @to.start_accepting

        @to.accept_list_start @am, @number_list

        accept_list_start_number
      end

      def test_accept_list_start_ualpha
        @to.start_accepting

        @to.accept_list_start @am, @ualpha_list

        accept_list_start_ualpha
      end

      def test_accept_list_end_bullet
        @to.start_accepting

        @to.accept_list_start @am, @bullet_list

        @to.accept_list_end @am, @bullet_list

        accept_list_end_bullet
      end

      def test_accept_list_end_label
        @to.start_accepting

        @to.accept_list_start @am, @label_list

        @to.accept_list_end @am, @label_list

        accept_list_end_label
      end

      def test_accept_list_end_lalpha
        @to.start_accepting

        @to.accept_list_start @am, @lalpha_list

        @to.accept_list_end @am, @lalpha_list

        accept_list_end_lalpha
      end

      def test_accept_list_end_number
        @to.start_accepting

        @to.accept_list_start @am, @number_list

        @to.accept_list_end @am, @number_list

        accept_list_end_number
      end

      def test_accept_list_end_note
        @to.start_accepting

        @to.accept_list_start @am, @note_list

        @to.accept_list_end @am, @note_list

        accept_list_end_note
      end

      def test_accept_list_end_ualpha
        @to.start_accepting

        @to.accept_list_start @am, @ualpha_list

        @to.accept_list_end @am, @ualpha_list

        accept_list_end_ualpha
      end
    end
  end

end

