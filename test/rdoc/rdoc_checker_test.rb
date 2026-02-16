# frozen_string_literal: true

require_relative 'helper'

class RDocCheckerTest < RDoc::TestCase
  def setup
    super
    RDoc::Checker.clear
  end

  def test_warning_to_s_with_file_and_line
    warning = RDoc::Checker::Warning.new("test message", file: "foo.rb", line: 42)
    assert_equal "foo.rb:42: test message", warning.to_s
  end

  def test_warning_to_s_with_file_only
    warning = RDoc::Checker::Warning.new("test message", file: "foo.rb")
    assert_equal "foo.rb: test message", warning.to_s
  end

  def test_warning_to_s_with_message_only
    warning = RDoc::Checker::Warning.new("test message")
    assert_equal "test message", warning.to_s
  end

  def test_add_collects_warnings
    RDoc::Checker.add("warning 1")
    RDoc::Checker.add("warning 2", file: "bar.rb")

    assert_equal 2, RDoc::Checker.warnings.size
    assert_equal "warning 1", RDoc::Checker.warnings[0].message
    assert_equal "bar.rb", RDoc::Checker.warnings[1].file
  end

  def test_any_returns_false_when_empty
    refute RDoc::Checker.any?
  end

  def test_any_returns_true_when_warnings_exist
    RDoc::Checker.add("a warning")
    assert RDoc::Checker.any?
  end

  def test_clear_removes_all_warnings
    RDoc::Checker.add("warning")
    assert RDoc::Checker.any?

    RDoc::Checker.clear
    refute RDoc::Checker.any?
  end

  def test_report_outputs_nothing_when_empty
    out, _err = capture_output do
      RDoc::Checker.report
    end

    assert_empty out
  end

  def test_report_outputs_warnings_grouped
    RDoc::Checker.add("first warning", file: "a.rb", line: 1)
    RDoc::Checker.add("second warning", file: "b.rb")

    out, _err = capture_output do
      RDoc::Checker.report
    end

    assert_match(/Documentation check failures:/, out)
    assert_match(/a\.rb:1: first warning/, out)
    assert_match(/b\.rb: second warning/, out)
    assert_match(/2 check\(s\) failed/, out)
  end
end
