require 'rubygems'
require 'minitest/autorun'

require 'fileutils'
require 'pp'
require 'tempfile'
require 'tmpdir'
require 'stringio'

require 'rdoc'

##
# RDoc::TestCase is an abstract TestCase to provide common setup and teardown
# across all RDoc tests.  The test case uses minitest, so all the assertions
# of minitest may be used.
#
# The testcase provides the following:
#
# * A reset code-object tree
# * A reset markup preprocessor (RDoc::Markup::PreProcess)
# * The <code>@RM</code> alias of RDoc::Markup (for less typing)
# * <code>@pwd</code> containing the current working directory
# * FileUtils, pp, Tempfile, Dir.tmpdir and StringIO

class RDoc::TestCase < MiniTest::Unit::TestCase

  ##
  # Abstract test-case setup

  def setup
    super

    @top_level = nil

    @RM = RDoc::Markup

    RDoc::RDoc.reset
    RDoc::Markup::PreProcess.registered.clear

    @pwd = Dir.pwd
  end

  def comment text, top_level = @top_level
    RDoc::Comment.new text, top_level
  end

end

