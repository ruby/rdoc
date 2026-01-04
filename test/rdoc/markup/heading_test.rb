# frozen_string_literal: true
require_relative '../helper'

class RDocMarkupHeadingTest < RDoc::TestCase

  def setup
    super

    @h = RDoc::Markup::Heading.new 1, 'Hello *Friend*!'
  end

  def test_aref
    assert_equal 'hello-friend', @h.aref
  end

  def test_label
    assert_equal 'hello-friend', @h.label
    assert_equal 'hello-friend', @h.label(nil)

    context = RDoc::NormalClass.new 'Foo'

    assert_equal 'class-foo-hello-friend', @h.label(context)
  end

  def test_legacy_aref
    # Note: *Friend* markup is stripped, ! becomes %21 which becomes -21
    assert_equal 'label-Hello+Friend-21', @h.legacy_aref
  end

  def test_legacy_label
    assert_equal 'label-Hello+Friend-21', @h.legacy_label
    assert_equal 'label-Hello+Friend-21', @h.legacy_label(nil)

    context = RDoc::NormalClass.new 'Foo'
    assert_equal 'class-Foo-label-Hello+Friend-21', @h.legacy_label(context)
  end

  def test_legacy_label_preserves_context_casing
    h = RDoc::Markup::Heading.new 1, 'Credits'
    context = RDoc::NormalModule.new 'RDoc'
    assert_equal 'module-RDoc-label-Credits', h.legacy_label(context)

    # Nested module example
    parent = RDoc::NormalModule.new 'Foo'
    context = RDoc::NormalClass.new 'Bar'
    context.parent = parent
    assert_equal 'class-Foo::Bar-label-Credits', h.legacy_label(context)
  end

  def test_plain_html
    assert_equal 'Hello <strong>Friend</strong>!', @h.plain_html
  end

  def test_plain_html_using_image_alt_as_text
    h = RDoc::Markup::Heading.new 1, 'rdoc-image:foo.png:Hello World'

    assert_equal 'Hello World', h.plain_html
  end
end
