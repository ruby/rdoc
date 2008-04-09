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
    ri_reader = nil
    klass = {
      'attributes' => [
        { 'name' => 'attribute', 'rw' => 'RW',
          'comment' => [RDoc::Markup::Flow::P.new('attribute comment')] },
        { 'name' => 'attribute_no_comment', 'rw' => 'RW',
          'comment' => nil },
      ],
      'class_methods' => [
        { 'name' => 'class_method' },
      ],
      'class_method_extensions' => [
        { 'name' => 'class_method_extension' },
      ],
      'comment' => [RDoc::Markup::Flow::P.new('SomeClass comment')],
      'constants' => [
        { 'name' => 'CONSTANT', 'value' => '"value"',
          'comment' => [RDoc::Markup::Flow::P.new('CONSTANT value')] },
        { 'name' => 'CONSTANT_NOCOMMENT', 'value' => '"value"',
          'comment' => nil },
      ],
      'display_name' => 'Class',
      'full_name' => 'SomeClass',
      'includes' => [],
      'instance_methods' => [
        { 'name' => 'instance_method' },
      ],
      'instance_method_extensions' => [
        { 'name' => 'instance_method_extension' },
      ],
      'superclass_string' => 'Object',
    }

    @dd.display_class_info klass, ri_reader

    expected = <<-EOF
---------------------------------------------------- Class: SomeClass < Object
     SomeClass comment

------------------------------------------------------------------------------


Constants:
----------

     CONSTANT:
          CONSTANT value

     CONSTANT_NOCOMMENT


Class methods:
--------------

     class_method


Class method extensions:
------------------------

     class_method_extension


Instance methods:
-----------------

     instance_method


Instance method extensions:
---------------------------

     instance_method_extension


Attributes:
-----------

     attribute (RW):
          attribute comment

     attribute_no_comment (RW)
    EOF

    assert_equal expected, @output.string
  end

end

