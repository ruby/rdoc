= \RDoc

* http://rubyforge.org/projects/rdoc/

== DESCRIPTION:

RDoc is an application that produces documentation for one or more Ruby source
files.  RDoc includes the `rdoc` and `ri` tools for generating and displaying
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
and used with the -T option.

== SYNOPSIS:

  gem 'rdoc'
  require 'rdoc/rdoc'
  # ... see RDoc

== BUGS:

If you found a bug, please report it at the RDoc project's tracker on
RubyForge:

http://rubyforge.org/tracker/?group_id=627

== LICENSE:

RDoc is Copyright (c) 2001-2003 Dave Thomas, The Pragmatic Programmers,
portions (c) 2007-2008 Eric Hodel.  It is free software, and may be
redistributed under the terms specified in the README file of the Ruby
distribution.

