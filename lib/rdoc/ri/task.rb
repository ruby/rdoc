require 'rubygems'
begin
  gem 'rdoc'
rescue Gem::LoadError
end unless defined?(RDoc)

require 'rdoc/task'

class RDoc::RI::Task < RDoc::Task
  def clobber_task_description
    "Remove RDoc RI data files"
  end

  def defaults
    super
    @rdoc_dir = '.rdoc'
  end

  def rdoc_task_description
    'Build RDoc RI data files'
  end

  def rerdoc_task_description
    'Rebuild RDoc RI data files'
  end
end
