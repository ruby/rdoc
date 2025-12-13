# frozen_string_literal: true
require_relative '../lib/integration_test_case'

class HeadingTest < IntegrationTestCase

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
    run_rdoc(markup) do |html_lines|
      heading_lines = select_lines(html_lines, /^<h\d/)
      # Check count of headings.
      markup_lines = markup.lines
      assert_equal(markup_lines.size, heading_lines.size)
      # Check each markup line against the corresponding heading line.
      markup_lines.each_with_index do |markup_line, index|
        heading_line = heading_lines[index]
        equal_signs, expected_title = markup_line.chomp.split(' ', 2)
        assert(heading_line.include?(expected_title))
        expected_heading_level = equal_signs.size
        heading_line.match(/^<h(\d)/)
        actual_heading_level = $1.to_i
        assert_equal(expected_heading_level, actual_heading_level)
      end
    end
  end

end
