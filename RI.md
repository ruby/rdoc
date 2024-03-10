# `ri` (Ruby Information)

`ri` gives fast and easy on-line access to Ruby documentation.

## Why `ri`?

Using `ri` may have advantages over using
the {Ruby online documentation}[https://docs.ruby-lang.org/en/master]:

- The `ri` documentation is always available, even when you do not have internet access
  (think, airplane mode).
- If you are working in a terminal window, typing `ri _whatever_` may be faster
  than navigating to a browser window and searching for documentation.
- If you are working
  in {irb (interactive Ruby)}[https://docs.ruby-lang.org/en/master/IRB.html],
  you _already_ have immediate access to `ri`.

## Using `ri`

With `ri`, you can quickly access documents for:

  - Ruby (core and standard library):

    - Class or module (e.g., `Array` or `Enumerable`).
    - Singleton or instance method (e.g., `IO::readlines` or `IO#readlines`).
    - Page (e.g., `ruby:dig_methods`).

  - Gems:

    - Class or module (e.g., `Nokogiri::HMTL4::Document` or `Nokogiri`).
    - Singleton or instance method
      (e.g., `Nokogiri::HTML4::Document::parse` or `Nokogiri::HTML4::Document#fragment`).
    - Page (e.g., `nokogiri:README`).

Examples:

- Document for class {Array}[https://docs.ruby-lang.org/en/master/Array.html]:

    ```sh
    # Use 'head' to get just the first lines.
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

- Document for singleton method {IO::readlines}[https://docs.ruby-lang.org/en/master/IO.html#method-c-readlines]:

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

- Document for instance method {IO#readlines}[https://docs.ruby-lang.org/en/master/IO.html#method-i-readlines]:

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

- Document for page {Dig Methods}[https://docs.ruby-lang.org/en/master/dig_methods_rdoc.html]:

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

## About the Examples

`ri` output can be large,
and so here we sometimes pipe the output to one of these:

- {head}[https://www.man7.org/linux/man-pages/man1/head.1.html]: leading lines only.
- {tail}[https://www.man7.org/linux/man-pages/man1/tail.1.html]: trailing lines only.
- {wc -l}[https://www.man7.org/linux/man-pages/man1/wc.1.html]: line count only.

## Modes

There are two `ri` modes:

- <i>Static mode</i>:
  In general, `ri` responds in static mode
  if the command has an argument.
  See {Static Mode}[RI_md.html#label-Static+Mode].
- <i>Interactive mode</i>:
  In general, `ri` responds in interactive mode
  if the command has no argument.
  See {Interactive Mode}[RI_md.html#label-Interactive+Mode].

<b>Pro tip</b>:
If you are a frequent `ri` user,
you can save time by keeping open a dedicated command window
with a running interactive `ri` session;
when you switch to that window, `ri` is ready to respond quickly,
without the performance overhead of re-reading `ri` source files.

## Names

In both modes, static and interactive,
`ri` responds to input _names_;
each name specifies documents or other information to be printed.

These examples summarize `ri` names
(for details and examples, follow the links):

- {Ruby classes and modules}[rdoc-ref:RI.md@Ruby+Classes+and+Modules]:

    | Name                  | Prints                                                    |
    |-----------------------|-----------------------------------------------------------|
    | File                  | Document for class File.                                  |
    | File::File::Constants | Document for module File::File::Constants.                |
    | Ar                    | Nothing (not unique initial characters).                  |
    | Arr                   | Document for class Array (unique initial characters).     |
<br>

- {Ruby methods}[rdoc-ref:RI.md@Ruby+Methods]:

    | Name            | Prints                                                                                                        |
    |-----------------|---------------------------------------------------------------------------------------------------------------|
    | IO::readlines   | Document for singleton method IO::readlines.                                                                  |
    | IO#readlines    | Document for instance method IO::readlines.                                                                   |
    | IO.readlines    | Documents for instance method IO::readlines and singleton method IO::readlines.                               |
    | ::readlines     | Documents for singleton method readlines in all classes and modules.                                          |
    | #readlines      | Documents for instance method #readlines in all classes and modules.                                          |
    | .readlines      | Documents for singleton method ::readlines and instance method #readlines in all classes and modules.         |
    | readlines       | Documents for singleton method ::readlines and instance method #readlines in all classes and modules.         |
<br>

- {Ruby pages}[rdoc-ref:RI.md@Ruby+Pages]:

    | Name                        | Prints                                                          |
    |-----------------------------|-----------------------------------------------------------------|
    | ruby:                       | List of Ruby pages.                                             |
    | ruby:security.rdoc          | Document for page security.                                     |
    | ruby:security               | Document for page security (if no other security.*).            |
    | ruby:syntax/assignment.rdoc | Document for page assignment.                                   |
    | ruby:syntax/assignment      | Document for page assignment (if no other syntax/assignment.*). |
    | ruby:assignment             | Document for page assignment (if no other */assignment.*).      |
<br>

- {Gem documents}[rdoc-ref:RI.md@Gem+Documents]
  (assuming gem Nokigiri installed):

    | Name                               | Prints                                                                         |
    |------------------------------------|--------------------------------------------------------------------------------|
    | Nokigiri                           | Document for module Nokogiri.                                                  |
    | Nokigiri::CSS                      | Document for class Nokogiri::CSS.                                              |
    | nokogiri:                          | List of Nokogiri pages.                                                        |
    | nokogiri:README.md                 | Document for page README.md.                                                   |
    | nokogiri:README                    | Document for page README.md (if no other README.*).                            |
    | Nokogiri::HTML4::Document          | Document for class Nokogiri::HTML4::Document.                                  |
    | Nokogiri::HTML4::Document::parse   | Document for singleton method Nokogiri::HTML4::Document::parse.                |
    | Nokogiri::HTML4::Document#fragment | Document for instance method Nokogiri::HTML4::Document#fragment.               |

## Source Files

`ri` derives documentation from files in _local_ directories,
(not from the {Ruby online documentation}[https://docs.ruby-lang.org/en/master]).
To see the source directories on your local machine:

```sh
$ ri --list-doc-dirs
```

These are the directories that `ri` may search, which may or may not actually exist.

## Static Mode

In static mode, `ri` prints a response and exits.

In general, `ri` responds in static mode
if the command has an argument.

### Ruby Classes and Modules

To get the document for a particular class or module,
give its name as the argument:

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

If the name is not unique initial characters,
no document is found:

```sh
$ ri A
Nothing known about A
```

To get a list of all classes and modules,
use option `--list` with no argument:

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
$ ri Array | wc -l       # Class only.
390
$ ri --all Array | wc -l # Class and methods.
4224
```

### Ruby Methods

To get the document for a particular instance method,
include the class/module name and the method name in the command:

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

### Gem Documents



### Static Options

`ri` also responds in static mode when certain options are given,
even with no arguments;
these include:

- {Option --help}: Prints `ri` help text.
- {Option --list}: Prints list of classes and modules.
- {Option --list-doc-dirs}: Prints list of `ri` source directories.
- {Option --version}: Prints `ri` version.


## Interactive Mode

In general' `ri` responds to a command in interactive mode
if the command has no arguments.

## Options



## Environment Variables


All options also can be specified through the +RI+ environment variable.
Command-line options always override those specified in the +RI+ environment
variable.

The +RI_PAGER+ environment variable allows you to choose a particular pager or
particular options for your pager.

