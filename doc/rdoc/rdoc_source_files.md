## \RDoc Source Files

When generating documentation, `rdoc` reads source code and text from selected files.

The files selected are based on `rdoc`
[command-line arguments](rdoc-ref:doc/rdoc/rdoc_source_files.md@Command-Line+Arguments)
and [command-line options](rdoc-ref:doc/rdoc/rdoc_source_files.md@Command-Line+Options).

### Command-Line Arguments

The `rdoc` command-line arguments specify directories and files that are to be considered.

Examples:

- Argument `.`, the current directory,
  specifies that the current directory is to be searched;
  this is also the default if no argument is given.

- Argument `*` specifies that:

    - Each file in the current working directory is to be considered for inclusion.
    - Each directory in the current working directory is to be considered for (recursive) searching.

- Argument `*.rb` specifies that all Ruby files in the current directory tree
  are to be considered for inclusion.

- Argument `rdoc` specifies that all directories and files in each directory named `rdoc`
  are to be considered for inclusion.

Although arguments may specify any directories and files,
specifying a directory or file outside of the current directory tree
may yield surprising results.

### Unconditional Exclusions

Certain directories and files are *always* excluded from consideration:

- Each directory named `CVS`, `.svn`, or `.git`.
- Each file whose name *ends with* (regardless of case)
  `.class`, `.eps`, `.erb`, `.scpt.txt`, `.svg`, `.ttf`, or `.yml`.
- Each file whose name *ends with* (regardless of case)
  `tags`, if its content shows that it is a `vi` tags file.

### Default Exclusions

Certain other directories and files are by default excluded from consideration:

- Each directory named `spec` or `test`.
  This default may be overridden;
  see [Option \\--no-skipping-tests](rdoc-ref:doc/rdoc/rdoc_source_files.md@Option+--no-skipping-tests).
- Each directory or file whose name *starts with* `.`.

### Further Refinements

The collections of directories to be searched and files to be read
may be further refined by:

- [Option \\--exclude](rdoc-ref:doc/rdoc/rdoc_source_files.md@Option+--exclude).
- [.document files](rdoc-ref:doc/rdoc/rdoc_source_files.md@.document+Files).

### Files to Be Read

The initial set of files to be read
includes each file whose path is given as a command-line argument,
but is not otherwise excluded by
[unconditional exclusions](rdoc-ref:doc/rdoc/rdoc_source_files.md@Unconditional+Exclusions),
[default exclusions](rdoc-ref:doc/rdoc/rdoc_source_files.md@Default+Exclusions),
or [further refinements](rdoc-ref:doc/rdoc/rdoc_source_files.md@Further+Refinements)
described above.

As directories are searched, additional files may be added to that set,
but only those that are not excluded (as above).

The final such set is non-redundant,
so that no file is read more than once.

### Directories to Be Searched

The initial set of directories to be searched
includes each directory whose path is given as a command-line argument,
but is not otherwise excluded by
[unconditional exclusions](rdoc-ref:doc/rdoc/rdoc_source_files.md@Unconditional+Exclusions),
[default exclusions](rdoc-ref:doc/rdoc/rdoc_source_files.md@Default+Exclusions),
or [further refinements](rdoc-ref:doc/rdoc/rdoc_source_files.md@Further+Refinements)
described above.

As directories are searched, additional directories may be added to that set,
but only those that are not excluded (as above).

The final such set is non-redundant,
so that no directory is searched more than once.

Each directory to be searched is recursively traversed
[breadth-first](https://en.wikipedia.org/wiki/Breadth-first_search).

In each searched directory:

- Each non-excluded file is added to the set of files to be read.
- Each non-excluded directory is added to the set of directories to be searched.

### `.document` Files

File selection is also affected by the contents of files named `.document`,
which may be anywhere in the searched directory trees;
if there are no such files,
defaults are in effect as above.

#### Comments

Note that in a `.document` file, the character `#` in a line
marks that character and all characters after it to end-of-line as a comment;
the comment has no effect on file selection.

#### Content

Excluding its comments,
a `.document` file consists of whitespace separated strings,
each of which indicates files or directories to be included for consideration;
for clarity, it's good to put each such string on a separate line.

Each such string is converted to a Regexp,
which is matched to each entry in each searche directory;
for each matching entry:

- If the entry is a file, it is added to the files to be read.
- If it is a directory, it is added to the directories to be searched.

Example: contents of file `.document` in the \RDoc root directory:

```
*.md   # Include all .md files.
*.rdoc # Include all .rdoc files.
lib    # Recursively search directory lib/.
doc    # Recursively search directory doc/.
```

**Note well:** If the effective `.document` file is empty,
*all* files and directories in its directory tree are excluded.

#### Scope

A file named `.document` affects file selection in the directory tree at its own directory,
but may be "overridden" by other files named `.document` lower in that directory tree.

Each directory throughout the directory tree has just one controlling `.document` file:
the nearest such file in the chain of *ancestor* directories.

### Command-Line Options

This section describes only those options that affect `rdoc` file selection;
for other options, see the help text (by typing `rdoc --help`).

#### Option `--exclude`

Command-line option `--exclude` specifies a string that is converted to a Regexp;
each matching entry in each searched directory is excluded from consideration.

This option may be given more than once.

#### Option `--no-skipping-tests`

Command-line option `--no-skipping-tests` specifies that directories named `test` or `spec`
are not automatically excluded;
note, though, that to include local directory `test` or `spec`,
the name must be given as an argument:

```
$ rdoc                                # Excludes every directory named test or spec.
$ rdoc --no-skipping-tests            # Includes nested directories named test or spec,
                                      # but not local directories named test or spec.
$ rdoc --no-skipping-tests  test spec # Include all directories named test and spec.
```
