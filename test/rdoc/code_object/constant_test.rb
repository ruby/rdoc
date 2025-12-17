# frozen_string_literal: true
require_relative '../xref_test_case'

class RDocConstantTest < XrefTestCase

  def setup
    super

    @const = @c1.constants.first
  end

  def test_documented_eh
    file = @store.add_file 'file.rb'

    const = RDoc::Constant.new 'CONST', nil, nil
    file.add_constant const

    refute const.documented?

    const.comment = comment 'comment'

    assert const.documented?
  end

  def test_documented_eh_alias
    file = @store.add_file 'file.rb'

    const = RDoc::Constant.new 'CONST', nil, nil
    file.add_constant const

    refute const.documented?

    const.is_alias_for = 'C1'

    refute const.documented?

    @c1.add_comment comment('comment'), @file

    assert const.documented?
  end

  def test_full_name
    assert_equal 'C1::CONST', @const.full_name
  end

  def test_is_alias_for
    file = @store.add_file 'file.rb'

    c = RDoc::Constant.new 'CONST', nil, 'comment'
    file.add_constant c

    assert_nil c.is_alias_for

    c.is_alias_for = 'C1'

    assert_equal @c1, c.is_alias_for

    c.is_alias_for = 'unknown'

    assert_equal 'unknown', c.is_alias_for
  end

  def test_marshal_dump
    file = @store.add_file 'file.rb'

    c = RDoc::Constant.new 'CONST', nil, 'this is a comment'
    c.record_location file

    aliased = file.add_class RDoc::NormalClass, 'Aliased'
    c.is_alias_for = aliased

    cm = file.add_class RDoc::NormalClass, 'Klass'
    cm.add_constant c

    section = cm.sections.first

    loaded = Marshal.load Marshal.dump c
    loaded.store = @store

    document = doc(para('this is a comment'))

    assert_equal c, loaded

    assert_equal aliased,        loaded.is_alias_for
    assert_equal document,       loaded.comment.parse
    assert_equal file,      loaded.file
    assert_equal 'Klass::CONST', loaded.full_name
    assert_equal 'CONST',        loaded.name
    assert_equal :public,        loaded.visibility
    assert_equal cm,             loaded.parent
    assert_equal section,        loaded.section
  end

  def test_marshal_load
    file = @store.add_file 'file.rb'

    c = RDoc::Constant.new 'CONST', nil, 'this is a comment'
    c.record_location file

    cm = file.add_class RDoc::NormalClass, 'Klass'
    cm.add_constant c

    section = cm.sections.first

    loaded = Marshal.load Marshal.dump c
    loaded.store = @store

    document = doc(para('this is a comment'))

    assert_equal c, loaded

    assert_nil                   loaded.is_alias_for
    assert_equal document,       loaded.comment.parse
    assert_equal file,      loaded.file
    assert_equal 'Klass::CONST', loaded.full_name
    assert_equal 'CONST',        loaded.name
    assert_equal :public,        loaded.visibility
    assert_equal cm,             loaded.parent
    assert_equal section,        loaded.section

    assert                       loaded.display?
  end

  def test_marshal_load_version_0
    file = @store.add_file 'file.rb'

    aliased = file.add_class RDoc::NormalClass, 'Aliased'
    cm      = file.add_class RDoc::NormalClass, 'Klass'
    section = cm.sections.first

    loaded = Marshal.load "\x04\bU:\x13RDoc::Constant[\x0Fi\x00I" +
                          "\"\nCONST\x06:\x06ETI\"\x11Klass::CONST\x06" +
                          ";\x06T0I\"\fAliased\x06;\x06To" +
                          ":\eRDoc::Markup::Document\a:\v@parts[\x06o" +
                          ":\x1CRDoc::Markup::Paragraph\x06;\b[\x06I" +
                          "\"\x16this is a comment\x06;\x06T:\n@file0I" +
                          "\"\ffile.rb\x06;\x06TI\"\nKlass\x06" +
                          ";\x06Tc\x16RDoc::NormalClass0"

    loaded.store = @store

    document = doc(para('this is a comment'))

    assert_equal aliased,        loaded.is_alias_for
    assert_equal document,       loaded.comment.parse
    assert_equal file,      loaded.file
    assert_equal 'Klass::CONST', loaded.full_name
    assert_equal 'CONST',        loaded.name
    assert_equal :public,        loaded.visibility
    assert_equal cm,             loaded.parent
    assert_equal section,        loaded.section

    assert loaded.display?
  end

  def test_marshal_round_trip
    file = @store.add_file 'file.rb'

    c = RDoc::Constant.new 'CONST', nil, 'this is a comment'
    c.record_location file
    c.is_alias_for = 'Unknown'

    cm = file.add_class RDoc::NormalClass, 'Klass'
    cm.add_constant c

    section = cm.sections.first

    loaded = Marshal.load Marshal.dump c
    loaded.store = @store

    reloaded = Marshal.load Marshal.dump loaded
    reloaded.store = @store

    assert_equal section,   reloaded.section
    assert_equal 'Unknown', reloaded.is_alias_for
  end

  def test_path
    assert_equal 'C1.html#CONST', @const.path
  end

end
