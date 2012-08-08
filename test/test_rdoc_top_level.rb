require File.expand_path '../xref_test_case', __FILE__

class TestRDocTopLevel < XrefTestCase

  def setup
    super

    @top_level = RDoc::TopLevel.new 'path/top_level.rb'
    @top_level.parser = RDoc::Parser::Ruby
  end

  def test_class_new
    tl1 = RDoc::TopLevel.new 'file.rb'
    tl2 = RDoc::TopLevel.new 'file.rb'
    tl3 = RDoc::TopLevel.new 'other.rb'

    assert_same tl1, tl2
    refute_same tl1, tl3
  end

  def test_add_alias
    a = RDoc::Alias.new nil, 'old', 'new', nil
    @top_level.add_alias a

    object = @store.find_class_named 'Object'
    expected = { '#old' => [a] }
    assert_equal expected, object.unmatched_alias_lists
    assert_includes object.in_files, @top_level
  end

  def test_add_alias_nodoc
    @top_level.document_self = false

    a = RDoc::Alias.new nil, 'old', 'new', nil
    @top_level.add_alias a

    object = @store.find_class_named('Object')
    assert_empty object.unmatched_alias_lists
    assert_includes object.in_files, @top_level
  end

  def test_add_constant
    const = RDoc::Constant.new 'C', nil, nil
    @top_level.add_constant const

    object = @store.find_class_named 'Object'
    assert_equal [const], object.constants
    assert_includes object.in_files, @top_level
  end

  def test_add_constant_nodoc
    @top_level.document_self = false

    const = RDoc::Constant.new 'C', nil, nil
    @top_level.add_constant const

    object = @store.find_class_named 'Object'
    assert_empty object.constants
    assert_includes object.in_files, @top_level
  end

  def test_add_include
    include = RDoc::Include.new 'C', nil
    @top_level.add_include include

    object = @store.find_class_named 'Object'
    assert_equal [include], object.includes
    assert_includes object.in_files, @top_level
  end

  def test_add_include_nodoc
    @top_level.document_self = false

    include = RDoc::Include.new 'C', nil
    @top_level.add_include include

    object = @store.find_class_named('Object')
    assert_empty object.includes
    assert_includes object.in_files, @top_level
  end

  def test_add_method
    method = RDoc::AnyMethod.new nil, 'm'
    @top_level.add_method method

    object = @store.find_class_named 'Object'
    assert_equal [method], object.method_list
    assert_includes object.in_files, @top_level
  end

  def test_add_method_stopdoc
    @top_level.document_self = false

    method = RDoc::AnyMethod.new nil, 'm'
    @top_level.add_method method

    object = @store.find_class_named('Object')
    assert_empty object.method_list
    assert_includes object.in_files, @top_level
  end

  def test_base_name
    assert_equal 'top_level.rb', @top_level.base_name
  end

  def test_display_eh
    refute @top_level.display?

    page = RDoc::TopLevel.new 'README.txt'
    page.parser = RDoc::Parser::Simple

    assert page.display?
  end

  def test_eql_eh
    top_level2 = RDoc::TopLevel.new 'path/top_level.rb'
    other_level = RDoc::TopLevel.new 'path/other_level.rb'

    assert_operator @top_level, :eql?, top_level2

    refute_operator other_level, :eql?, @top_level
  end

  def test_equals2
    top_level2 = RDoc::TopLevel.new 'path/top_level.rb'
    other_level = RDoc::TopLevel.new 'path/other_level.rb'

    assert_equal @top_level, top_level2

    refute_equal other_level, @top_level
  end

  def test_find_class_or_module
    assert_equal @c1,    @xref_data.find_class_or_module('C1')
    assert_equal @c2_c3, @xref_data.find_class_or_module('C2::C3')
    assert_equal @c4,    @xref_data.find_class_or_module('C4')
    assert_equal @m1_m2, @xref_data.find_class_or_module('M1::M2')
  end

  def test_full_name
    assert_equal 'path/top_level.rb', @top_level.full_name
  end

  def test_hash
    tl2 = RDoc::TopLevel.new 'path/top_level.rb'
    tl3 = RDoc::TopLevel.new 'other/top_level.rb'

    assert_equal @top_level.hash, tl2.hash
    refute_equal @top_level.hash, tl3.hash
  end

  def test_http_url
    assert_equal 'prefix/path/top_level_rb.html', @top_level.http_url('prefix')
  end

  def test_last_modified
    assert_equal nil, @top_level.last_modified
    stat = Object.new
    def stat.mtime() 0 end
    @top_level.file_stat = stat
    assert_equal 0, @top_level.last_modified
  end

  def test_name
    assert_equal 'top_level.rb', @top_level.name
  end

  def test_page_name
    assert_equal 'top_level', @top_level.page_name

    tl = RDoc::TopLevel.new 'README.ja.rdoc'

    assert_equal 'README.ja', tl.page_name

    tl = RDoc::TopLevel.new 'Rakefile'

    assert_equal 'Rakefile', tl.page_name
  end

  def test_search_record
    assert_nil @xref_data.search_record
  end

  def test_search_record_page
    page = RDoc::TopLevel.new 'README.txt'
    page.parser = RDoc::Parser::Simple
    page.comment = 'This is a comment.'

    expected = [
      'README',
      '',
      'README',
      '',
      'README_txt.html',
      '',
      "<p>This is a comment.\n",
    ]

    assert_equal expected, page.search_record
  end

  def test_text_eh
    refute @xref_data.text?

    rd = RDoc::TopLevel.new 'rd_format.rd'
    rd.parser = RDoc::Parser::RD

    assert rd.text?

    simple = RDoc::TopLevel.new 'simple.txt'
    simple.parser = RDoc::Parser::Simple

    assert simple.text?
  end

  def test_text_eh_no_parser
    refute @xref_data.text?

    rd = RDoc::TopLevel.new 'rd_format.rd'

    refute rd.text?
  end

end

