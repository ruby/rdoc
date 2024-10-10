#
# This class is referenced by RubyGems to create documents.
# Now, methods are moved to rubygems_plugin.rb.
#
# When old version RDoc is not used,
# this class is not used from RubyGems too.
# Then, remove this class.
#
module RDoc
  class RubygemsHook
    def initialize(spec); end

    def remove; end

    def self.generation_hook installer, specs; end
  end
end
