require 'stringio'
require 'test/unit'
require 'rdoc/ri/formatter'
require 'rdoc/ri/display'
require 'rdoc/ri/driver'

class TestRDocRIDefaultDisplay < Test::Unit::TestCase

  def setup
    @output = StringIO.new
    @width = 78
    @indent = '  '

    @dd = RDoc::RI::DefaultDisplay.new RDoc::RI::Formatter, @width, true,
                                       @output
  end

  def test_display_class_info
    klass = {
      'attributes' => [
        { 'name' => 'author', 'rw' => 'RW',
          'comment' => RDoc::Markup::Flow::P.new("<b>Recommended</b>: blah") },
      ],
      'class_methods' => [],
      'class_method_extensions' => [],
      'constants' => [
        { 'name' => 'VERSION', 'value' => '"1.5.1"',
          'comment' => RDoc::Markup::Flow::P.new('The version of Hoe') },
      ],
      'display_name' => 'Class',
      'full_name' => 'Hoe',
      'includes' => [],
      'instance_methods' => [
          { 'name' => 'developer' },
          { 'name' => 'paragraphs_of' },
      ],
      'instance_method_extensions' => [],
      'superclass_string' => 'Object',
    }
    ri_reader = nil

    @dd.display_class_info klass, ri_reader

    expected = <<-EOF
---------------------------------------------------------- Class: Hoe < Object
     (no description...)
------------------------------------------------------------------------------


Constants:
----------

     VERSION: \"1.5.1\"


Instance methods:
-----------------

     developer, paragraphs_of

Attributes:
     author
    EOF

    assert_equal expected, @output.string
  end

end

