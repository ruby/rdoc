# frozen_string_literal: true

require_relative 'helper'

class RDocCheckerIntegrationTest < RDoc::TestCase
  def test_document_reports_checker_warnings
    RDoc::Checker.add("test warning", file: "test.rb")

    out, _err = capture_output do
      temp_dir do
        File.write("test.rb", "# comment\nclass Foo; end")

        assert_raise(SystemExit) do
          @rdoc.document(["test.rb"])
        end
      end
    end

    assert_match(/Documentation check failures:/, out)
    assert_match(/test warning/, out)
  end

  def test_document_exits_with_status_1_when_warnings
    RDoc::Checker.add("test warning")

    temp_dir do
      File.write("test.rb", "# comment\nclass Foo; end")

      error = assert_raise(SystemExit) do
        capture_output do
          @rdoc.document(["test.rb"])
        end
      end

      assert_equal 1, error.status
    end
  end

  def test_document_does_not_exit_when_no_warnings
    temp_dir do
      File.write("test.rb", "# comment\nclass Foo; end")

      # Should not raise SystemExit
      capture_output do
        @rdoc.document(["test.rb"])
      end
    end
  end

  def test_document_coverage_report_with_warnings_exits_failure
    @options.coverage_report = true
    RDoc::Checker.add("test warning")

    temp_dir do
      File.write("test.rb", "# Documented class\nclass Foo; end")

      error = assert_raise(SystemExit) do
        capture_output do
          @rdoc.document(["test.rb"])
        end
      end

      # Even if fully documented, warnings should cause failure
      assert_equal false, error.success?
    end
  end
end
