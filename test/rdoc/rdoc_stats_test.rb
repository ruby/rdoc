# frozen_string_literal: true
require_relative 'helper'

class RDocStatsTest < RDoc::TestCase

  def setup
    super

    @s = RDoc::Stats.new @store, 0

    @tl = @store.add_file 'file.rb'
    @tl.parser = RDoc::Parser::Ruby
  end

  def test_doc_stats
    c = RDoc::CodeObject.new

    assert_equal [1, 1], @s.doc_stats([c])
  end

  def test_doc_stats_documented
    c = RDoc::CodeObject.new
    c.comment = comment 'x'

    assert_equal [1, 0], @s.doc_stats([c])
  end

  def test_doc_stats_display_eh
    c = RDoc::CodeObject.new
    c.ignore

    assert_equal [0, 0], @s.doc_stats([c])
  end

  def test_report_attr
    c = @tl.add_class RDoc::NormalClass, 'C'
    c.record_location @tl
    c.add_comment 'C', @tl

    a = RDoc::Attr.new nil, 'a', 'RW', nil
    a.record_location @tl
    a.line = 3
    c.add_attribute a

    @store.complete :public

    report = @s.report

    assert_match "The following items are not documented:\n", report
    assert_match "file.rb:\n  Attribute:\n    C#a file.rb:3\n", report
  end

  def test_report_attr_documented
    c = @tl.add_class RDoc::NormalClass, 'C'
    c.record_location @tl
    c.add_comment 'C', @tl

    a = RDoc::Attr.new nil, 'a', 'RW', 'a'
    a.record_location @tl
    c.add_attribute a

    @store.complete :public

    assert_match "100% documentation!\nGreat Job!\n", @s.report
  end

  def test_report_constant
    m = @tl.add_module RDoc::NormalModule, 'M'
    m.record_location @tl
    m.add_comment 'M', @tl

    c = RDoc::Constant.new 'C', nil, nil
    c.record_location @tl
    c.line = 7
    m.add_constant c

    @store.complete :public

    report = @s.report

    assert_match "The following items are not documented:\n", report
    assert_match "file.rb:\n  Constant:\n    M::C file.rb:7\n", report
  end

  def test_report_constant_alias
    mod = @tl.add_module RDoc::NormalModule, 'M'

    c = @tl.add_class RDoc::NormalClass, 'C'
    mod.add_constant c

    ca = RDoc::Constant.new 'CA', nil, nil
    ca.is_alias_for = c

    @tl.add_constant ca

    @store.complete :public

    # Constant aliases are skipped in the report
    refute_match 'CA', @s.report
  end

  def test_report_constant_documented
    m = @tl.add_module RDoc::NormalModule, 'M'
    m.record_location @tl
    m.add_comment 'M', @tl

    c = RDoc::Constant.new 'C', nil, 'C'
    c.record_location @tl
    m.add_constant c

    @store.complete :public

    assert_match "100% documentation!\nGreat Job!\n", @s.report
  end

  def test_report_class
    c = @tl.add_class RDoc::NormalClass, 'C'
    c.record_location @tl

    m = RDoc::AnyMethod.new nil, 'm'
    m.record_location @tl
    c.add_method m
    m.comment = 'm'

    @store.complete :public

    report = @s.report

    assert_match "The following items are not documented:\n", report
    assert_match "file.rb:\n  Class:\n    C\n", report
  end

  def test_report_skip_object
    c = @tl.add_class RDoc::NormalClass, 'Object'
    c.record_location @tl

    m = RDoc::AnyMethod.new nil, 'm'
    m.record_location @tl
    c.add_method m
    m.comment = 'm'

    @store.complete :public

    refute_match(/^\s+Object$/, @s.report)
  end

  def test_report_class_documented
    c = @tl.add_class RDoc::NormalClass, 'C'
    c.record_location @tl
    c.add_comment 'C', @tl

    m = RDoc::AnyMethod.new nil, 'm'
    m.record_location @tl
    c.add_method m
    m.comment = 'm'

    @store.complete :public

    assert_match "100% documentation!\nGreat Job!\n", @s.report
  end

  def test_report_class_documented_level_1
    c1 = @tl.add_class RDoc::NormalClass, 'C1'
    c1.record_location @tl
    c1.add_comment 'C1', @tl

    m1 = RDoc::AnyMethod.new nil, 'm1'
    m1.record_location @tl
    c1.add_method m1
    m1.comment = 'm1'

    c2 = @tl.add_class RDoc::NormalClass, 'C2'
    c2.record_location @tl

    m2 = RDoc::AnyMethod.new nil, 'm2'
    m2.record_location @tl
    c2.add_method m2
    m2.comment = 'm2'

    @store.complete :public

    @s.coverage_level = 1

    report = @s.report

    assert_match "The following items are not documented:\n", report
    assert_match "file.rb:\n  Class:\n    C2\n", report
  end

  def test_report_class_empty
    @tl.add_class RDoc::NormalClass, 'C'

    @store.complete :public

    report = @s.report

    assert_match "The following items are not documented:\n", report
    assert_match "C is referenced but empty.\n", report
    assert_match "It probably came from another project.", report
  end

  def test_report_class_empty_2
    c1 = @tl.add_class RDoc::NormalClass, 'C1'
    c1.record_location @tl

    c2 = @tl.add_class RDoc::NormalClass, 'C2'
    c2.record_location @tl
    c2.add_comment 'C2', @tl

    @store.complete :public

    @s.coverage_level = 1

    report = @s.report

    assert_match "The following items are not documented:\n", report
    assert_match "file.rb:\n  Class:\n    C1\n", report
  end

  def test_report_ignored_class_excluded
    c = @tl.add_class RDoc::NormalClass, 'C'
    c.ignore

    @store.complete :public

    refute_match(/^\s+C$/, @s.report)
  end

  def test_report_empty
    @store.complete :public

    assert_match "100% documentation!\nGreat Job!\n", @s.report
  end

  def test_report_method
    c = @tl.add_class RDoc::NormalClass, 'C'
    c.record_location @tl
    c.add_comment 'C', @tl

    m1 = RDoc::AnyMethod.new nil, 'm1'
    m1.record_location @tl
    m1.line = 5
    c.add_method m1

    m2 = RDoc::AnyMethod.new nil, 'm2'
    m2.record_location @tl
    c.add_method m2
    m2.comment = 'm2'

    @store.complete :public

    report = @s.report

    assert_match "The following items are not documented:\n", report
    assert_match "file.rb:\n  Method:\n    C#m1 file.rb:5\n", report
  end

  def test_report_method_class
    c = @tl.add_class RDoc::NormalClass, 'C'
    c.record_location @tl
    c.add_comment 'C', @tl

    m1 = RDoc::AnyMethod.new nil, 'm1', singleton: true
    m1.record_location @tl
    m1.line = 8
    c.add_method m1

    m2 = RDoc::AnyMethod.new nil, 'm2', singleton: true
    m2.record_location @tl
    c.add_method m2
    m2.comment = 'm2'

    @store.complete :public

    report = @s.report

    assert_match "The following items are not documented:\n", report
    assert_match "file.rb:\n  Method:\n    C.m1 file.rb:8\n", report
  end

  def test_report_method_documented
    c = @tl.add_class RDoc::NormalClass, 'C'
    c.record_location @tl
    c.add_comment 'C', @tl

    m = RDoc::AnyMethod.new nil, 'm'
    m.record_location @tl
    c.add_method m
    m.comment = 'm'

    @store.complete :public

    assert_match "100% documentation!\nGreat Job!\n", @s.report
  end

  def test_report_method_parameters
    c = @tl.add_class RDoc::NormalClass, 'C'
    c.record_location @tl
    c.add_comment 'C', @tl

    m1 = RDoc::AnyMethod.new nil, 'm1'
    m1.record_location @tl
    m1.line = 10
    m1.params = '(p1, p2)'
    m1.comment = 'Stuff with +p1+'
    c.add_method m1

    m2 = RDoc::AnyMethod.new nil, 'm2'
    m2.record_location @tl
    c.add_method m2
    m2.comment = 'm2'

    @store.complete :public

    @s.coverage_level = 1

    report = @s.report

    assert_match "file.rb:\n  Method:\n    C#m1 file.rb:10\n      Undocumented params: p2\n", report
  end

  def test_report_method_parameters_documented
    @tl.parser = RDoc::Parser::Ruby
    c = @tl.add_class RDoc::NormalClass, 'C'
    c.record_location @tl
    c.add_comment 'C', @tl

    m = RDoc::AnyMethod.new nil, 'm'
    m.record_location @tl
    m.params = '(p1)'
    m.comment = 'Stuff with +p1+'
    c.add_method m

    @store.complete :public

    @s.coverage_level = 1

    assert_match "100% documentation!\nGreat Job!\n", @s.report
  end

  def test_report_method_parameters_yield
    c = @tl.add_class RDoc::NormalClass, 'C'
    c.record_location @tl
    c.add_comment 'C', @tl

    m = RDoc::AnyMethod.new nil, 'm'
    m.record_location @tl
    m.call_seq = <<-SEQ
