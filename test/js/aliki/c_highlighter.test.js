'use strict';

const { test } = require('node:test');
const { assert, assertIncludes, refuteIncludes, loadHighlighter } = require('../helper');

const highlight = loadHighlighter('aliki/js/c_highlighter.js');

test('keywords', () => {
  const result = highlight('int main() { return 0; }');

  assertIncludes(result, '<span class="c-type">int</span>');
  assertIncludes(result, '<span class="c-keyword">return</span>');
});

test('identifiers', () => {
  const result = highlight('int x = 5; char *name;');

  assertIncludes(result, '<span class="c-identifier">x</span>');
  assertIncludes(result, '<span class="c-identifier">name</span>');
});

test('operators', () => {
  const result = highlight('a == b && c != d');

  assertIncludes(result, '<span class="c-operator">==</span>');
  assertIncludes(result, '<span class="c-operator">&amp;&amp;</span>');
  assertIncludes(result, '<span class="c-operator">!=</span>');
});

test('single char operators', () => {
  const result = highlight('a + b - c * d / e');

  assertIncludes(result, '<span class="c-operator">+</span>');
  assertIncludes(result, '<span class="c-operator">-</span>');
  assertIncludes(result, '<span class="c-operator">*</span>');
  assertIncludes(result, '<span class="c-operator">/</span>');
});

test('preprocessor directives', () => {
  const result = highlight('#include <stdio.h>\n#define MAX 100');

  assertIncludes(result, '<span class="c-preprocessor">#include &lt;stdio.h&gt;</span>');
  assertIncludes(result, '<span class="c-preprocessor">#define MAX 100</span>');
});

test('preprocessor with line continuation', () => {
  const result = highlight('#define LONG_MACRO \\\n    value');

  // Preprocessor should capture everything including the line continuation
  assertIncludes(result, '<span class="c-preprocessor">#define LONG_MACRO \\');
  assertIncludes(result, '    value</span>');
});

test('single line comment', () => {
  const result = highlight('// This is a comment');

  assertIncludes(result, '<span class="c-comment">// This is a comment</span>');
});

test('multi line comment', () => {
  const result = highlight('/* Multi\\nline\\ncomment */');

  assertIncludes(result, '<span class="c-comment">/* Multi\\nline\\ncomment */</span>');
});

test('string literals', () => {
  const result = highlight('"hello world"');

  assertIncludes(result, '<span class="c-string">&quot;hello world&quot;</span>');
});

test('string with escapes', () => {
  const result = highlight('"hello \\"world\\""');

  assertIncludes(result, '<span class="c-string">&quot;hello \\&quot;world\\&quot;&quot;</span>');
});

test('character literals', () => {
  const result = highlight("'a'");

  assertIncludes(result, '<span class="c-value">&#39;a&#39;</span>');
});

test('character literals with escapes', () => {
  const result = highlight("'\\n' '\\\\' '\\''");

  assertIncludes(result, '<span class="c-value">&#39;\\n&#39;</span>');
  assertIncludes(result, '<span class="c-value">&#39;\\\\&#39;</span>');
  assertIncludes(result, '<span class="c-value">&#39;\\&#39;&#39;</span>');
});

test('decimal numbers', () => {
  const result = highlight('42 3.14 2.5e10');

  assertIncludes(result, '<span class="c-value">42</span>');
  assertIncludes(result, '<span class="c-value">3.14</span>');
  assertIncludes(result, '<span class="c-value">2.5e10</span>');
});

test('hexadecimal numbers', () => {
  const result = highlight('0xFF 0xDEADBEEF');

  assertIncludes(result, '<span class="c-value">0xFF</span>');
  assertIncludes(result, '<span class="c-value">0xDEADBEEF</span>');
});

test('octal numbers', () => {
  const result = highlight('0755');

  assertIncludes(result, '<span class="c-value">0755</span>');
});

test('number suffixes', () => {
  const result = highlight('42u 3.14f 100L');

  assertIncludes(result, '<span class="c-value">42u</span>');
  assertIncludes(result, '<span class="c-value">3.14f</span>');
  assertIncludes(result, '<span class="c-value">100L</span>');
});

test('html escaping', () => {
  const result = highlight('if (x < 5 && y > 10) {}');

  assertIncludes(result, '&lt;');
  assertIncludes(result, '&gt;');
  assertIncludes(result, '&amp;&amp;');
});

test('complex c code', () => {
  const code = `#include <stdio.h>

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
`;

  const result = highlight(code);

  // Verify key components are highlighted
  assertIncludes(result, '<span class="c-preprocessor">#include &lt;stdio.h&gt;</span>');
  assertIncludes(result, '<span class="c-comment">/* Main function */</span>');
  assertIncludes(result, '<span class="c-type">int</span>');
  assertIncludes(result, '<span class="c-type">char</span>');
  assertIncludes(result, '<span class="c-keyword">return</span>');
  assertIncludes(result, '<span class="c-function">main</span>');
  assertIncludes(result, '<span class="c-function">printf</span>');
  assertIncludes(result, '<span class="c-string">&quot;Hello, World!&quot;</span>');
  assertIncludes(result, '<span class="c-value">0xFF</span>');
  assertIncludes(result, '<span class="c-value">0</span>');
  assertIncludes(result, '<span class="c-comment">// Print the string</span>');
});

