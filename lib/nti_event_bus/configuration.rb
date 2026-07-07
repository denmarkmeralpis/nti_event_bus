# frozen_string_literal: true

module NtiEventBus
  # Runtime configuration. On Rails the Railtie fills in path defaults; hosts may override any of it.
  class Configuration
    # Absolute path to the root events file that is evaluated by `setup!` (e.g. config/events.rb).
    attr_accessor :root_events_file
    # Absolute path to the directory that `draw` resolves nested event files from (e.g. config/events).
    attr_accessor :events_dir
    # ActiveJob queue used by the default dispatcher.
    attr_accessor :queue_name
    # Optional logger; when set, receives debug lines from the bus.
    attr_accessor :logger

    attr_writer :dispatcher

    def initialize
      @queue_name = :events
      @root_events_file = nil
      @events_dir = nil
      @logger = nil
      @dispatcher = nil
    end

    # Object responding to `#call(handler_name, payload)`. Defaults to asynchronous ActiveJob dispatch.
    def dispatcher
      @dispatcher ||= Dispatchers::ActiveJob.new
    end

    def root_events_file!
      root_events_file ||
        raise(NotConfiguredError, 'NtiEventBus.configuration.root_events_file must be set')
    end
  end
end
