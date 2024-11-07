# frozen_string_literal: true

require_relative 'rdoc/rubygems_hook'

# To install dependency libraries of RDoc, you need to run bundle install.
# At that time, rdoc/markdown is not generated.
# If generate and remove are executed at that time, an error will occur.
# So, we can't register generate and remove to Gem at that time.
begin
  require_relative 'rdoc/markdown'
rescue LoadError
else
  Gem.done_installing(&RDoc::RubyGemsHook.method(:generate))
  Gem.pre_uninstall(&RDoc::RubyGemsHook.method(:remove))
end
