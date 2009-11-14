require 'rubygems'
require 'minitest/autorun'
require 'rdoc/ri/writer'
require 'rdoc/rdoc'
require 'tmpdir'
require 'fileutils'

class TestRDocRIWriter < MiniTest::Unit::TestCase

  def setup
    @tmpdir = File.join Dir.tmpdir, "test_rdoc_ri_writer_#{$$}"
    @w = RDoc::RI::Writer.new @tmpdir

    @obj = RDoc::ClassModule.new 'Object'
    @meth = RDoc::AnyMethod.new nil, 'method'
  end

  def teardown
    FileUtils.rm_rf @tmpdir
  end

  def test_add_class
    @w.add_class @obj

    flunk
  end

end

