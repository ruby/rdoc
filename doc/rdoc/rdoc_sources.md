# \RDoc Sources

\RDoc derives Ruby documentation from files
that are selected by \RDoc defaults and by user specifications.

\RDoc reads files and directories specified as arguments
on the `rdoc` command line;
if no arguments are given, \RDoc reads `'.'` (the current working directory):

- For each given file path \RDoc reads the file.
- For each given directory path,
  \RDoc (by default) recursively reads all directories and files in the directory tree.
  You can restrict the and directories and files to be read by creating
  [.document files][document files].

## File Types

Based on the file extension of a file name,
\RDoc assumes its content to be one of these:

- `.rb`: Ruby code.
- `.c`, `.h`, `.C`, `.H`: C code.
- `.rdoc`: Text file in `rdoc` (markup) format.
- `.md`: Text file in `markdown` format.
- `.rd`: Text file in `rd` format.

In Ruby or C code, documentation is derived from the code itself,
and may also be derived from the text of comments;
that text may be in any of these formats
(see [directive :markup:][directive markup]).

- `rdoc` (markup);
  see RDoc::MarkupReference.
- `markdown`;
  see RDoc::Markdown.
- `rd`;
  see [RD Working Draft][rd working draft].
- `tomdoc`;
  see [Tomdoc for Ruby][tomdoc for ruby].

## `.document` Files

When \RDoc reads a directory,
it first looks for a file named `.document`:

- If the file does not exist,
  \RDoc reads all files in the directory,
  and reads its subdirectories.
- It the file exists,
  \RDoc reads only the files and subdirectories specified there.

The format of the `.document` file is simple:

- Each line may contain a _pattern_, which may be:

    - A file path.
    - A directory path.
    - A file glob, such as `*.rb` or `C*`.

- A line may contain only one pattern (no whitespace- or comma-separated multiple patterns).
- A pattern may be followed (on the same line) by a comment (beginning with `'#'`).
- An entire line may be a comment (beginning with `'#'`).
- A line may be blank (empty).

Any directory in the filetree may contain a `.document`file.

[document files]: rdoc-ref:rdoc_sources.md@.document+Files
[directive markup]: https://ruby.github.io/rdoc/RDoc/MarkupReference.html#class-RDoc::MarkupReference-label-3Amarkup-3A
[rd working draft]: https://github.com/uwabami/rdtool/blob/master/doc/rd-draft.rd
[tomdoc for ruby]: http://tomdoc.org
