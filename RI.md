# `ri` (Ruby Information)

`ri` is the Ruby command-line utility
that gives fast and easy on-line access to Ruby documentation.

Example (the pipe to `head` restricts output to leading lines):

```sh
$ ri Array | head
= Array < Object

------------------------------------------------------------------------
= Includes:
Enumerable (from ruby core)

(from ruby core)
------------------------------------------------------------------------
An Array is an ordered, integer-indexed collection of objects, called
elements.  Any object may be an Array element.
```

## Why `ri`?

Using `ri` may have advantages over using
the {Ruby online documentation}[https://docs.ruby-lang.org/en/master]:

- The `ri` documentation is always available, even when you do not have internet access
  (think: airplane mode).
- If you are working in a terminal window, typing `ri _whatever_` (or just `ri`)
  may be faster than navigating to a browser window and searching for documentation.
- If you are working in an
  {irb (interactive Ruby)}[https://docs.ruby-lang.org/en/master/IRB.html]
  session, you _already_ have immediate access to `ri`:
  just type `'help'` or `'show_doc'`.

## About the Examples

- `ri` output can be large,
  and so here we sometimes pipe the output to one of these:

    - {head}[https://www.man7.org/linux/man-pages/man1/head.1.html]: leading lines only.
    - {tail}[https://www.man7.org/linux/man-pages/man1/tail.1.html]: trailing lines only.
    - {wc -l}[https://www.man7.org/linux/man-pages/man1/wc.1.html]: line count only.

  - Examples that involve the `ri` environment variables `RI` or `RI_PAGER`
    may use the shell idiom `_env_name_="_env_value_"`
    to define an environment variable on the command line:

    ```sh
    $ RI="--all --no-gems" ruby -e "p ENV['RI']"
    "--all --no-gems"
    $ RI_PAGER="grep . | less" ruby -e "p ENV['RI_PAGER']"
    "grep . | less"
    ```

- Examples that involve gems assume that gem `nokogiri` is installed.

## `ri` Documents

With `ri`, you can quickly access documents on-line for:

  - Ruby (core and standard library):

    - Class or module (e.g., `Array` or `Enumerable`).
    - Singleton or instance method (e.g., `IO::readlines` or `IO#readlines`).
    - Page (e.g., `ruby:dig_methods`).

  - Gems:
.
    - Class or module (e.g., `Nokogiri::HMTL4::Document` or `Nokogiri`).
    - Singleton or instance method
      (e.g., `Nokogiri::HTML4::Document::parse` or `Nokogiri::HTML4::Document#fragment`).
    - Page (e.g., `nokogiri:README`).

Examples:

- Document for class `Array`:

    ```sh
    $ ri Array | head
    = Array < Object
    
    ------------------------------------------------------------------------
    = Includes:
    Enumerable (from ruby core)
    
    (from ruby core)
    ------------------------------------------------------------------------
    An Array is an ordered, integer-indexed collection of objects, called
    elements.  Any object (even another array) may be an array element.
    ```

- Document for singleton method `IO::readlines`:

    ```sh
    $ ri IO::readlines | head
    = IO::readlines
    
    (from ruby core)
    ------------------------------------------------------------------------
    IO.readlines(name, sep=$/ [, getline_args, open_args])     -> array
    IO.readlines(name, limit [, getline_args, open_args])      -> array
    IO.readlines(name, sep, limit [, getline_args, open_args]) -> array
    
    ------------------------------------------------------------------------
    
    ```

- Document for instance method `IO#readlines`:

    ```sh
    $ ri IO#readlines | head
    = IO#readlines
    
    (from ruby core)
    ------------------------------------------------------------------------
    ios.readlines(sep=$/ [, getline_args])     -> array
    ios.readlines(limit [, getline_args])      -> array
    ios.readlines(sep, limit [, getline_args]) -> array
    
    ------------------------------------------------------------------------

    ```

- Document for page `ruby:dig_methods`:

    ```sh
    $ ri ruby:dig_methods | head
    = Dig Methods
    
    Ruby's dig methods are useful for accessing nested data structures.
    
    Consider this data:
    item = {
    id: "0001",
    type: "donut",
    name: "Cake",
    ppu: 0.55,
    ```

## Modes

There are two `ri` modes:

- <i>Static mode</i>:
  In general, `ri` responds in its static mode
  if a _name_ is given;
  it prints and exits.
  See {Static Mode}[RI_md.html#label-Static+Mode].
- <i>Interactive mode</i>:
  In general, `ri` enters its interactive mode
  if no _name_ is given;
  in interactive mode, `ri` prints and waits for another command.
  See {Interactive Mode}[RI_md.html#label-Interactive+Mode].

### Pro Tip: Keep `ri` Available

If you are a frequent `ri` user,
you can save time by keeping open a dedicated command window
with either of:

- A running {interactive ri}[rdoc-ref:RI.md@Interactive+Mode] session.
- A running {irb session}[https://docs.ruby-lang.org/en/master/IRB.html];
  type `'help'` or `'show_doc'` to enter `ri`, newline to exit.

When you switch to that window, `ri` is ready to respond quickly, 
without the performance overhead of re-reading `ri` source files.

## Names

In both modes, static and interactive,
`ri` responds to an input _name_ that specifies what is to be printed:
a document, multiple documents, or other information:

- Static mode (in the shell): type `'ri _name_'`;
  examples (output omitted):

    ```sh
    $ ri File
    $ ri IO#readlines
    $ ri ruby:
    ```
  
- Interactive mode (already in `ri`): just type the _name_; 
  examples (output omitted):

    ```sh
    $ ri
    Enter the method name you want to look up.
    You can use tab to autocomplete.
    Enter a blank line to exit.
    >> File
    >> IO#readlines
    >> ruby:
    ```

### Names for Getting Lists

This table summarizes `ri` names for getting lists:

| Name      | Prints                  |
|-----------|-------------------------|
| ruby:     | List of Ruby pages.     |
| nokogiri: | List of Nokogiri pages. |
<br>

There are more lists available;
see {option \\--list}[rdoc-ref:RI.md@-list-2C+-l].

### Names for Getting Documents

These tables summarize `ri` names for getting documents
(for details and examples, follow the links):

- {Ruby classes and modules}[rdoc-ref:RI.md@Ruby+Classes+and+Modules]:

    | Name       | Prints                                                |
    |------------|-------------------------------------------------------|
    | File       | Document for class File.                              |
    | File::Stat | Document for nested class File::Stat.                 |
    | Enumerable | Document for module Enumerable.                       |
    | Arr        | Document for class Array (unique initial characters). |
<br>

    If {option \\--all}[rdoc-ref:RI.md@-all-2C+-a]
    is in effect, documents for the methods in the named class or module
    are also printed.
 
- {Ruby methods}[rdoc-ref:RI.md@Ruby+Methods]:


    | Name                  | Prints                                                                          |
    |-----------------------|---------------------------------------------------------------------------------|
    | IO::readlines         | Document for singleton method IO::readlines.                                    |
    | IO#readlines          | Document for instance method IO::readlines.                                     |
    | IO.readlines          | Documents for instance method IO::readlines and singleton method IO::readlines. |
    | ::readlines           | Documents for all singleton methods ::readlines.                                |
    | #readlines            | Documents for all instance methods #readlines; see note below.                   |
    | .readlines, readlines | Documents for singleton methods ::readlines and instance methods #readlines.    |
<br>

    Note: in static mode, the name on the command line may need escape characters.
    In the table above, `#readlines` on the command line
    may (depending on the shell) need to be escaped as `\#readlines`;
    other escapes may be required for certain other method names.
    See {Escaping Names}[rdoc-ref:RI.md@Escaping+Names].

- {Ruby pages}[rdoc-ref:RI.md@Ruby+Pages]:

    | Name                        | Prints                                                          |
    |-----------------------------|-----------------------------------------------------------------|
    | ruby:security.rdoc          | Document for page security.                                     |
    | ruby:security               | Document for page security (if no other security.*).            |
    | ruby:syntax/assignment.rdoc | Document for page assignment.                                   |
    | ruby:syntax/assignment      | Document for page assignment (if no other syntax/assignment.*). |
    | ruby:assignment             | Document for page assignment (if no other */assignment.*).      |
<br>

- {Gem documents}[rdoc-ref:RI.md@Gem+Documents]:

    | Name                               | Prints                                                                         |
    |------------------------------------|--------------------------------------------------------------------------------|
    | Nokogiri                           | Document for module Nokogiri.                                                  |
    | Nokogiri::CSS                      | Document for class Nokogiri::CSS.                                              |
    | nokogiri:README.md                 | Document for page README.md.                                                   |
    | nokogiri:README                    | Document for page README.md (if no other README.*).                            |
    | Nokogiri::HTML4::Document          | Document for class Nokogiri::HTML4::Document.                                  |
    | Nokogiri::HTML4::Document::parse   | Document for singleton method Nokogiri::HTML4::Document::parse.                |
    | Nokogiri::HTML4::Document#fragment | Document for instance method Nokogiri::HTML4::Document#fragment.               |
<br>

    If {option \\--all}[rdoc-ref:RI.md@-all-2C+-a]
    is in effect, documents for the methods in the named class or module
    are also printed.

## Static Mode

In static mode, `ri` prints a response and exits.

In general, `ri` responds in static mode
if the command gives a _name_:

```sh
$ ri Array | head
= Array < Object

------------------------------------------------------------------------
= Includes:
Enumerable (from ruby core)

(from ruby core)
------------------------------------------------------------------------
An Array is an ordered, integer-indexed collection of objects, called
elements.  Any object may be an Array element.
```

The name may also be given in `$stdin`:

```sh
$ echo "Array" | ri | head

Enter the method name you want to look up.
You can use tab to autocomplete.
Enter a blank line to exit.

= Array < Object

------------------------------------------------------------------------
= Includes:
Enumerable (from ruby core)
```

Despite the message ("Enter ...."), `ri` does not enter its interactive mode. 

`ri` also responds in static mode when certain options are given,
even when no _name_ is given;
these include:

Option –help or -h: Prints ri help text

- {Option \--help or -h}[rdoc-ref:RI.md@-help-2C+-h]:
  Prints `ri` help text.
- {option \\--list or -l}[rdoc-ref:RI.md@-list-2C+-l]:
  Prints list of classes and modules.
- {option \\--list-doc-dirs}[rdoc-ref:RI.md@-list-doc-dirs]:
  Prints list of `ri` source directories.
- {option \\--version or -v}[rdoc-ref:RI.md@-version-2C+-v]:
  Prints `ri` version.

## Interactive Mode

In general, `ri` responds to a command in interactive mode
if the command has no arguments:

```sh
$ ri
Enter the method name you want to look up.
You can use tab to autocomplete.
Enter a blank line to exit.
>> 

```

A command in interactive mode are similar to one in static mode,
except that you:

- Omit command word `ri`; just type the _name_.
- Omit options;  the only options in effect are those found in environment variable `RI`.

## Getting Ruby Documents

### Ruby Classes and Modules

To get the document for a particular class or module,
give its name as the _name_ argument:

For class `File`:

```sh
$ ri File | head
= File < IO

(from ruby core)
------------------------------------------------------------------------
A File is an abstraction of any file object accessible by the program
and is closely associated with class IO.  File includes the methods of
module FileTest as class methods, allowing you to write (for example)
File.exist?("foo").

In the description of File methods, permission_
```
    
For module `File::File::FileConstants`:

```sh
$ ri File::File::Constants | head
= File::File::Constants

(from ruby core)
------------------------------------------------------------------------
Document-module: File::Constants

File::Constants provides file-related constants.  All possible file
constants are listed in the documentation but they may not all be
present on your platform.
```

You can abbreviate a class or module name to unique initial characters:

```sh
$ ri Arr | head -1
= Array < Object
```

If the _name_ is not unique initial characters,
no document is found:

```sh
$ ri A
Nothing known about A
```

To get a list of all classes and modules,
use option `--list` with no _name_:

```sh
$ ri --list | head
ACL
ACL::ACLEntry
ACL::ACLList
ARGF
Abbrev
Addrinfo
ArgumentError
Array
Base64
BasicObject
```

To get a list of classes and modules beginning with a certain substring,
use option `--list` with an argument:

```sh
$ ri --list A | head
ACL
ACL::ACLEntry
ACL::ACLList
ARGF
Abbrev
Addrinfo
ArgumentError
Array

$ ri --list Ar | head
ArgumentError
Array
```

To get the document for a class or module,
together with the documents for all its methods,
use option `--all`:

```sh
$ ri Array | wc -l       # Line count for document Array only.
390
$ ri --all Array | wc -l # Line count for document Array and its method documents.
4224
```

### Ruby Methods

For methods, `ri` can print:

- For a given Ruby class or module:

  - The document for a the singleton method of a given name.
  - The document for a the instance method of a given name.
  - The documents for both the singleton and the instance methods of a given name.

- For all Ruby classes and modules:

  - The documents for all singleton methods of a given name.
  - The documents for all instance methods of a given name.
  - The documents for all singleton and instance methods of a given name.

To get the document for a particular instance method,
give the _name_ in the form `_name_of_class_or_module_#_name_of_method_`:

```sh
$ ri IO#read | head
= IO#read

(from ruby core)
------------------------------------------------------------------------
  ios.read([length [, outbuf]])    -> string, outbuf, or nil

------------------------------------------------------------------------

Reads length bytes from the I/O stream.
```


### Ruby Pages

`ri` handles free-standing _pages_,
each of which presents a document that is not defined within a class or module.

To get a particular page document,
include its name in the argument:

```sh
$ ri ruby:regexp | head
Regular expressions (regexps) are patterns which describe
the contents of a string. They're used for testing whether a string
contains a given pattern, or extracting the portions that match. They
are created with the /pat/ and %r{pat} literals or the
Regexp.new constructor.

A regexp is usually delimited with forward slashes (/). For example:

  /hay/ =~ 'haystack'   #=> 0
  /y/.match('haystack') #=> #<MatchData "y">
  ```

To get a list of the page documents,
give the argument as `ruby:`:

```sh
$ ri ruby: | head
= Pages in ruby core

CONTRIBUTING.md
COPYING
COPYING.ja
LEGAL
NEWS-1.8.7
NEWS-1.9.1
NEWS-1.9.2
NEWS-1.9.3
```

Many of the "boilerplate" pages have names beginning with a capital letter;
other pages typically do not:

```sh
$ ri ruby: | grep "^[a-z]" | head
bug_triaging.rdoc
contributing.rdoc
dig_methods.rdoc
dtrace_probes.rdoc
extension.ja.rdoc
extension.rdoc
fiber.md
globals.rdoc
implicit_conversion.rdoc
keywords.rdoc

$ ri ruby: | grep "^[a-z]" | tail
syntax/control_expressions.rdoc
syntax/exceptions.rdoc
syntax/literals.rdoc
syntax/methods.rdoc
syntax/miscellaneous.rdoc
syntax/modules_and_classes.rdoc
syntax/pattern_matching.rdoc
syntax/precedence.rdoc
syntax/refinements.rdoc
win32/README.win32
```

To get a page:

```sh
$ ri ruby:syntax/exceptions.rdoc | head
= Exception Handling

Exceptions are rescued in a begin/end block:
1
  begin
    # code that might raise
  rescue
    # handle exception
  end
```

If the page name is sufficiently unique,
you can omit leading and trailing elements:
`ruby:exeptions` is the same as `ruby:syntax/exceptions.rdoc`.

## Getting Gem Documents

### Gem Classes and Modules

### Gem Methods

### Gem Pages

### Escaping Names

[TODO]

## Source Files

`ri` derives documentation from files in _local_ directories,
(not from the {Ruby online documentation}[https://docs.ruby-lang.org/en/master]).
To see the source directories on your local machine:

```sh
$ ri --list-doc-dirs
```

These are the directories that `ri` may search, which may or may not actually exist.

## Pager

Because `ri` output is often large,
`ri` by default pipes the output to a _pager_,
which is the program whose name is the first-found among:

- The value of `ENV['RI_PAGER']`.
- The value of `ENV['PAGER']`.
- `'pager'`.
- `'less'`.
- `'more'`.

If none is found, the output goes directly to `$stdout`, with no pager.

If you set environment variable `RI_PAGER` or `PAGER`,
its value should be the name of an executable program
that will accept the `ri` output (such as `'pager'`, `'less'`, or `'more'`).

### Pro Tip: Pager Options

You can set the pager value to a pager program name with options;
this example (which omits output) sets the pager to `'less'`,
with options `'-E'` (quit at EOF) and `'-F'` (quit if one screen):

```sh
RI_PAGER="less -E -F" ri Array
```

See the options for your chosen pager program
(e.g, type `'less --help'`).

### Pro Tip: Pre-Pager Processing

The "pager" value actually need not specify a simple pager program.
You can, for example, set the pager value to `'grep . | less'`,
which will exclude blank lines (thus saving screen space)
before piping output to `less`;
example (output omitted):

```sh
RI_PAGER="grep . | less" ri Array
```

## Options

Options may be given on the `ri` command line;
those should be whitespace-separated, and must precede the given _name_, if any.

Options may also be specified in environment variable `RI`;
those should also be whitespace-separated.

An option specified in environment variable `RI`
may be overridden by an option on the `ri` command line:

```sh
$ RI="--all" ri Array | wc -l
4224
$ RI="--all" ri --no-all Array | wc -l
390
```

### Summary

| Option                   | Effect                                                                            |
|--------------------------|-----------------------------------------------------------------------------------|
| --all, -a                | Print all (class or module plus methods); default is --no-all.                    |
| --doc-dir=_DIRPATH_, -d  | Add directory to ri source directories; may be repeated.                          |
| --dump=FILEPATH          | Print dump of cache file; default is --no-dump.                                   |
| --format=FORMAT, -f      | Set formatter: ansi, bs, markdown, rdoc; default is bs for pager, ansi otherwise. |
| --gems                   | Allow documents from installed gems; default.                                     |
| --help, -h               | Print help message and exit.                                                      |
| --home                   | Allow documents from ~/.rdoc; default.                                            |
| --interactive, -i        | Enter interactive mode; default when no name given.                               |
| --list, -l               | Print list of classes and modules; default is --no-list.                          |
| --list-doc-dirs          | Print list of ri source directories; default is --no-list-doc-dirs.               |
| --no-all                 | Do not print methods for named class or module; default.                          |
| --no-dump                | Do not print dump of cache file; default.                                         |
| --no-gems                | Exclude documents for installed gems; default is --gems.                          |
| --no-home                | Exclude documents from ~/.rdoc; default is --home.                                |
| --no-interactive         | Do not enter interactive mode; default when name given.                           |
| --no-list                | Do not print list; default.                                                       |
| --no-list-doc-dirs       | Do not print list of ri source directories; default;                              |
| --no-pager, -T           | Do not pipe output to pager; default is --pager.                                  |
| --no-profile             | Do not run with Ruby profiler; default.                                           |
| --no-site                | Exclude documents from site libraries; default is --site.                         |
| --no-standard-docs       | Exclude documents from the standard library, etc; default is to include them.     |
| --no-system              | Exclude documents from from system libraries; default is --system.                |
| --pager                  | Pipe output to pager; default.                                                    |
| --profile                | Run with Ruby profiler; default is --no-profile.                                  |
| --server=NUMBER          | Set port for RDoc server; default is 8214.                                        |
| --site                   | Allow documents from site libraries; default.                                     |
| --system                 | Allow documents from from system libraries; default.                              |
| --version, -v            | Print ri version and exit.                                                        |
| --width=NUMBER, -w       | Set width (in characters) for output; default is 80.                              |

### `--all`, `-a`

Option `--all` (aliased as `-a`) specifies that when _name_ identifies a class or module,
the output should include the documents for all its methods:

```shell
$ ri Array | wc -l
390
$ ri --all Array | wc -l
4224
```

The default is `--no-all`.

### `--doc-dir=DIRPATH`, `-d`

Option `--doc-dir=DIRPATH` (aliased as `-d`) adds the given directory path
to the beginning of the array of `ri` source directory paths:

```sh
$ ri --doc-dir=/tmp --list-doc-dirs | head -1
/tmp
```

### `--dump=FILEPATH`

Option `--dump=FILEPATH` specifies that `ri` is to dump the content
of the `.ri` file at the given file path;
the default is `--no-dump`.

The file path may point to any `.ri` file,
but typically would point to one named `cache.ri`:

```sh
$ ri --dump=/usr/share/ri/3.0.0/system/cache.ri | wc -l
14487
$ ri --dump=/usr/share/ri/3.0.0/system/cache.ri | head
{:ancestors=>
  {"Array"=>["Enumerable", "Object"],
   "RubyVM"=>["Object"],
   "RubyVM::AbstractSyntaxTree::Node"=>["Object"],
   "Object"=>["BasicObject", "Kernel"],
   "Integer"=>["Numeric"],
   "Module"=>["Object"],
   "Class"=>["Module"],
   "Complex"=>["Numeric"],
   "NilClass"=>["Object"],
```

### `--format=FORMAT`, `-f`

Option `--format=FORMAT` (aliased as `-f`) specifies the formatter for the output,
which must be `ansi`, `bs`, `markdown`, or `rdoc`;
the default is `bs` for paged output, `ansi` otherwise.

### `--gems`

Option `--gems` (the default) specifies that documents from installed gems
may be included;
option `--no-gems` may be used to exclude them:

```sh
$ ri --list | wc -l
1417
$ ri --list --no-gems| wc -l
1262
```

### `--help`, `-h`

Option `--help` (aliased as `-h`) specifies that `ri` is to print
its help text and exit.

### `--home`

Option `--home` (the default) specifies that `ri` is to include source directory
in `~/.rdoc` if it exists.

### `--interactive`, `-i`

Option `--interactive` (aliased as `-i`)
specifies that `ri` is to enter interactive mode (ignoring the _name_ if given);
the option is the default when no _name_ is given.

### `--list`, `-l`

Option `--list` (aliased as `-l`) specifies that all class and module names
whose initial characters match the given _name_ are to be printed;
the default is `--no-list`:

```sh
$ ri --list Ar | head
ArgumentError
Array
```

If no _name_ is given, all class and module names are printed.

### `--list-doc-dirs`

Option `--list-doc-dirs` specifies that a list of the `ri` source directories
is to be printed;
default is `--no-list-doc-dirs`.

### `--no-all`

Option `--no-all` (the default) specifies that for a given class or module,
its method documents are not to be printed.

### `--no-dump`

Option `--no-dump` (the default) specifies that a cache file is not to be dumped.

### `--no-gems`

Option `--no-gems` specifies that gem documents are not to be printed;
`--gems` is the default.

### `--no-home`

Option `--no-gems` specifies that gem documents from `~/.rdoc` are not to be printed;
`--home` is the default.

### `--no-interactive`

Option `--no-interactive` (the default when _name_ is not given)
specifies that `ir` is not to enter interactive mode,
regardless of whether _name_ is given.

### `--no-list`

Option `--no-list` (the default) specifies that a list of class and module names
is not to be printed.

### `--no-list-doc-dirs`

Option `--no-list-doc-dirs` (the default) specifies that the list of documentation
directories is not to be printed.

### `--no-pager`, `-T`

Option `--no-pager` (aliased as `-T`) specifies that the output is not to be piped
to a pager;
default is `--pager`.

### `--no-profile`

Option `no-profile` (the default) specifies that the program is not to be run
with the Ruby profiler.

### `--no-site`

Option `--no-site` specifies that documents from the site libraries
are not to be printed;
default is `--site`.

### `--no-standard`

Option `--no-standard` specifies that documents from the standard libraries
are not to be printed;
default is to print documents from the standard libraries.

### `--no-system`

Option `--no-system` specifies that documents from the system libraries
are not to be printed;
default is `--system`.

### `--pager`

Option `--pager` (the default) specifies that the output is to be piped
to a pager.

### `--profile`

Option `--profile` specifies that the program is to be run with the Ruby profiler;
default is `--no-profile`.

### `--server=NUMBER`

Option `--server` specifies that the RDoc server is to be run on the port
given as _NUMBER_;
the default port is `8214`.

### `--site`

Option `--site` (the default) specifies that documents from the site libraries
may be included.

### `--system`

Option `--system` (the default) specifies that documents from the system libraries
may be included.

### `--version`, `-v`

Option `--version` (aliased as `-v`) specifies that `ri` is to print its version and exit.

### `--width=NUMBER`

Option `--width` specifies that the output line lengths should be restricted
to the given _NUMBER_ of characters;
this is to be accomplished by line-wrapping, not truncation.
The default width is `80`:

```she\
$ ri --width=40 Array | head
= Array < Object

----------------------------------------
= Includes:
Enumerable (from ruby core)

(from ruby core)
----------------------------------------
An Array is an ordered, integer-indexed
collection of objects, called
```


## Environment Variables


All options also can be specified through the +RI+ environment variable.
Command-line options always override those specified in the +RI+ environment
variable.

The +RI_PAGER+ environment variable allows you to choose a particular pager or
particular options for your pager.

