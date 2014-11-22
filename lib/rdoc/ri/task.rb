#--
# Copyright (c) 2003, 2004 Jim Weirich, 2009 Eric Hodel
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require 'rubygems'
begin
  gem 'rdoc'
rescue Gem::LoadError
end unless defined?(RDoc)

require 'rdoc/task'

module RDoc::RI
  class Task < RDoc::Task
    def clobber_task_description
      "Remove RDoc RI data files"
    end

    def defaults
      super
      @rdoc_dir = 'doc/ri'
    end

    def rdoc_task_description
      'Build RDoc RI data files'
    end

    def rerdoc_task_description
      'Rebuild RDoc RI data files'
    end
  end
end
