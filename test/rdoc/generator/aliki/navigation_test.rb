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
          this.attributes = {};
          this.listeners = {};
        }
        appendChild(child) { this.children.push(child); }
        replaceChildren(child) { this.children = [child]; }
        setAttribute(key, value) { this.attributes[key] = value; }
        addEventListener(event, callback) { this.listeners[event] = callback; }
        set innerHTML(value) { throw new Error('Navigation must use textContent'); }
      }
      const container = new Element('div');
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
        {name: 'Foo', full_name: 'Foo', path: 'Foo.html', children: [
          {name: '<Leaf>', full_name: 'Foo::Leaf', path: 'Foo/Leaf.html', children: []}
        ]},
        {name: 'FooBar', full_name: 'FooBar', path: null, children: [
          {name: 'Child', full_name: 'FooBar::Child', path: 'FooBar/Child.html', children: []}
        ]}
      ];
    JS
    @context.eval File.read(File.expand_path('../../../../lib/rdoc/generator/template/aliki/js/navigation.js', __dir__))
  end

  def teardown
    @context.dispose
  end

  def test_unopened_branches_are_lazy_and_only_populated_once
    @context.eval "buildClassNavigation(container, nodes, '../', '')"
    assert_equal ['Foo'], @context.eval('elements("a").map(link => link.textContent)')
    @context.eval 'const branch = elements("details")[0]; branch.open = true; branch.listeners.toggle()'
    assert_equal ['Foo', '<Leaf>'], @context.eval('elements("a").map(link => link.textContent)')
    @context.eval 'branch.open = false; branch.listeners.toggle(); branch.open = true; branch.listeners.toggle()'
    assert_equal 2, @context.eval('elements("a").length')
  end

  def test_current_namespace_opens_without_matching_similar_prefixes
    @context.eval "buildClassNavigation(container, nodes, '../../', 'FooBar::Child')"
    assert_equal [false, true], @context.eval('elements("details").map(branch => branch.open)')
    assert_equal ['../../Foo.html', '../../FooBar/Child.html'], @context.eval('elements("a").map(link => link.href)')
    assert_equal ['page'], @context.eval('elements("a").map(link => link.attributes["aria-current"]).filter(Boolean)')
  end

  def test_single_root_expands_but_grandchildren_remain_lazy
    @context.eval <<~JS
      buildClassNavigation(container, [
        {name: 'Root', full_name: 'Root', path: 'Root.html', children: nodes}
      ], './', '');
    JS
    assert_equal [true, false, false], @context.eval('elements("details").map(branch => branch.open)')
    assert_equal ['Root', 'Foo'], @context.eval('elements("a").map(link => link.textContent)')
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
      buildClassNavigation(container, tree, '../', 'Hidden::Middle::Leaf');
    JS

    assert_equal ['Hidden', 'Middle', 'Leaf', 'Visible', 'Child'], @context.eval('tree.flatMap(node => [node.name, ...node.children.flatMap(child => [child.name, ...child.children.map(leaf => leaf.name)])])')
    assert_equal ['../Hidden/Middle/Leaf.html', '../Visible.html'], @context.eval('elements("a").map(link => link.href)')
    assert_equal ['page'], @context.eval('elements("a").map(link => link.attributes["aria-current"]).filter(Boolean)')
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
      container.dataset = {currentClass: 'Root::Child'};
      document.listeners.DOMContentLoaded();
    JS

    assert_equal ['../Root/Child.html'], @context.eval('elements("a").map(link => link.href)')
    assert_equal ['Root'], @context.eval('elements("code").filter(code => code.textContent).map(code => code.textContent)')
  end
end