m(a) { |c| ... }
m(a, b) { |c, d| ... }
    SEQ
    m.comment = 'Stuff with +a+, yields +c+ for you to do stuff with'
    c.add_method m

    @store.complete :public

    @s.coverage_level = 1

    report = @s.report

    assert_match "file.rb:\n  Method:\n    C#m\n      Undocumented params: b, d\n", report
  end

  def test_report_multiple_files
    tl2 = @store.add_file 'other.rb'
    tl2.parser = RDoc::Parser::Ruby

    c1 = @tl.add_class RDoc::NormalClass, 'C1'
    c1.record_location @tl

    c2 = tl2.add_class RDoc::NormalClass, 'C2'
    c2.record_location tl2

    @store.complete :public

    report = @s.report

    assert_match "The following items are not documented:\n", report
    assert_match "file.rb:\n  Class:\n    C1\n", report
    assert_match "other.rb:\n  Class:\n    C2\n", report
  end

  def test_report_reopened_class_lists_each_file
    tl2 = @store.add_file 'other.rb'
    tl2.parser = RDoc::Parser::Ruby

    c = @tl.add_class RDoc::NormalClass, 'C'
    c.record_location @tl

    reopened = tl2.add_class RDoc::NormalClass, 'C'
    reopened.record_location tl2

    assert_same c, reopened

    @store.complete :public

    report = @s.report

    assert_match "file.rb:\n  Class:\n    C\n", report
    assert_match "other.rb:\n  Class:\n    C\n", report
  end

  def test_report_reopened_class_lists_each_file_regardless_of_parse_order
    tl2 = @store.add_file 'other.rb'
    tl2.parser = RDoc::Parser::Ruby

    c = tl2.add_class RDoc::NormalClass, 'C'
    c.record_location tl2

    reopened = @tl.add_class RDoc::NormalClass, 'C'
    reopened.record_location @tl

    assert_same c, reopened

    @store.complete :public

    report = @s.report

    assert_match "file.rb:\n  Class:\n    C\n", report
    assert_match "other.rb:\n  Class:\n    C\n", report
  end

  def test_report_file_sorting
    tl_b = @store.add_file 'b.rb'
    tl_b.parser = RDoc::Parser::Ruby
    tl_a = @store.add_file 'a.rb'
    tl_a.parser = RDoc::Parser::Ruby

    c1 = tl_b.add_class RDoc::NormalClass, 'B'
    c1.record_location tl_b

    c2 = tl_a.add_class RDoc::NormalClass, 'A'
    c2.record_location tl_a

    @store.complete :public

    report = @s.report

    a_pos = report.index('a.rb:')
    b_pos = report.index('b.rb:')

    assert a_pos < b_pos, "a.rb should appear before b.rb"
  end

  def test_report_items_without_line_sort_first
    c = @tl.add_class RDoc::NormalClass, 'C'
    c.record_location @tl
    c.add_comment 'C', @tl

    m1 = RDoc::AnyMethod.new nil, 'with_line'
    m1.record_location @tl
    m1.line = 3
    c.add_method m1

    m2 = RDoc::AnyMethod.new nil, 'no_line'
    m2.record_location @tl
    c.add_method m2

    @store.complete :public

    report = @s.report

    no_line_pos = report.index('no_line')
    with_line_pos = report.index('with_line')

    assert no_line_pos < with_line_pos,
      "Items without line numbers should appear before items with line numbers"
  end

  def test_report_item_sorting_by_line
    c = @tl.add_class RDoc::NormalClass, 'C'
    c.record_location @tl
    c.add_comment 'C', @tl

    m1 = RDoc::AnyMethod.new nil, 'z_method'
    m1.record_location @tl
    m1.line = 5
    c.add_method m1

    m2 = RDoc::AnyMethod.new nil, 'a_method'
    m2.record_location @tl
    m2.line = 10
    c.add_method m2

    @store.complete :public

    report = @s.report

    z_pos = report.index('z_method')
    a_pos = report.index('a_method')

    assert z_pos < a_pos, "z_method (line 5) should appear before a_method (line 10)"
  end

  def test_report_mixed_types_in_file
    c = @tl.add_class RDoc::NormalClass, 'C'
    c.record_location @tl
    c.add_comment 'C', @tl

    a = RDoc::Attr.new nil, 'a', 'RW', nil
    a.record_location @tl
    a.line = 3
    c.add_attribute a

    k = RDoc::Constant.new 'K', nil, nil
    k.record_location @tl
    k.line = 5
    c.add_constant k

    m = RDoc::AnyMethod.new nil, 'm'
    m.record_location @tl
    m.line = 7
    c.add_method m

    @store.complete :public

    report = @s.report

    assert_match "file.rb:\n", report
    assert_match "  Constant:\n    C::K file.rb:5\n", report
    assert_match "  Attribute:\n    C#a file.rb:3\n", report
    assert_match "  Method:\n    C#m file.rb:7\n", report
  end

  def test_report_multi_file_class
    tl2 = @store.add_file 'ext.c'
    tl2.parser = RDoc::Parser::C

    c = @tl.add_class RDoc::NormalClass, 'C'
    c.record_location @tl
    c.add_comment 'C', @tl

    m1 = RDoc::AnyMethod.new nil, 'ruby_method'
    m1.record_location @tl
    m1.line = 10
    c.add_method m1

    m2 = RDoc::AnyMethod.new nil, 'c_method'
    m2.record_location tl2
    c.add_method m2

    @store.complete :public

    report = @s.report

    assert_match "ext.c:\n  Method:\n    C#c_method\n", report
    assert_match "file.rb:\n  Method:\n    C#ruby_method file.rb:10\n", report
  end

  def test_summary
    c = @tl.add_class RDoc::NormalClass, 'C'
    c.record_location @tl

    m = @tl.add_module RDoc::NormalModule, 'M'
    m.record_location @tl

    a = RDoc::Attr.new nil, 'a', 'RW', nil
    a.record_location @tl
    c.add_attribute a

    c_c = RDoc::Constant.new 'C', nil, nil
    c_c.record_location @tl
    c.add_constant c_c

    m = RDoc::AnyMethod.new nil, 'm'
    m.record_location @tl
    c.add_method m

    @store.complete :public

    summary = @s.summary
    summary.sub!(/Elapsed:.*/m, '')

    expected = <<~EXPECTED
      Files:      0

      Classes:    1 (1 undocumented)
      Modules:    1 (1 undocumented)
      Constants:  1 (1 undocumented)
      Attributes: 1 (1 undocumented)
      Methods:    1 (1 undocumented)

      Total:      5 (5 undocumented)
        0.00% documented

    EXPECTED

    assert_equal expected, summary
  end

  def test_summary_level_false
    c = @tl.add_class RDoc::NormalClass, 'C'
    c.record_location @tl

    @store.complete :public

    @s.coverage_level = false

    summary = @s.summary
    summary.sub!(/Elapsed:.*/m, '')

    expected = <<~EXPECTED
      Files:      0

      Classes:    1 (1 undocumented)
      Modules:    0 (0 undocumented)
      Constants:  0 (0 undocumented)
      Attributes: 0 (0 undocumented)
      Methods:    0 (0 undocumented)

      Total:      1 (1 undocumented)
        0.00% documented

    EXPECTED

    assert_equal expected, summary
  end

  def test_summary_level_1
    c = @tl.add_class RDoc::NormalClass, 'C'
    c.record_location @tl
    c.add_comment 'C', @tl

    m = RDoc::AnyMethod.new nil, 'm'
    m.record_location @tl
    m.params = '(p1, p2)'
    m.comment = 'Stuff with +p1+'
    c.add_method m

    @store.complete :public

    @s.coverage_level = 1
    @s.report

    summary = @s.summary
    summary.sub!(/Elapsed:.*/m, '')

    expected = <<~EXPECTED
      Files:      0

      Classes:    1 (0 undocumented)
      Modules:    0 (0 undocumented)
      Constants:  0 (0 undocumented)
      Attributes: 0 (0 undocumented)
      Methods:    1 (0 undocumented)
      Parameters: 2 (1 undocumented)

      Total:      4 (1 undocumented)
       75.00% documented

    EXPECTED

    assert_equal expected, summary
  end

  def test_undoc_params
    method = RDoc::AnyMethod.new [], 'm'
    method.params = '(a)'
    method.comment = comment 'comment'

    total, undoc = @s.undoc_params method

    assert_equal 1,     total
    assert_equal %w[a], undoc
  end

  def test_undoc_params_block
    method = RDoc::AnyMethod.new [], 'm'
    method.params = '(&a)'
    method.comment = comment '+a+'

    total, undoc = @s.undoc_params method

    assert_equal 1, total
    assert_empty    undoc
  end

  def test_undoc_params_documented
    method = RDoc::AnyMethod.new [], 'm'
    method.params = '(a)'
    method.comment = comment '+a+'

    total, undoc = @s.undoc_params method

    assert_equal 1, total
    assert_empty    undoc
  end

  def test_undoc_params_keywords
    method = RDoc::AnyMethod.new [], 'm'
    method.params = '(**a)'
    method.comment = comment '+a+'

    total, undoc = @s.undoc_params method

    assert_equal 1, total
    assert_empty    undoc
  end

  def test_undoc_params_splat
    method = RDoc::AnyMethod.new [], 'm'
    method.params = '(*a)'
    method.comment = comment '+a+'

    total, undoc = @s.undoc_params method

    assert_equal 1, total
    assert_empty    undoc
  end

end
