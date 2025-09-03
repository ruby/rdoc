# \RDoc Sources

\RDoc derives Ruby documentation from files
that are selected by \RDoc defaults and by user specifications.

\RDoc reads files and directories specified as arguments on the `rdoc` command line;
if no arguments are given, reads files and directories starting in `'.'`
the current working directory.

When anq argument is:

- A file path: \RDoc reads the file.
- A directory path:
  \RDoc (by default) recursively reads all files and directories in the directory tree.
  You can restrict the files and directories to be read;
  see [Document-Control Files][document-control files].

## File Types

Based on the file extension of a file name,
\RDoc assumes its content to be one of these:

- `.rb`, `.rbw`: Ruby code.
- `.c`, `.h`, `.C`, `.H`: C code.
- `.rdoc`: Text file in `rdoc` (markup) format.
- `.md`: Text file in `markdown` format.
- `.rd`: Text file in `rd` format.
- _Anything else_: Text file in `rdoc` (markup) format.

In Ruby or C code, some documentation is derived from the code itself.

Additional documentation may be derived from the text in comments;
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

## Document-Control Files

A directory may have a document-control file, named `.document`.

- If a directory _does not_ have document-control file,
  \RDoc reads all its files and subdirectories.
- If directory _does have_ a document-control file,
  \RDoc reads only the files and subdirectories specified there.

The format of the document-control file is simple:

- Each line may contain a _pattern_, which may be:

    - A file path; e.g., `foo.rb`, `lib/bar.rb`.
    - A directory path; e.g., `subdir`, `subdir/subsubdir`.
    - A file glob; e.g., `*.rb`, `C*`, `lib/*.rb`.

- A line may contain only one pattern (no whitespace- or comma-separated multiple patterns).
- A pattern may be followed (on the same line) by a comment (beginning with `'#'`).
- An entire line may be a comment (beginning with `'#'`).
- A line may be blank (empty).

Each directory in the filetree may (or may not) contain a document-control file.

Note that a document-control file in a subdirectory is read _after_ document-control files
in directories above it;
therefore if file `parent/.document` specifies `child/foo.rb`,
then `child/foo.rb` is read regardless of the content of `child/.document`.

[document-control files]: rdoc-ref:rdoc_sources.md@Document-Control+Files
[directive markup]: https://ruby.github.io/rdoc/RDoc/MarkupReference.html#class-RDoc::MarkupReference-label-3Amarkup-3A
[rd working draft]: https://github.com/uwabami/rdtool/blob/master/doc/rd-draft.rd
[tomdoc for ruby]: http://tomdoc.org
