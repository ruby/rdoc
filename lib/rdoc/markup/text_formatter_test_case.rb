require 'rdoc/markup/formatter_test_case'

##
# Test case for creating new RDoc::Markup formatters.  See
# test_rdoc_markup_to_*.rb for examples.

class RDoc::Markup::TextFormatterTestCase < RDoc::Markup::FormatterTestCase

  def self.add_text_tests
    self.class_eval do

      def test_accept_heading_indent
        @to.start_accepting
        @to.indent = 3
        @to.accept_heading @RM::Heading.new(1, 'Hello')

        accept_heading_indent
      end

      def test_accept_rule_indent
        @to.start_accepting
        @to.indent = 3
        @to.accept_rule @RM::Rule.new(1)

        accept_rule_indent
      end

      def test_accept_verbatim_indent
        @to.start_accepting
        @to.indent = 2
        @to.accept_verbatim @RM::Verbatim.new("hi\n", " world\n")

        accept_verbatim_indent
      end

      def test_accept_verbatim_big_indent
        @to.start_accepting
        @to.indent = 2
        @to.accept_verbatim @RM::Verbatim.new("hi\n", "world\n")

        accept_verbatim_big_indent
      end

      def test_accept_paragraph_indent
        @to.start_accepting
        @to.indent = 3
        @to.accept_paragraph @RM::Paragraph.new(('words ' * 30).strip)

        accept_paragraph_indent
      end

      def test_accept_paragraph_wrap
        @to.start_accepting
        @to.accept_paragraph @RM::Paragraph.new(('words ' * 30).strip)

        accept_paragraph_wrap
      end

      def test_attributes
        assert_equal 'Dog', @to.attributes("\\Dog")
      end

    end
  end

end

