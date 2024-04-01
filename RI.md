#`ri`: Ruby Information

`ri` (<b>r</b>uby <b>i</b>nformation) is the Ruby command-line utility
that gives fast and easy on-line access to Ruby documentation.

`ri` can show documentation for Ruby and installed gems:

- A **class** or **module**:
  text associated with the class or module definition
  in a source file (`.rb` or `.c`).
- One or more **methods**:
  text associated with method definitions
  in source files (`.rb` and `.c`).
- A **page**:
  text from a stand-alone documentation file
  (`.rdoc` or  `.md`, or sometimes other).

`ri` can also show lists of:

- **classes** and **modules**:
  full or partial list.
- **pages**:
  for Ruby or for an installed gem.

## In Brief

Command for class or module document;
see output details at {Class or Module Document}[rdoc-ref:RI.md@Class+or+Module+Document]:

| Command                             | Document                         |
|-------------------------------------|----------------------------------|
| ri IO                               | Class IO.                        |
| ri Nokogiri::HTML4::Document        | Class Nokogiri::HTML4::Document. |
| ri Enumerable                       | Module Enumerable.               |
| ri Nokogiri                         | Module Nokogiri.                 |
<br>

Command for method documents;
see output details at {Method Document}[rdoc-ref:RI.md@Method+Document]:

| Command                             | Document(s)                                            |
|-------------------------------------|--------------------------------------------------------|
| ri IO::readlines                    | Class method IO::readlines.                            |
| ri IO#readlines                     | Instance method IO#readlines.                          |
| ri IO.readlines                     | Both of the above.                                     |
| ri readlines                        | ::readlines and #readlines in all classes and modules. |
| ri Nokogiri::HTML4::Document::parse | Class method Nokogiri::HTML4::Document::parse.         |
| ri Nokogiri::HTML4::Document#parse  | Instance method Nokogiri#HTML4::Document::parse.       |
| ri Nokogiri::HTML4::Document.parse  | Both of the above.                                     |
<br>

Command for page;
see output details at {Page Document}[rdoc-ref:RI.md@Page+Document]:

| Command                             | Page              |
|-------------------------------------|-------------------|
| ri ruby:dig_methods                 | Ruby dig_methods. |
| ri nokogiri:README                  | Nokogiri README.  |
<br>

Command for list;
see output details at {Lists}[rdoc-ref:RI.md@Lists]:

| Command                             | List                                                     |
|-------------------------------------|----------------------------------------------------------|
| ri --list                           | Classes and modules (including gems).                    |
| ri --list Fi                        | Classes and modules starting with 'Fi' (including gems). |
| ri ruby:                            | Ruby pages.                                              |
| ri nokogiri:                        | Nokogiri pages.                                          |
<br>

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

