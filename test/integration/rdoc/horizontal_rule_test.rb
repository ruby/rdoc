# frozen_string_literal: true
require_relative '../lib/integration_test_case'

class HorizontalRuleTest < IntegrationTestCase

  def test_horizontal_rule
    markup = <<MARKUP
---

--- Not a horizontal rule.

-- Not a horizontal rule.

---

MARKUP
    run_rdoc(markup) do |html_lines|
      # Check count of horizontal rules.
      hr_lines = select_lines(html_lines, '<hr>')
      assert_equal(2, hr_lines.size)
      # Check count of not horizontal rules.
      # One of the above generates an M-dash, the other an N-dash.
      pattern = /<p>(—|–) Not a horizontal rule.<\/p>/
      not_hr_lines = html_lines.select {|line| line.match(pattern) }
      assert_equal(2, not_hr_lines.size)
    end
  end

end