test('empty code', () => {
  const result = highlight('');

  assert.equal(result, '');
});

test('only whitespace', () => {
  const result = highlight('   \n\t  \n  ');

  assert.equal(result, '   \n\t  \n  ');
});

test('c11 keywords', () => {
  const result = highlight('_Atomic _Bool _Complex _Thread_local');

  assertIncludes(result, '<span class="c-type">_Atomic</span>');
  assertIncludes(result, '<span class="c-type">_Bool</span>');
  assertIncludes(result, '<span class="c-type">_Complex</span>');
  assertIncludes(result, '<span class="c-keyword">_Thread_local</span>');
});

test('preprocessor only at line start', () => {
  // # in the middle of code should not be treated as preprocessor
  const result = highlight('int x = 5 # 3;');

  refuteIncludes(result, '<span class="c-preprocessor">');
  // The # should be treated as regular text
  assertIncludes(result, '#');
});

test('typical function definition', () => {
  const code = `static VALUE
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
`;

  const result = highlight(code);

  // Verify it highlights correctly without errors
  assertIncludes(result, '<span class="c-keyword">static</span>');
  assertIncludes(result, '<span class="c-type">VALUE</span>');
  assertIncludes(result, '<span class="c-function">rb_ary_all_p</span>');
  assertIncludes(result, '<span class="c-type">int</span>');
  assertIncludes(result, '<span class="c-type">long</span>');
  assertIncludes(result, '<span class="c-keyword">for</span>');
  assertIncludes(result, '<span class="c-keyword">return</span>');
  assertIncludes(result, '<span class="c-macro">Qtrue</span>');
  assertIncludes(result, '<span class="c-macro">Qfalse</span>');
  assertIncludes(result, '<span class="c-macro">RARRAY_LEN</span>');
  assertIncludes(result, '<span class="c-macro">RTEST</span>');
  assertIncludes(result, '<span class="c-macro">RARRAY_AREF</span>');
});

test('macros all caps', () => {
  const result = highlight('RARRAY_LEN(ary) ARY_EMBED_P(x) FL_UNSET_EMBED');

  assertIncludes(result, '<span class="c-macro">RARRAY_LEN</span>');
  assertIncludes(result, '<span class="c-macro">ARY_EMBED_P</span>');
  assertIncludes(result, '<span class="c-macro">FL_UNSET_EMBED</span>');
});

test('types common ruby types', () => {
  const result = highlight('VALUE obj; ID name; size_t len;');

  assertIncludes(result, '<span class="c-type">VALUE</span>');
  assertIncludes(result, '<span class="c-type">ID</span>');
  assertIncludes(result, '<span class="c-type">size_t</span>');
});

test('types with t suffix', () => {
  const result = highlight('uint32_t count; ssize_t result; ptrdiff_t diff;');

  assertIncludes(result, '<span class="c-type">uint32_t</span>');
  assertIncludes(result, '<span class="c-type">ssize_t</span>');
  assertIncludes(result, '<span class="c-type">ptrdiff_t</span>');
});

test('function names', () => {
  const result = highlight('rb_ary_replace(copy, orig); ary_memcpy(dest, src);');

  assertIncludes(result, '<span class="c-function">rb_ary_replace</span>');
  assertIncludes(result, '<span class="c-function">ary_memcpy</span>');
});

test('function definition', () => {
  const result = highlight('VALUE rb_ary_new(void) {');

  assertIncludes(result, '<span class="c-type">VALUE</span>');
  assertIncludes(result, '<span class="c-function">rb_ary_new</span>');
  assertIncludes(result, '<span class="c-type">void</span>');
});

test('variable names', () => {
  const result = highlight('int count = 5; char *ptr = NULL;');

  assertIncludes(result, '<span class="c-identifier">count</span>');
  assertIncludes(result, '<span class="c-identifier">ptr</span>');
  assertIncludes(result, '<span class="c-macro">NULL</span>');
});

test('mixed identifiers in expression', () => {
  const result = highlight('if (ARY_EMBED_P(ary) && len > 0)');

  assertIncludes(result, '<span class="c-macro">ARY_EMBED_P</span>');
  assertIncludes(result, '<span class="c-identifier">ary</span>');
  assertIncludes(result, '<span class="c-identifier">len</span>');
});

test('macro vs function distinction', () => {
  // Macros are ALL_CAPS, functions are not
  const result = highlight('RARRAY_LEN(ary) vs ary_length(ary)');

  assertIncludes(result, '<span class="c-macro">RARRAY_LEN</span>');
  assertIncludes(result, '<span class="c-function">ary_length</span>');
});
