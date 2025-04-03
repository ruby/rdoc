module RDoc
  class BasePlugin
    # Register a literner for the given event

    def self.listens_to(event_name, &block)
      rdoc.event_registry.register(event_name, block)
    end

    # Activate the plugin with the given RDoc instance
    # Without calling this, plugins won't work

    def self.activate_with(rdoc = ::RDoc::RDoc.current)
      @@rdoc = rdoc
    end

    def self.rdoc
      @@rdoc
    end
  end
end
