# frozen_string_literal: true

require_relative '../../helper'

return if RUBY_DESCRIPTION =~ /truffleruby/ || RUBY_DESCRIPTION =~ /jruby/

begin
  require 'mini_racer'
rescue LoadError
  return
end

class RDocGeneratorAlikiHighlightCTest < Test::Unit::TestCase
  HIGHLIGHT_C_JS_PATH = ::File.expand_path(
    '../../../../lib/rdoc/generator/template/aliki/js/c_highlighter.js',
    __dir__
  )

  HIGHLIGHT_C_JS = begin
    highlight_c_js = ::File.read(HIGHLIGHT_C_JS_PATH)

    # We need to modify the JS slightly to make it work in the context of a test.
    highlight_c_js.gsub(
      /\(function\(\) \{[\s\S]*'use strict';/,
      "// Test wrapper\n"
    ).gsub(
      /if \(document\.readyState[\s\S]*\}\)\(\);/,
      "// Removed DOM initialization for testing"
    )
  end.freeze

  def setup
    @context = MiniRacer::Context.new
    @context.eval(HIGHLIGHT_C_JS)
  end

  def teardown
    @context.dispose
  end

  def test_keywords
    result = highlight('int main() { return 0; }')

    assert_includes result, '<span class="c-type">int</span>'
    assert_includes result, '<span class="c-keyword">return</span>'
  end

  def test_identifiers
    result = highlight('int x = 5; char *name;')

    assert_includes result, '<span class="c-identifier">x</span>'
    assert_includes result, '<span class="c-identifier">name</span>'
  end

  def test_operators
    result = highlight('a == b && c != d')

    assert_includes result, '<span class="c-operator">==</span>'
    assert_includes result, '<span class="c-operator">&amp;&amp;</span>'
    assert_includes result, '<span class="c-operator">!=</span>'
  end

  def test_single_char_operators
    result = highlight('a + b - c * d / e')

    assert_includes result, '<span class="c-operator">+</span>'
    assert_includes result, '<span class="c-operator">-</span>'
    assert_includes result, '<span class="c-operator">*</span>'
    assert_includes result, '<span class="c-operator">/</span>'
  end

  def test_preprocessor_directives
    result = highlight("#include <stdio.h>\n#define MAX 100")

    assert_includes result, '<span class="c-preprocessor">#include &lt;stdio.h&gt;</span>'
    assert_includes result, '<span class="c-preprocessor">#define MAX 100</span>'
  end

  def test_preprocessor_with_line_continuation
    result = highlight("#define LONG_MACRO \\\n    value")

    # Preprocessor should capture everything including the line continuation
    assert_includes result, '<span class="c-preprocessor">#define LONG_MACRO \\'
    assert_includes result, '    value</span>'
  end

  def test_single_line_comment
    result = highlight('// This is a comment')

    assert_includes result, '<span class="c-comment">// This is a comment</span>'
  end

  def test_multi_line_comment
    result = highlight('/* Multi\nline\ncomment */')

    assert_includes result, '<span class="c-comment">/* Multi\nline\ncomment */</span>'
  end

  def test_string_literals
    result = highlight('"hello world"')

    assert_includes result, '<span class="c-string">&quot;hello world&quot;</span>'
  end

  def test_string_with_escapes
    result = highlight('"hello \"world\""')

    assert_includes result, '<span class="c-string">&quot;hello \&quot;world\&quot;&quot;</span>'
  end

  def test_character_literals
    result = highlight("'a'")

    assert_includes result, "<span class=\"c-value\">&#39;a&#39;</span>"
  end

  def test_character_literals_with_escapes
    result = highlight("'\\n' '\\\\' '\\''")

    assert_includes result, "<span class=\"c-value\">&#39;\\n&#39;</span>"
    assert_includes result, "<span class=\"c-value\">&#39;\\\\&#39;</span>"
    assert_includes result, "<span class=\"c-value\">&#39;\\&#39;&#39;</span>"
  end

  def test_decimal_numbers
    result = highlight('42 3.14 2.5e10')

    assert_includes result, '<span class="c-value">42</span>'
    assert_includes result, '<span class="c-value">3.14</span>'
    assert_includes result, '<span class="c-value">2.5e10</span>'
  end

  def test_hexadecimal_numbers
    result = highlight('0xFF 0xDEADBEEF')

    assert_includes result, '<span class="c-value">0xFF</span>'
    assert_includes result, '<span class="c-value">0xDEADBEEF</span>'
  end

  def test_octal_numbers
    result = highlight('0755')

    assert_includes result, '<span class="c-value">0755</span>'
  end

  def test_number_suffixes
    result = highlight('42u 3.14f 100L')

    assert_includes result, '<span class="c-value">42u</span>'
    assert_includes result, '<span class="c-value">3.14f</span>'
    assert_includes result, '<span class="c-value">100L</span>'
  end

  def test_html_escaping
    result = highlight('if (x < 5 && y > 10) {}')

    assert_includes result, '&lt;'
    assert_includes result, '&gt;'
    assert_includes result, '&amp;&amp;'
  end

  def test_complex_c_code
    code = <<~C
      #include <stdio.h>

      /* Main function */
      int main() {
          char *str = "Hello, World!";
          int x = 0xFF;

          // Print the string
          if (x > 0) {
              printf("%s\\n", str);
          }
          return 0;
      }
    C

    result = highlight(code)

    # Verify key components are highlighted
    assert_includes result, '<span class="c-preprocessor">#include &lt;stdio.h&gt;</span>'
    assert_includes result, '<span class="c-comment">/* Main function */</span>'
    assert_includes result, '<span class="c-type">int</span>'
    assert_includes result, '<span class="c-type">char</span>'
    assert_includes result, '<span class="c-keyword">return</span>'
    assert_includes result, '<span class="c-function">main</span>'
    assert_includes result, '<span class="c-function">printf</span>'
    assert_includes result, '<span class="c-string">&quot;Hello, World!&quot;</span>'
    assert_includes result, '<span class="c-value">0xFF</span>'
    assert_includes result, '<span class="c-value">0</span>'
    assert_includes result, '<span class="c-comment">// Print the string</span>'
  end

  def test_empty_code
    result = highlight('')

    assert_equal '', result
  end

  def test_only_whitespace
    result = highlight("   \n\t  \n  ")

    assert_equal "   \n\t  \n  ", result
  end

  def test_c11_keywords
    result = highlight('_Atomic _Bool _Complex _Thread_local')

    assert_includes result, '<span class="c-type">_Atomic</span>'
    assert_includes result, '<span class="c-type">_Bool</span>'
    assert_includes result, '<span class="c-type">_Complex</span>'
    assert_includes result, '<span class="c-keyword">_Thread_local</span>'
  end

  def test_preprocessor_only_at_line_start
    # # in the middle of code should not be treated as preprocessor
    result = highlight('int x = 5 # 3;')

    refute_includes result, '<span class="c-preprocessor">'
    # The # should be treated as regular text
    assert_includes result, '#'
  end

  def test_typical_function_definition
    code = <<~C
      static VALUE
      rb_ary_all_p(int argc, VALUE *argv, VALUE ary)
      {
          long i;

          for (i = 0; i < RARRAY_LEN(ary); i++) {
              if (!RTEST(RARRAY_AREF(ary, i))) {
                  return Qfalse;
              }
          }
          return Qtrue;
      }
    C

    result = highlight(code)

    # Verify it highlights correctly without errors
    assert_includes result, '<span class="c-keyword">static</span>'
    assert_includes result, '<span class="c-type">VALUE</span>'
    assert_includes result, '<span class="c-function">rb_ary_all_p</span>'
    assert_includes result, '<span class="c-type">int</span>'
    assert_includes result, '<span class="c-type">long</span>'
    assert_includes result, '<span class="c-keyword">for</span>'
    assert_includes result, '<span class="c-keyword">return</span>'
    assert_includes result, '<span class="c-macro">Qtrue</span>'
    assert_includes result, '<span class="c-macro">Qfalse</span>'
    assert_includes result, '<span class="c-macro">RARRAY_LEN</span>'
    assert_includes result, '<span class="c-macro">RTEST</span>'
    assert_includes result, '<span class="c-macro">RARRAY_AREF</span>'
  end

  def test_macros_all_caps
    result = highlight('RARRAY_LEN(ary) ARY_EMBED_P(x) FL_UNSET_EMBED')

    assert_includes result, '<span class="c-macro">RARRAY_LEN</span>'
    assert_includes result, '<span class="c-macro">ARY_EMBED_P</span>'
    assert_includes result, '<span class="c-macro">FL_UNSET_EMBED</span>'
  end

  def test_types_common_ruby_types
    result = highlight('VALUE obj; ID name; size_t len;')

    assert_includes result, '<span class="c-type">VALUE</span>'
    assert_includes result, '<span class="c-type">ID</span>'
    assert_includes result, '<span class="c-type">size_t</span>'
  end

  def test_types_with_t_suffix
    result = highlight('uint32_t count; ssize_t result; ptrdiff_t diff;')

    assert_includes result, '<span class="c-type">uint32_t</span>'
    assert_includes result, '<span class="c-type">ssize_t</span>'
    assert_includes result, '<span class="c-type">ptrdiff_t</span>'
  end

  def test_function_names
    result = highlight('rb_ary_replace(copy, orig); ary_memcpy(dest, src);')

    assert_includes result, '<span class="c-function">rb_ary_replace</span>'
    assert_includes result, '<span class="c-function">ary_memcpy</span>'
  end

  def test_function_definition
    result = highlight('VALUE rb_ary_new(void) {')

    assert_includes result, '<span class="c-type">VALUE</span>'
    assert_includes result, '<span class="c-function">rb_ary_new</span>'
    assert_includes result, '<span class="c-type">void</span>'
  end

  def test_variable_names
    result = highlight('int count = 5; char *ptr = NULL;')

    assert_includes result, '<span class="c-identifier">count</span>'
    assert_includes result, '<span class="c-identifier">ptr</span>'
    assert_includes result, '<span class="c-macro">NULL</span>'
  end

  def test_mixed_identifiers_in_expression
    result = highlight('if (ARY_EMBED_P(ary) && len > 0)')

    assert_includes result, '<span class="c-macro">ARY_EMBED_P</span>'
    assert_includes result, '<span class="c-identifier">ary</span>'
    assert_includes result, '<span class="c-identifier">len</span>'
  end

  def test_macro_vs_function_distinction
    # Macros are ALL_CAPS, functions are not
    result = highlight('RARRAY_LEN(ary) vs ary_length(ary)')

    assert_includes result, '<span class="c-macro">RARRAY_LEN</span>'
    assert_includes result, '<span class="c-function">ary_length</span>'
  end

  private

  def highlight(code)
    @context.eval("highlightC(#{code.to_json})")
  end
end
