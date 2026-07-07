# frozen_string_literal: true

module NtiEventBus
  # Evaluation context for event-definition files.
  #
  # A root file is `instance_eval`ed against a DSL instance; it may `draw` additional files from the
  # configured `events_dir`, and declares subscriptions with `on_event` / `perform`:
  #
  #   on_event 'order.created' do
  #     perform Orders::Handlers::Created
  #   end
  class DSL
    def initialize(registry, events_dir)
      @registry = registry
      @events_dir = events_dir
      @current_event_name = nil
    end

    def on_event(event_name, &block)
      raise ArgumentError, 'Nested `on_event` not allowed' if @current_event_name
      raise ArgumentError, 'Block required for `on_event`' unless block

      event_name = normalize_event!(event_name)

      @current_event_name = event_name
      instance_eval(&block)
    ensure
      @current_event_name = nil
    end

    def perform(handlers)
      raise ArgumentError, 'perform must be inside `on_event`' unless @current_event_name

      Array(handlers).each do |handler|
        @registry.add(@current_event_name, handler)
      end
    end

    def draw(name)
      raise NotConfiguredError, 'NtiEventBus.configuration.events_dir must be set' unless @events_dir

      path = File.join(@events_dir.to_s, "#{name}.rb")
      raise LoadError, "Event file not found: #{path}" unless File.exist?(path)

      instance_eval(File.read(path), path.to_s)
    end

    private

    def normalize_event!(event_name)
      raise ArgumentError, 'event_name must be a String' unless event_name.is_a?(String)

      event_name = event_name.strip
      raise ArgumentError, 'event_name cannot be empty' if event_name.empty?

      # enforce naming convention: domain.action
      raise ArgumentError, "event_name must follow 'domain.action' format" unless event_name.include?('.')

      event_name.freeze
    end
  end
end
