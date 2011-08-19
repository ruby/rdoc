require 'rubygems'
require 'minitest/autorun'

require 'fileutils'
require 'pp'
require 'tempfile'
require 'tmpdir'
require 'stringio'

require 'rdoc'

class RDoc::TestCase < MiniTest::Unit::TestCase

  def setup
    super

    @RM = RDoc::Markup

    RDoc::RDoc.reset
    RDoc::Markup::PreProcess.registered.clear

    @pwd = Dir.pwd
  end

end

