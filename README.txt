= \RDoc

* Project Page: http://rubyforge.org/projects/rdoc/
* Documentation: http://rdoc.rubyforge.org/

== DESCRIPTION:

RDoc is an application that produces documentation for one or more Ruby source
files.  RDoc includes the +rdoc+ and +ri+ tools for generating and displaying
online documentation.

At this point in time, RDoc 2.x is a work in progress and may incur further
API changes beyond what has been made to the RDoc 1.0.1.  Command-line tools
are largely unaffected, but internal APIs may shift rapidly.

See RDoc for a description of RDoc's markup and basic use.

== TEMPLATE NOTE:

RDoc comes with five built-in HTML templates.  We use a 3rd party template,
however, for RDoc's own documentation site[http://rdoc.rubyforge.org].  This
template is Hanna[http://github.com/mislav/hanna/tree/master].

We strongly are considering making Hanna as RDoc's default template
in a future release, but for now this template can be downloaded separately
and used with the +-T+ option.

== SYNOPSIS:

  gem 'rdoc'
  require 'rdoc/rdoc'
  # ... see RDoc

== BUGS:
---
RDoc's Fortran 95 support is pretty broken right now.
The rdoc-f95[http://www.gfd-dennou.org/library/dcmodel/rdoc-f95/] project has
patches for RDoc 1.x that provide excellent Fortran 95 support.  Properly
supporting Fortran 95 requires a rewrite of RDoc's markup engine, which
is high on our list of goals.  The Fortran 95 issue can be tracked
here[http://rubyforge.org/tracker/index.php?func=detail&aid=21542&group_id=627&atid=2475].
---
The markup engine has lots of little bugs.  In particular:
* Escaping does not work for all markup.
* Typesetting is not always correct.
* Some output formats (ri, for example) do not correctly handle all of the
  markup.
The markup engine needs a rewrite, which can be tracked here[http://rubyforge.org/tracker/index.php?func=detail&aid=21540&group_id=627&atid=2475].
-------
If you find a bug, please report it at the RDoc project's
tracker[http://rubyforge.org/tracker/?group_id=627] on RubyForge:

== LICENSE:

RDoc is Copyright (c) 2001-2003 Dave Thomas, The Pragmatic Programmers,
portions (c) 2007-2008 Eric Hodel.  It is free software, and may be
redistributed under the terms specified in the README file of the Ruby
distribution.
