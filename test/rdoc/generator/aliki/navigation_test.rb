# frozen_string_literal: true
require_relative '../../helper'

return if RUBY_DESCRIPTION =~ /truffleruby/ || RUBY_DESCRIPTION =~ /jruby/

begin
  require 'mini_racer'
rescue LoadError
  return
end

class RDocGeneratorAlikiNavigationTest < Test::Unit::TestCase
  def setup
    @context = MiniRacer::Context.new
    @context.eval <<~JS
      class Element {
        constructor(tag) {
          this.tag = tag;
          this.children = [];
        }
        appendChild(child) { this.children.push(child); }
        replaceChildren(...children) { this.children = children; }
        set innerHTML(value) { throw new Error('Navigation must use textContent'); }
      }
      const container = new Element('ul');
      container.className = 'link-list nav-list';
      const document = {
        createElement: tag => new Element(tag),
        listeners: {},
        addEventListener(event, callback) { this.listeners[event] = callback; },
        getElementById: id => id === 'class-navigation' ? container : null
      };
      function elements(tag, root = container) {
        return root.children.flatMap(child =>
          (child.tag === tag ? [child] : []).concat(elements(tag, child)));
      }
      const nodes = [
        {name: 'Foo', path: 'Foo.html', children: [
          {name: '<Leaf>', path: 'Foo/Leaf.html', children: []}
        ]},
        {name: 'FooBar', path: null, children: [
          {name: 'Child', path: 'FooBar/Child.html', children: []}
        ]}
      ];
    JS
    @context.eval File.read(File.expand_path('../../../../lib/rdoc/generator/template/aliki/js/navigation.js', __dir__))
  end

  def teardown
    @context.dispose
  end

  def test_all_branches_are_rendered_before_opening
    @context.eval "buildClassNavigation(container, nodes, '../')"
    assert_equal ['ul', 'link-list nav-list'], @context.eval('[container.tag, container.className]')
    assert_equal ['li', 'li'], @context.eval('container.children.map(child => child.tag)')
    assert_equal [false, false], @context.eval('elements("details").map(branch => branch.open)')
    assert_equal ['Foo', '<Leaf>', 'Child'], @context.eval('elements("a").map(link => link.textContent)')
  end

  def test_rendering_again_replaces_existing_links
    @context.eval "buildClassNavigation(container, nodes, '../')"
    @context.eval "buildClassNavigation(container, nodes, '../../')"
    assert_equal ['../../Foo.html', '../../Foo/Leaf.html', '../../FooBar/Child.html'], @context.eval('elements("a").map(link => link.href)')
  end

  def test_single_root_expands_but_descendants_remain_closed
    @context.eval <<~JS
      buildClassNavigation(container, [
        {name: 'Root', path: 'Root.html', children: nodes}
      ], './');
    JS
    assert_equal [true, false, false], @context.eval('elements("details").map(branch => branch.open)')
    assert_equal ['Root', 'Foo', '<Leaf>', 'Child'], @context.eval('elements("a").map(link => link.textContent)')
  end

  def test_tree_from_search_index_synthesizes_unlinked_ancestors
    @context.eval <<~JS
      const index = [
        {type: 'class', full_name: 'Hidden::Middle::Leaf', path: 'Hidden/Middle/Leaf.html'},
        {type: 'instance_method', full_name: 'Hidden::Middle::Leaf#call', path: 'Hidden/Middle/Leaf.html#method-i-call'},
        {type: 'constant', full_name: 'Hidden::Middle::Leaf::VALUE', path: 'Hidden/Middle/Leaf.html'},
        {type: 'module', full_name: 'Visible', path: 'Visible.html'},
        {type: 'class', full_name: 'Visible::Child', path: 'Visible/Child.html'}
      ];
      const tree = buildClassTree(index);
      buildClassNavigation(container, tree, '../');
    JS

    assert_equal ['Hidden', 'Middle', 'Leaf', 'Visible', 'Child'], @context.eval('tree.flatMap(node => [node.name, ...node.children.flatMap(child => [child.name, ...child.children.map(leaf => leaf.name)])])')
    assert_equal ['../Hidden/Middle/Leaf.html', '../Visible.html', '../Visible/Child.html'], @context.eval('elements("a").map(link => link.href)')
  end

  def test_visible_parent_is_linked_even_when_child_appears_first
    @context.eval <<~JS
      const tree = buildClassTree([
        {type: 'class', full_name: 'Parent::Child', path: 'Parent/Child.html'},
        {type: 'module', full_name: 'Parent', path: 'Parent.html'}
      ]);
    JS

    assert_equal 'Parent.html', @context.eval('tree[0].path')
    assert_equal 'Parent/Child.html', @context.eval('tree[0].children[0].path')
  end

  def test_navigation_initializes_from_loaded_search_data
    @context.eval <<~JS
      var search_data = {index: [
        {type: 'class', full_name: 'Root::Child', path: 'Root/Child.html'}
      ]};
      var index_rel_prefix = '../';
      document.listeners.DOMContentLoaded();
    JS

    assert_equal ['../Root/Child.html'], @context.eval('elements("a").map(link => link.href)')
    assert_equal ['Root'], @context.eval('elements("code").filter(code => code.textContent).map(code => code.textContent)')
  end
end