- `ri` output can be large;
  to save space, an example may pipe it to one of these:

    - {head}[https://www.man7.org/linux/man-pages/man1/head.1.html]: leading lines only.
    - {tail}[https://www.man7.org/linux/man-pages/man1/tail.1.html]: trailing lines only.
    - {wc -l}[https://www.man7.org/linux/man-pages/man1/wc.1.html]: line count only.
    - {grep}[https://www.man7.org/linux/man-pages/man1/grep.1.html]: selected lines only.

- An example that involves the `ri` environment variables `RI` or `RI_PAGER`
  may define an environment variable on the command line
  via the shell idiom `_env_name_="_env_value_"`:

    ```sh
    $ RI="--all --no-gems" ruby -e "p ENV['RI']"
    "--all --no-gems"
    $ RI_PAGER="grep . | less" ruby -e "p ENV['RI_PAGER']"
    "grep . | less"
    ```

- An example that involves a gem assumes that gem `nokogiri` is installed.

## Modes

There are two `ri` modes:

- <i>Static mode</i>:
  In general, `ri` responds in its static mode
  if a _name_ is given;
  it outputs and exits (as in the examples above).
  See {Static Mode}[rdoc-ref:RI.md@Static+Mode].
- <i>Interactive mode</i>:
  In general, `ri` enters its interactive mode
  if no _name_ is given;
  in interactive mode, `ri` outputs and waits for another command:

    ```sh
    $ ri
    Enter the method name you want to look up.
    You can use tab to autocomplete.
    Enter a blank line to exit.
    >>
    ```

    See {Interactive Mode}[rdoc-ref:RI.md@Interactive+Mode].

## Names

In both modes, static and interactive,
`ri` responds to an input _name_ that specifies what is to be output:
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

These tables summarize `ri` _name_ values:

- Ruby class and module documents
  (see {details and examples}[rdoc-ref:RI.md@Ruby+Class+and+Module+Documents]):

    | Name         | Outputs                                               |
    |--------------|-------------------------------------------------------|
    | 'File'       | Document for class File.                              |
    | 'File::Stat' | Document for nested class File::Stat.                 |
    | 'Enumerable' | Document for module Enumerable.                       |
    | 'Arr'        | Document for class Array (unique initial characters). |
<br>

    If {option \\--all}[rdoc-ref:RI.md@-all-2C+-a]
    is in effect, documents for the methods in the named class or module
    are also output.

- Ruby method documents
  (see {details and examples}[rdoc-ref:RI.md@Ruby+Method+Documents]):

    | Name                      | Outputs                                                                     |
    |---------------------------|-----------------------------------------------------------------------------|
    | 'IO::readlines'           | Document for class method IO::readlines.                                    |
    | 'IO#readlines'            | Document for instance method IO::readlines.                                 |
    | 'IO.readlines'            | Documents for instance method IO::readlines and class method IO::readlines. |
    | '::readlines'             | Documents for all class methods ::readlines.                                |
    | '#readlines'              | Documents for all instance methods #readlines; see note below.              |
    | '.readlines', 'readlines' | Documents for class methods ::readlines and instance methods #readlines.    |
<br>

    **Note**: in static mode, a name on the command line may need
    shell quote or escape characters.
    In the table above, `#readlines` on the command line
    may (depending on the shell) need to be escaped as `\#readlines`;
    see {Shell Quoting and Escaping}[rdoc-ref:RI.md@Shell+Quoting+or+Escaping].

- Ruby page documents
  (see {details and examples}[rdoc-ref:RI.md@Ruby+Page+Documents]):

    | Name                          | Outputs                                                         |
    |-------------------------------|-----------------------------------------------------------------|
    | 'ruby:syntax/assignment.rdoc' | Document for page assignment.                                   |
    | 'ruby:syntax/assignment'      | Document for page assignment (if no other syntax/assignment.*). |
    | 'ruby:assignment'             | Document for page assignment (if no other */assignment.*).      |
<br>

- Gem class and module documents
  (see {details and examples}[rdoc-ref:RI.md@Gem+Class+and+Module+Documents]):

    | Name                        | Outputs                                       |
    |-----------------------------|-----------------------------------------------|
    | 'Nokogiri::HTML4::Document' | Document for class Nokogiri::HTML4::Document. |
    | 'Nokogiri'                  | Document for module Nokogiri.                 |
<br>

    If {option \\--all}[rdoc-ref:RI.md@-all-2C+-a]
    is in effect, documents for the methods in the named class or module
    are also output.

- Gem method documents
  (see {details and examples}[rdoc-ref:RI.md@Gem+Method+Documents]):

    | Name                                 | Outputs                                                          |
    |--------------------------------------|------------------------------------------------------------------|
    | 'Nokogiri::HTML4::Document::parse'   | Document for class method Nokogiri::HTML4::Document::parse.      |
    | 'Nokogiri::HTML4::Document#fragment' | Document for instance method Nokogiri::HTML4::Document#fragment. |
<br>

- Gem page documents
  (see {details and examples}[rdoc-ref:RI.md@Gem+Page+Documents]):

    | Name                 | Outputs                      |
    |----------------------|------------------------------|
    | 'nokogiri:README.md' | Document for page README.md. |
<br>

- Lists:

    | Name        | Outputs                 |
    |-------------|-------------------------|
    | 'ruby:'     | List of Ruby pages.     |
    | 'nokogiri:' | List of Nokogiri pages. |
<br>

    There are more lists available;
    see {option --list}[rdoc-ref:RI.md@-list-2C+-l].

## Pro Tips

### `ri` at the Ready

If you are a frequent `ri` user,
you can save time by keeping open a dedicated command window
with either of:

- A running {interactive ri}[rdoc-ref:RI.md@Interactive+Mode] session.
- A running {irb session}[https://docs.ruby-lang.org/en/master/IRB.html];
  type `'help'` or `'show_doc'` to enter `ri`, newline to exit.

When you switch to that window, `ri` is ready to respond quickly,
without the performance overhead of re-reading `ri` sources.

### Pager \Options

You can set the pager value to a pager program name with options;
this example (which omits output) sets the pager to `'less'`,
with options `'-E'` (quit at EOF) and `'-F'` (quit if one screen):

```sh
RI_PAGER="less -E -F" ri Array
```

See the options for your chosen pager program
(e.g, type `'less --help'`).

### Output Filters

The "pager" value actually need not specify a simple pager program.
You can, for example, set the pager value to `'grep . | less'`,
which will exclude blank lines (thus saving screen space)
before piping output to `less`;
example (output omitted):

```sh
RI_PAGER="grep . | less" ri Array
```

### Links  in `ri` Output

#### Implicit Link

When you see:

- `'IO::readlines'`, `'IO#readlines'`, `'IO.readlines'`:
  use that same text as the _name_ in an `ri` command.

    Examples (output omitted):

    ```sh
    $ ri IO::readlines
    $ ri IO#readlines
    $ ri IO.readlines
    ```

- `'#read'`, `'::read'`, `'.read'`:
  you're likely already in the `ri` document for a class or module,
  or for a method in a class or module;
  use that same text with the name of the class or module (such as `'File'`)
  as the _name_ in an `ri` command.

    Examples (output omitted):

    ```sh
    $ ri File::read
    $ ri File#read
    $ ri File.read
    ```

#### Explicit Link

When you see:

- `'{Dig Methods}[rdoc-ref:doc/dig_methods.rdoc]'`:
   use the trailing part of the `'[rdoc-ref:doc/'` in an `ri` command
   for a Ruby document.

    Example (output omitted):

    ```sh
    $ ri ruby:dig_methods.rdoc
    ```

- `'{Table (information)}[https://en.wikipedia.org/wiki/Table_(information)]'`:
  go to the given URL in your browser.

## `ri` Documents

This section outlines what you can expect to find
in the `ri` document for a class, module, method, or page.

See also:

- {Pager}[rdoc-ref:RI.md@Pager].
- {Links in ri Output}[rdoc-ref:RI.md@Links+in+ri+Output].

### Class and Module Documents

The document for a class or module shows:

- The class or module name, along with its parent class if any.
- Where it's defined (Ruby core or gem).
- When each exists:

    - The names of its included modules.
    - The text of its embedded documentation.
    - Its constants.
    - Its class methods.
    - Its instance methods.

Examples:

- Ruby class `Array`:

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

- Gem Nokogiri module `Nokogiri`:

    ```sh
    $ ri Nokogiri | head
    = Nokogiri

    (from gem nokogiri-1.16.2-x86_64-linux)
    ------------------------------------------------------------------------

    Nokogiri parses and searches XML/HTML very quickly, and also has
    correctly implemented CSS3 selector support as well as XPath 1.0
    support.

    Parsing a document returns either a Nokogiri::XML::Document, or a
    ```

The document typically includes certain headings,
which may be useful for searching:

```sh
$ ri IO | grep "^= "
= IO < Object
= Includes:
= Constants:
= Class methods:
= Instance methods:
```

### Method Documents

The document for a method includes:

- The source of the method: `'(from ruby core)'` or `'(from gem _gem_)'`.
- The calling sequence(s) for the method.
- The text of its embedded documentation (if it exists).

Examples:

```sh
$ ri IO#read | head
= IO#read

(from ruby core)
------------------------------------------------------------------------
ios.read([length [, outbuf]])    -> string, outbuf, or nil

------------------------------------------------------------------------

Reads length bytes from the I/O stream.
```

```sh
$ ri Nokogiri::parse | head
= Nokogiri::parse

(from gem nokogiri-1.16.2-x86_64-linux)
------------------------------------------------------------------------
  parse(string, url = nil, encoding = nil, options = nil) { |doc| ... }

------------------------------------------------------------------------

Parse an HTML or XML document.  string contains the document.
```

The output for a _name_ that cites methods includes the document
for each found implementation;
the number of such implementations depends on the _name_:

- Within a class:

    Each of these commands outputs documents
    for methods in the class `IO` (output omitted):

    ```sh
    $ ri IO::readlines # Class method ::readlines.
    $ ri IO#readlines  # Instance method #readlines.
    $ ri IO.readlines  # Both of above.
    ```

- In all Ruby classes:

    Each of these commands outputs documents
    for methods in all Ruby classes (output omitted):

    ```sh
    $ ri ::readlines   # Class method ::readlines.
    $ ri \#readlines   # Instance method #readlines.
    $ ri .readlines    # Both of above.
    ```

    For these all-classes commands,
    the output is organized into sections,
    one for each found method (output filtered to show sections):

    ```sh
    $ ri ::readlines | grep "= Implementation"
    === Implementation from CSV
    === Implementation from IO
    ```

    ```sh
    $ ri \#readlines | grep "= Implementation"
    === Implementation from ARGF
    === Implementation from CSV
    === Implementation from IO
    === Implementation from Kernel
    === Implementation from Buffering
    === Implementation from Pathname
    === Implementation from StringIO
    === Implementation from GzipReader
    ```

    ```sh
    $ ri .readlines | grep "= Implementation"
    === Implementation from ARGF
    === Implementation from CSV
    === Implementation from CSV
    === Implementation from IO
    === Implementation from IO
    === Implementation from Kernel
    === Implementation from Buffering
    === Implementation from Pathname
    === Implementation from StringIO
    === Implementation from GzipReader
    ```

## `ri` Information

With certain options, an `ri` command may output information other than documents
for a class, module, methods, or page:

- {Option \\--help or -h}[rdoc-ref:RI.md@-help-2C+-h]:
  Outputs `ri` help text.
- {option \\--version or -v}[rdoc-ref:RI.md@-version-2C+-v]:
  Outputs `ri` version.
- {option \\--list or -l}[rdoc-ref:RI.md@-list-2C+-l]:
  Outputs list of classes and modules.
- {option \\--list-doc-dirs}[rdoc-ref:RI.md@-list-doc-dirs]:
  Outputs list of `ri` source directories.
- {Option \\--dump=FILEPATH}[rdoc-ref:RI.md@-dump-3DFILEPATH]:
  Outputs dump of ri cache file at the given filepath.

## Static Mode

In static mode, `ri` outputs a response and exits.

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

`ri` also responds in static mode when certain options are given,
even when no _name_ is given;
see {ri Information}[rdoc-ref:RI.md@ri+Information].

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
except that it:

- Omits command word `ri`; you just type the _name_.
- Omits options; in interactive mode the only options in effect
  are those taken from environment variable `RI`.
  See {Options}[rdoc-ref:RI.md@Options].
- Supports tab auto-completion for the names of a classes, modules, and methods;
  when, for example, you type `"Arr\t"` (here `"\t` represents the tab character),
  `ri` "completes" the text as `'Array '`.

See also {ri at the Ready}[rdoc-ref:RI.md@ri+at+the+Ready].

## Ruby Documents

### Ruby Class and Module Documents

See {Ruby Class and Module Lists}[rdoc-ref:RI.md@Ruby+Class+and+Module+Lists].

Names for Ruby class and module documents:

| Name         | Outputs                                               |
|--------------|-------------------------------------------------------|
| 'File'       | Document for class File.                              |
| 'File::Stat' | Document for nested class File::Stat.                 |
| 'Enumerable' | Document for module Enumerable.                       |
| 'Arr'        | Document for class Array (unique initial characters). |
| 'A'          | Nothing (not unique initial characters).              |
<br>

If {option \\--all}[rdoc-ref:RI.md@-all-2C+-a]
is in effect, documents for the methods in the named class or module
are also output.

Examples:

- Document for class `File`:

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

- Document for nested class `File::Stat`:

    ```sh
    $ ri File::Stat | head
    = File::Stat < Object

    ------------------------------------------------------------------------
    = Includes:
    Comparable (from ruby core)

    (from ruby core)
    ------------------------------------------------------------------------
    Objects of class File::Stat encapsulate common status information for
    File objects. The information is recorded at the moment the File::Stat
    ```

- Document for class `Enumerable`:

    ```sh
    $ ri Enumerable | head
    = Enumerable

    (from ruby core)
    ------------------------------------------------------------------------
    The Enumerable mixin provides collection classes with several traversal
    and searching methods, and with the ability to sort. The class must
    provide a method #each, which yields successive members of the
    collection. If Enumerable#max, #min, or #sort is used, the objects in
    the collection must also implement a meaningful <=> operator, as these
    methods rely on an ordering between members of the collection.
    ```

- Document for class `Array` (unique initial characters):

    ```sh
    $ ri Arr | head
    = Array < Object

    ------------------------------------------------------------------------
    = Includes:
    Enumerable (from ruby core)

    (from ruby core)
    ------------------------------------------------------------------------
    An Array is an ordered, integer-indexed collection of objects, called
    elements.  Any object may be an Array element.
    ```

- Document for class `Array` with option `--all`:

    ```sh
    $ ri Array | wc -l
    390
    $ ri --all Array | wc -l
    4224
    ```

### Ruby Method Documents

Names for Ruby method documents:

| Name                      | Outputs                                                                    |
|---------------------------|----------------------------------------------------------------------------|
| 'IO::readlines'           | Document for class method IO::readlines.                                   |
| 'IO#readlines'            | Document for instance method IO#readlines.                                 |
| 'IO.readlines'            | Documents for class method IO::readlines and instance method IO#readlines. |
| '::readlines'             | Documents for all class methods ::readlines.                               |
| '#readlines'              | Documents for all instance methods #readlines; see note below.             |
| '.readlines', 'readlines' | Documents for class methods ::readlines and instance methods #readlines.   |
<br>

Examples:

- Document for class method `IO::readlines`:

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

  - Documents for class method `IO::readlines` and instance method `IO#readlines`
    (outputs two documents):

    ```sh
    $ ri IO.readlines | grep "(from "
    (from ruby core)
    (from ruby core)
    ```

- Documents for all class methods `::readlines`
  (outputs two documents):

    ```sh
    $ ri ::readlines | grep Implementation
    === Implementation from CSV
    === Implementation from IO
    ```

  - Documents for all instance methods `#readlines`:

    ```sh
    $ ri \#readlines | grep Implementation
    === Implementation from ARGF
    === Implementation from CSV
    === Implementation from IO
    === Implementation from Kernel
    === Implementation from Buffering
    === Implementation from Pathname
    === Implementation from StringIO
    === Implementation from GzipReader
    ```

  - Documents for class methods `::readlines` and instance methods `#readlines`:

    ```sh
    $ ri .readlines | grep Implementation
    === Implementation from ARGF
    === Implementation from CSV
    === Implementation from CSV
    === Implementation from IO
    === Implementation from IO
    === Implementation from Kernel
    === Implementation from Buffering
    === Implementation from Pathname
    === Implementation from StringIO
    === Implementation from GzipReader
    ```

### Ruby Page Documents

See {Ruby Page Lists}[rdoc-ref:RI.md@Ruby+Page+Lists].

To output a Ruby page document:

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
`ruby:exceptions` is the same as `ruby:syntax/exceptions.rdoc`.

## Ruby Lists

### Ruby Class and Module Lists

Names for Ruby class and module lists (when given with option `--list`):

| Name       | Outputs                                              |
|------------|------------------------------------------------------|
| '' [none]  | List of all Ruby classes and modules.                |
| 'A'        | List of Ruby classes and modules starting with 'A'.  |
| 'Ar'       | List of Ruby classes and modules starting with 'Ar'. |
| 'NoSuch'   | Nothing (no matching class or module name).          |
<br>

Examples:

- List of all Ruby classes and modules:

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

- List of Ruby classes and modules starting with `'A'`:

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
    ```

- List of Ruby classes and modules starting with `'Ar'`:

    ```sh

    $ ri --list Ar | head
    ArgumentError
    Array
    ```

### Ruby Page Lists

To output a list of the Ruby page documents,
give the _name_ as `ruby:`:

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

Many of the "boilerplate" pages have names beginning with a capital letter
(as seen above);
other pages typically do not:

```sh
$ ri ruby: | grep "^[a-z]"  | wc -l
35
```

```sh
$ ri ruby: | grep "^[a-z]" | head -5
bug_triaging.rdoc
contributing.rdoc
dig_methods.rdoc
dtrace_probes.rdoc
extension.ja.rdoc

$ ri ruby: | grep "^[a-z]" | tail -5
syntax/modules_and_classes.rdoc
syntax/pattern_matching.rdoc
syntax/precedence.rdoc
syntax/refinements.rdoc
win32/README.win32
```

## Gem Documents

### Gem Class and Module Documents

See {Gem Class and Model Lists}[rdoc-ref:RI.md@Gem+Class+and+Model+Lists].

Names for gem `nokogiri` class and model documents:

| Name                        | Outputs                                       |
|-----------------------------|-----------------------------------------------|
| 'Nokogiri::HTML4::Document' | Document for class Nokogiri::HTML4::Document. |
| 'Nokogiri'                  | Document for module Nokogiri.                 |
<br>

If {option \\--all}[rdoc-ref:RI.md@-all-2C+-a]
is in effect, documents for the methods in the named class or module
are also output.

Examples:

- Document for class `Nokogiri::HTML4::Document:
 
    ```sh
    $ ri Nokogiri::HTML4::Document | head
    = Nokogiri::HTML4::Document < Nokogiri::XML::Document
    
    (from gem nokogiri-1.16.2-x86_64-linux)
    ------------------------------------------------------------------------
    = Class methods:
    
      parse
    
    = Instance methods:
    ```

  - Document for module `Nokogiri`:

    ```sh
    $ ri Nokogiri | head
    = Nokogiri
    
    (from gem nokogiri-1.16.2-x86_64-linux)
    ------------------------------------------------------------------------
    
    Nokogiri parses and searches XML/HTML very quickly, and also has
    correctly implemented CSS3 selector support as well as XPath 1.0
    support.
    
    Parsing a document returns either a Nokogiri::XML::Document, or a
    ```
    
### Gem Method Documents

Names for gem `nokogiri` methods documents:

| Name                                 | Outputs                                                          |
|--------------------------------------|------------------------------------------------------------------|
| 'Nokogiri::HTML4::Document::parse'   | Document for class method Nokogiri::HTML4::Document::parse.      |
| 'Nokogiri::HTML4::Document#fragment' | Document for instance method Nokogiri::HTML4::Document#fragment. |
<br>

Examples:

- Document for class method `Nokogiri::HTML4::Document::parse`:

    ```sh
    $ ri Nokogiri::HTML4::Document::parse | head
    = Nokogiri::HTML4::Document::parse
    
    (from gem nokogiri-1.16.2-x86_64-linux)
    === Implementation from Document
    ------------------------------------------------------------------------
    parse(string_or_io, url = nil, encoding = nil, options = XML::ParseOptions::DEFAULT_HTML) { |options| ... }
    
    ------------------------------------------------------------------------
    
    Parse HTML.  string_or_io may be a String, or any object that responds
    ```

- Document for instance method `Nokogiri::HTML4::Document#fragment`:

    ```sh
    $ ri Nokogiri::HTML4::Document#fragment | head
    = Nokogiri::HTML4::Document#fragment
    
    (from gem nokogiri-1.16.2-x86_64-linux)
    === Implementation from Document
    ------------------------------------------------------------------------
    fragment(tags = nil)
    
    ------------------------------------------------------------------------
    
    Create a Nokogiri::XML::DocumentFragment from tags
    ```

### Gem Page Documents

To output a list of gem page documents, give the _name_ as _gemname_ with suffixed colon:

```sh
$ ri nokogiri: | head
= Pages in gem nokogiri-1.16.2-x86_64-linux

README.md
lib/nokogiri/css/tokenizer.rex
```

To output a gem page document:

```sh
$ ri nokogiri:README.md | head
<div><img src="https://nokogiri.org/images/nokogiri-serif-black.png" align="right"/></div>= Nokogiri
Nokogiri (鋸) makes it easy and painless to work with XML and HTML from
Ruby. It provides a sensible, easy-to-understand API for
{reading}[https://nokogiri.org/tutorials/parsing_an_html_xml_document.ht
ml], writing,
{modifying}[https://nokogiri.org/tutorials/modifying_an_html_xml_documen
t.html], and
{querying}[https://nokogiri.org/tutorials/searching_a_xml_html_document.
html] documents. It is fast and standards-compliant by relying on native
parsers like libxml2, libgumbo, and xerces.
```

If the page name is sufficiently unique,
you can omit leading and trailing elements:
`nokogiri:tokenizer` is the same as `nokogiri:lib/nokogiri/css/tokenizer.rex`.

## Gem Lists

### Gem Class and Module Lists

Names for gem `nokogiri` class and module lists (when given with option `--list`):

| Name       | Outputs                               |
|------------|---------------------------------------|
| Nokogiri   | List of Nokogiri classes and modules. |
<br>

Example:

```sh
$ ri --list Nokogiri | head
Nokogiri
Nokogiri::CSS
Nokogiri::CSS::Node
Nokogiri::CSS::Parser
Nokogiri::CSS::SyntaxError
Nokogiri::CSS::Tokenizer
Nokogiri::CSS::Tokenizer::ScanError
Nokogiri::CSS::XPathVisitor
Nokogiri::CSS::XPathVisitor::BuiltinsConfig
Nokogiri::CSS::XPathVisitor::DoctypeConfig
```

### Gem Page Lists

To output a list of the `nokogiri` page documents, give the _name_ as `nokogiri:`:

```sh
$ ri nokogiri: | head
= Pages in gem nokogiri-1.16.2-x86_64-linux

README.md
lib/nokogiri/css/tokenizer.rex
```

## Shell Quoting or Escaping

In static mode,
a _name_ on the command line may (depending on the shell)
need shell quoting or escaping.

Examples (output omitted):

```sh
ri \#readlines
ri 'Array.[]'
```

It is never necessary to quote or escape characters in interactive mode.

## `ri` Source Directories

`ri` derives documentation from files in _local_ directories,
(not from the {Ruby online documentation}[https://docs.ruby-lang.org/en/master]).

To see the directories that `ri` may search
(which may or may not actually exist):

```sh
$ ri --list-doc-dirs
```

The listed directories will include:

- Each user-specified directory,
  as given by {option --doc-dir}[rdoc-ref:RI.md@-doc-dir-3DDIRPATH-2C+-d+DIRPATH];
  see {Generating ri Source Files}[rdoc-ref:RI.md@Generating+ri+Source+Files].
- The system directory,
  which on a Unix-style platform may be `/usr/share/ri/_ruby_/system`;
  this directory is created and populated when Ruby is installed.
- The site directory,
  which on a Unix-style platform may be `/usr/share/ri/_ruby_/site`.
- The home directory,
  which on a Unix-style platform may be `~/.local/share/rdoc`.
- Each gem directory,
  which on a Unix-style platform may be `/var/lib/gems/_ruby_/doc/_gem_/ri`.

where:

- _ruby_ is the Ruby version number.
- Each _gem_ is a gem version.

The site and home directories are cited only for historical reasons,
and in a modern Ruby installation do not exist.
Therefore the usual order of searching will be:

1. User-specified directories.
1. The system directory.
1. Gem directories.

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

See also:

- {Pager Options}[rdoc-ref:RI.md@Pager+Options].
- {Output Filters}[rdoc-ref:RI.md@Output+Filters].

## \Options

\Options may be given on the `ri` command line;
those should be whitespace-separated, and must precede the given _name_, if any.

\Options may also be specified in environment variable `RI`;
those should also be whitespace-separated.

An option specified in environment variable `RI`
may be overridden by an option on the `ri` command line:

```sh
$ RI="--all" ri Array | wc -l
4224
$ RI="--all" ri --no-all Array | wc -l
390
```

### \Options Summary

These tables summarize `ri` options;
for details, see {Options Details}[rdoc-ref:RI.md@Options+Details].

#### Source Directories \Options

See {ri Source Directories}[rdoc-ref:RI.md@ri+Source+Directories].

Options for `ri`-defined source directories:

| Option                        | Effect                                                                            |
|-----------------------|-------------------------------------------------------------------------------|
| --gems, --no-gems     | Allow/exclude documents from installed gems. Default: --gems.                 |
| --home, --no-home     | Allow/exclude documents from ~/.rdoc. Default: --home.                        |
| --site, --no-site     | Allow/exclude documents from site libraries. Default: --site.                 |
| --no-standard-docs    | Exclude documents from the standard library, etc; default is to include them. |
| --system, --no-system | Allow/exclude documents from from system libraries. Default: --system.        |
<br>

Options for user-defined source directories:

| Option                        | Effect                                                                            |
|-------------------------------|-----------------------------------------------------------------------------------|
| --doc-dir=DIRPATH, -d DIRPATH | Add directory to ri source directories; may be repeated.                          |
<br>

Options for source directories information:

| Option                        | Effect                                                                            |
|-------------------------------|-----------------------------------------------------------------------------------|
| --list-doc-dirs               | Output list of ri source directories; default is --no-list-doc-dirs.               |
| --no-list-doc-dirs            | Do not output list of ri source directories; default;                              |
<br>

#### Mode \Options

| Option                        | Effect                                                                            |
|-------------------|---------------------------------------------------------|
| --interactive, -i | Enter interactive mode; default when no name given.     |
| --no-interactive  | Do not enter interactive mode; default when name given. |
<br>

#### Information \Options

| Option                        | Effect                                                                            |
|-------------------------------|-----------------------------------------------------------------------------------|
| --help, -h                    | Output help message and exit.                                                      |
| --version, -v                 | Output ri version and exit.                                                        |
<br>

#### Debugging \Options

| Option                     | Effect                                                    |
|----------------------------|-----------------------------------------------------------|
| --dump=FILEPATH, --no-dump | Output/don't-output dump of cache file. Default: --no-dump. |
| --profile, --no-profile    | Run/don't-run  with Ruby profiler. Default: --no-profile. |
<br>

#### Output \Options
| Option                     | Effect                                                                            |
|----------------------------|-----------------------------------------------------------------------------------|
| --format=FORMAT, -f FORMAT | Set formatter: ansi, bs, markdown, rdoc; default is bs for pager, ansi otherwise. |
| --pager                    | Pipe output to pager; default.                                                    |
| --no-pager, -T             | Do not pipe output to pager; default is --pager.                                  |
| --width=NUMBER, -w NUMBER  | Set width (in characters) for output; default is 80.                              |
<br>

#### List \Options

| Option                        | Effect                                                                            |
|------------|----------------------------------------------------------|
| --list, -l | Output list of classes and modules; default is --no-list. |
| --no-list  | Do not output list; default.                              |
<br>

#### Methods \Options (for Class or Module)

| Option                        | Effect                                                                            |
|-----------|----------------------------------------------------------------|
| --all, -a | Output all (class or module plus methods); default is --no-all. |
| --no-all  | Do not output methods for named class or module; default.       |
<br>

#### Server Option

| Option                        | Effect                                                                            |
|-----------------|--------------------------------------------|
| --server=NUMBER | Set port for RDoc server; default is 8214. |
<br>

### \Options Details

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

### `--doc-dir=DIRPATH`, `-d DIRPATH`

Option `--doc-dir=DIRPATH` (aliased as `-d`) adds the given directory path
to the beginning of the array of `ri` source directory paths:

```sh
$ ri --doc-dir=/tmp --list-doc-dirs | head -1
/tmp
```

See {ri Source Directories}[rdoc-ref:RI.md@ri+Source+Directories].

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

### `--format=FORMAT`, `-f FORMAT`

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

See {ri Source Directories}[rdoc-ref:RI.md@ri+Source+Directories].

### `--help`, `-h`

Option `--help` (aliased as `-h`) specifies that `ri` is to output
its help text and exit.

### `--home`

Option `--home` (the default) specifies that `ri` is to include source directory
in `~/.rdoc` if it exists.

See {ri Source Directories}[rdoc-ref:RI.md@ri+Source+Directories].

### `--interactive`, `-i`

Option `--interactive` (aliased as `-i`)
specifies that `ri` is to enter interactive mode (ignoring the _name_ if given);
the option is the default when no _name_ is given.

### `--list`, `-l`

Option `--list` (aliased as `-l`) specifies that all class and module names
whose initial characters match the given _name_ are to be output;
the default is `--no-list`:

```sh
$ ri --list Ar | head
ArgumentError
Array
```

If no _name_ is given, all class and module names are output.

### `--list-doc-dirs`

Option `--list-doc-dirs` specifies that a list of the `ri` source directories
is to be output;
default is `--no-list-doc-dirs`.

See {ri Source Directories}[rdoc-ref:RI.md@ri+Source+Directories].

### `--no-all`

Option `--no-all` (the default) specifies that for a given class or module,
its method documents are not to be output.

### `--no-dump`

Option `--no-dump` (the default) specifies that a cache file is not to be dumped.

### `--no-gems`

Option `--no-gems` specifies that gem documents are not to be output;
`--gems` is the default.

See {ri Source Directories}[rdoc-ref:RI.md@ri+Source+Directories].

### `--no-home`

Option `--no-gems` specifies that gem documents from `~/.rdoc` are not to be output;
`--home` is the default.

See {ri Source Directories}[rdoc-ref:RI.md@ri+Source+Directories].

### `--no-interactive`

Option `--no-interactive` (the default when _name_ is not given)
specifies that `ir` is not to enter interactive mode,
regardless of whether _name_ is given.

### `--no-list`

Option `--no-list` (the default) specifies that a list of class and module names
is not to be output.

### `--no-list-doc-dirs`

Option `--no-list-doc-dirs` (the default) specifies that the list of documentation
directories is not to be output.

See {ri Source Directories}[rdoc-ref:RI.md@ri+Source+Directories].

### `--no-pager`, `-T`

Option `--no-pager` (aliased as `-T`) specifies that the output is not to be piped
to a pager;
default is `--pager`.

### `--no-profile`

Option `no-profile` (the default) specifies that the program is not to be run
with the Ruby profiler.

### `--no-site`

Option `--no-site` specifies that documents from the site libraries
are not to be output;
default is `--site`.

See {ri Source Directories}[rdoc-ref:RI.md@ri+Source+Directories].

### `--no-standard`

Option `--no-standard` specifies that documents from the standard libraries
are not to be output;
default is to output documents from the standard libraries.

See {ri Source Directories}[rdoc-ref:RI.md@ri+Source+Directories].

### `--no-system`

Option `--no-system` specifies that documents from the system libraries
are not to be output;
default is `--system`.

See {ri Source Directories}[rdoc-ref:RI.md@ri+Source+Directories].

### `--pager`

Option `--pager` (the default) specifies that the output is to be piped
to a pager.

### `--profile`

Option `--profile` specifies that the program is to be run with the Ruby profiler;
default is `--no-profile`.

### `--server=NUMBER`

Option `--server` specifies that the \RDoc server is to be run on the port
given as _NUMBER_;
the default port is `8214`.

### `--site`

Option `--site` (the default) specifies that documents from the site libraries
may be included.

See {ri Source Directories}[rdoc-ref:RI.md@ri+Source+Directories].

### `--system`

Option `--system` (the default) specifies that documents from the system libraries
may be included.

See {ri Source Directories}[rdoc-ref:RI.md@ri+Source+Directories].

### `--version`, `-v`

Option `--version` (aliased as `-v`) specifies that `ri` is to output its version and exit.

### `--width=NUMBER`, `-w NUMBER`

Option `--width` (aliased as `-w`) specifies that the output line lengths
should be restricted to the given _NUMBER_ of characters;
this is to be accomplished by line-wrapping, not truncation.
The default width is `80`:

```sh
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

## Generating `ri` Source Files

As may be seen at {ri Source Directories}[rdoc-ref:RI.md@ri+Source+Directories],
`ri` by default reads data from directories installed by Ruby and gems.

You can create your own `ri` source files.
This command creates `ri` source files in local directory `my_ri`,
from Ruby source files in local directory `my_sources`:

```sh
rdoc --op my_ri --format=ri my_sources
```

Those files may then be considered for any `ri` output
by specifying option `--doc-dir=my_ri`;
see {option --doc-dir}[rdoc-ref:RI.md@-doc-dir-3DDIRPATH-2C+-d+DIRPATH].
