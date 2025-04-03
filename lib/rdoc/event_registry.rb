module RDoc
  class EventRegistry
    EVENT_TYPES = %i[
      rdoc_start
      sample
      rdoc_store_complete
    ]

    attr_reader :environment

    def initialize
      @registry = EVENT_TYPES.map { |event_name| [event_name, []] }.to_h
      @environment = {}
    end

    def register(event_name, handler)
      @registry[event_name] << handler
    end

    def trigger(event_name, *args)
      @registry[event_name].each do |handler|
        handler.call(@environment, *args)
      end
    end
  end
end
