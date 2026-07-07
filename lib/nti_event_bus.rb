# frozen_string_literal: true

require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/string/inflections'

require_relative 'nti_event_bus/version'
require_relative 'nti_event_bus/configuration'
require_relative 'nti_event_bus/registry'
require_relative 'nti_event_bus/dsl'
require_relative 'nti_event_bus/handler_base'
require_relative 'nti_event_bus/dispatchers'
require_relative 'nti_event_bus/handle_event_job'
require_relative 'nti_event_bus/railtie' if defined?(Rails::Railtie)

# Publish/subscribe event bus.
#
#   NtiEventBus.publish('order.created', { order_id: 1 })
#
# Handlers are declared in event files (see NtiEventBus::DSL) and executed asynchronously via a
# configurable dispatcher (see NtiEventBus::Dispatchers). The subscription registry is built once by
# `setup!`, deep-frozen, and read lock-free on the publish path.
module NtiEventBus
  class Error < StandardError; end

  # Raised when the bus is used before `setup!` has run or when required configuration is missing.
  class NotConfiguredError < Error; end

  # Guards registry (re)builds; reads of the frozen registry never take this lock.
  SETUP_MUTEX = Mutex.new

  class << self
    def configure
      yield(configuration) if block_given?
      configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end

    # Resets configuration to defaults. Intended for test suites.
    def reset_configuration!
      @configuration = Configuration.new
    end

    # Build the subscription registry from the configured event files and atomically install it.
    #
    # A fresh Registry is built, deep-frozen, then swapped in under SETUP_MUTEX. Readers always see a
    # fully-frozen registry (the previous one or the new one) — never a half-built one.
    def setup!
      SETUP_MUTEX.synchronize do
        registry = Registry.new
        path = configuration.root_events_file!
        DSL.new(registry, configuration.events_dir).instance_eval(File.read(path), path.to_s)
        registry.finalize!

        configuration.logger&.debug { "[NtiEventBus] registry built from #{path}" }
        @registry = registry
      end
      self
    end

    def registry
      @registry || raise(NotConfiguredError, 'NtiEventBus.setup! has not been run')
    end

    # Fan an event out to every subscribed handler via the configured dispatcher.
    # Returns nil. Unknown events (no handlers) are a no-op.
    def publish(event_name, payload)
      handlers = registry.handlers_for(event_name)
      return if handlers.empty?

      dispatcher = configuration.dispatcher
      handlers.each { |handler| dispatcher.call(handler.name, payload) }
      nil
    end
  end
end
