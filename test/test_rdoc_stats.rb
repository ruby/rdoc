require 'rubygems'
require 'minitest/autorun'
require 'rdoc/stats'
require 'rdoc/code_objects'
require 'rdoc/markup'
require 'rdoc/parser'

class TestRDocStats < MiniTest::Unit::TestCase

  def setup
    RDoc::TopLevel.reset

    @s = RDoc::Stats.new 0
  end

  def test_report_attr
    tl = RDoc::TopLevel.new 'file.rb'
    c = tl.add_class RDoc::NormalClass, 'C'
    c.record_location tl
    c.comment = 'C'

    a = RDoc::Attr.new nil, 'a', 'RW', nil
    a.record_location tl
    c.add_attribute a

    RDoc::TopLevel.complete :public

    report = @s.report

    expected = <<-EXPECTED
The following items are not documented:

class C # is documented

  attr_accessor :a # in file file.rb
end
    EXPECTED

    assert_equal expected, report
  end

  def test_report_attr_documented
    tl = RDoc::TopLevel.new 'file.rb'
    c = tl.add_class RDoc::NormalClass, 'C'
    c.record_location tl
    c.comment = 'C'

    a = RDoc::Attr.new nil, 'a', 'RW', 'a'
    a.record_location tl
    c.add_attribute a

    RDoc::TopLevel.complete :public

    report = @s.report

    expected = <<-EXPECTED.chomp
100% documentation!

Great Job!
    EXPECTED

    assert_equal expected, report
  end

  def test_report_constant
    tl = RDoc::TopLevel.new 'file.rb'
    m = tl.add_class RDoc::NormalModule, 'M'
    m.record_location tl
    m.comment = 'M'

    c = RDoc::Constant.new 'C', nil, nil
    c.record_location tl
    m.add_constant c

    RDoc::TopLevel.complete :public

    report = @s.report

    expected = <<-EXPECTED
The following items are not documented:

module M # is documented

  # in file file.rb
  C = nil
end
    EXPECTED

    assert_equal expected, report
  end

  def test_report_constant_alias
    tl = RDoc::TopLevel.new 'file.rb'
    mod = tl.add_module RDoc::NormalModule, 'M'

    c = tl.add_class RDoc::NormalClass, 'C'
    mod.add_constant c

    ca = RDoc::Constant.new 'CA', nil, nil
    ca.is_alias_for = c

    tl.add_constant ca

    RDoc::TopLevel.complete :public

    report = @s.report

    # TODO change this to refute match, aliases should be ignored as they are
    # programmer convenience constructs
    assert_match(/class Object/, report)
  end

  def test_report_constant_documented
    tl = RDoc::TopLevel.new 'file.rb'
    m = tl.add_class RDoc::NormalModule, 'M'
    m.record_location tl
    m.comment = 'M'

    c = RDoc::Constant.new 'C', nil, 'C'
    c.record_location tl
    m.add_constant c

    RDoc::TopLevel.complete :public

    report = @s.report

    expected = <<-EXPECTED.chomp
100% documentation!

Great Job!
    EXPECTED

    assert_equal expected, report
  end

  def test_report_class
    tl = RDoc::TopLevel.new 'file.rb'
    c = tl.add_class RDoc::NormalClass, 'C'
    c.record_location tl

    m = RDoc::AnyMethod.new nil, 'm'
    m.record_location tl
    c.add_method m
    m.comment = 'm'

    RDoc::TopLevel.complete :public

    report = @s.report

    expected = <<-EXPECTED
The following items are not documented:

# in files:
#   file.rb

class C

end
    EXPECTED

    assert_equal expected, report
  end

  def test_report_class_documented
    tl = RDoc::TopLevel.new 'file.rb'
    c = tl.add_class RDoc::NormalClass, 'C'
    c.record_location tl
    c.comment = 'C'

    m = RDoc::AnyMethod.new nil, 'm'
    m.record_location tl
    c.add_method m
    m.comment = 'm'

    RDoc::TopLevel.complete :public

    report = @s.report

    expected = <<-EXPECTED.chomp
100% documentation!

Great Job!
    EXPECTED

    assert_equal expected, report
  end

  def test_report_class_empty
    tl = RDoc::TopLevel.new 'file.rb'
    tl.add_class RDoc::NormalClass, 'C'

    RDoc::TopLevel.complete :public

    report = @s.report

    expected = <<-EXPECTED
The following items are not documented:

# class C is referenced but empty.
#
# It probably came from another project.  I'm sorry I'm holding it against you.
    EXPECTED

    assert_equal expected, report
  end

  def test_report_class_method_documented
    tl = RDoc::TopLevel.new 'file.rb'
    c = tl.add_class RDoc::NormalClass, 'C'
    c.record_location tl

    m = RDoc::AnyMethod.new nil, 'm'
    m.record_location tl
    c.add_method m
    m.comment = 'm'

    RDoc::TopLevel.complete :public

    report = @s.report

    expected = <<-EXPECTED
The following items are not documented:

# in files:
#   file.rb

class C

end
    EXPECTED

    assert_equal expected, report
  end

  def test_report_empty
    RDoc::TopLevel.complete :public

    report = @s.report

    expected = <<-EXPECTED.chomp
100% documentation!

Great Job!
    EXPECTED

    assert_equal expected, report
  end

  def test_report_method
    tl = RDoc::TopLevel.new 'file.rb'
    c = tl.add_class RDoc::NormalClass, 'C'
    c.record_location tl
    c.comment = 'C'

    m1 = RDoc::AnyMethod.new nil, 'm1'
    m1.record_location tl
    c.add_method m1

    m2 = RDoc::AnyMethod.new nil, 'm2'
    m2.record_location tl
    c.add_method m2
    m2.comment = 'm2'

    RDoc::TopLevel.complete :public

    report = @s.report

    expected = <<-EXPECTED
The following items are not documented:

class C # is documented

  # in file file.rb
  def m1; end

end
    EXPECTED

    assert_equal expected, report
  end

  def test_report_method_documented
    tl = RDoc::TopLevel.new 'file.rb'
    c = tl.add_class RDoc::NormalClass, 'C'
    c.record_location tl
    c.comment = 'C'

    m = RDoc::AnyMethod.new nil, 'm'
    m.record_location tl
    c.add_method m
    m.comment = 'm'

    RDoc::TopLevel.complete :public

    report = @s.report

    expected = <<-EXPECTED.chomp
100% documentation!

Great Job!
    EXPECTED

    assert_equal expected, report
  end

end

