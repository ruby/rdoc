# frozen_string_literal: true
require_relative 'helper'

class HeadingTest < XrefTestCase

  def test_headings
    markup = <<MARKUP
= Section 1
== Section 1.1
=== Section 1.1.1
==== Section 1.1.1.1
===== Section 1.1.1.1.1
====== Section 1.1.1.1.1.1
= Section 2
== Section 2.1
=== Section 2.1.1
==== Section 2.1.1.1
===== Section 2.1.1.1.1
====== Section 2.1.1.1.1.1
MARKUP
    Helper.run_rdoc(__method__, markup) do |html_lines|
      heading_lines = Helper.select_lines(html_lines, /^<h\d/)
      # Check count of headings.
      markup_lines = markup.lines
      assert_equal(markup_lines.size, heading_lines.size)
      # Check each markup line against the corresponding heading line.
      markup_lines.each_with_index do |markup_line, index|
        heading_line = heading_lines[index]
        doc = Document.new(heading_line)
        root_ele = doc.root
        # Check number of equal signs against the heading level.
        equal_signs, section_title = markup_line.chomp.split(' ', 2)
        heading_level = equal_signs.size
        assert_equal("h#{heading_level}", root_ele.name)
        # Check the id attribute.
        id_value = root_ele.attribute('id').value
        assert_equal("label-#{section_title.gsub(' ', '+')}", id_value)
      end
    end
  end

end
