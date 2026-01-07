# \RDoc Documents

The term _\RDoc_ _document_ refers to one of these:

- Content of comments in Ruby or C code files
  containing \RDoc markup.
- Content of an entire free-standing documentation file.

Only \RDoc documents are processed by \RDoc;
other comments and files are not processed.

## Document in Comments

An \RDoc document may reside in one or more comments
in Ruby or C code files.

Such a comment is all or part of an \RDoc document
only if it immediately precedes the code that defines
a class, module, method, alias, attribute, or constant.

In Ruby code, if there is more than one declaration of a class or module,
each declaration may have a preceding comment;
in that case, each such comment becomes part of the documentation
for the class or module.

Output:

- The documentation for a class or module
  is included in the documentation for that class or module.
- The documentation for a method, alias, attribute, or constant
  is included in the documentation for the parent class or module.

Example:

```
# This is documentation for class MyClass.
#
# The documentation may contain blank lines
# within the multi-line comment.
class MyClass; end

# This is more documentation for class MyClass.
# This and the comment above are both included in the documentation.
class MyClass

  # This is documentation for attribute my_attribute.
  attr_accessor :my_attribute

  # This is documetation for constant MY_CONSTANT.
  MY_CONSTANT = 'My constant'

  # This is documentation for method :my_method.
  def my_method; end

  # This is documentation for alias :my_alias
  alias my_alias my_method

end

# This is not documentation for anything;
# it does not immediately precede a code definition.

# This is documentation for module MyModule.
module MyModule; end
```

In Ruby code, the comment may be a single-line comment
or a multi-line comment;
both usages appear in the example above.

In C code, the comment may be a single-line comment
or a multi-line comment:

```
/* Single-line comment. */
/*
 * Multi-line
 * comment.
 */
```

In C code, the comment must precede the actual definition,
not its declaration.

```
/* This is not part of the documentation. */
void myFunction();

/* This is part of the documentation. */
void myFunction() {
  printf("I just got executed!");
}
```

## Document in File

An \RDoc document may reside in a stand-alone text file.
\RDoc reads the entire file,
and writes its documentation into a stand-alone HTML file.

The assumed \RDoc format depends on the file extension:

- `.md`: `markdown`; see RDoc::Markdown.
- `.rd`: `rd`; see {RD Working Draft}[https://github.com/uwabami/rdtool/blob/master/doc/rd-draft.rd].
- `.rdoc` or anything else: `rdoc`: see RDoc::MarkupReference.

The output filename also depends on the file extension:

- Input file `foo.md` becomes output file `foo_md.html`.
- Input file `foo.rd` becomes output file `foo_rd.html`.
- Input file `foo.rdoc` becomes output file `foo_foo.html`.
- For any other extension _ext_,
  input file <tt>foo.<i>ext</i></tt> becomes output file <tt>foo_<i>ext</i>.html</tt>.

