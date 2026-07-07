# frozen_string_literal: true

module NtiEventBus
  # Strategies for turning a resolved (handler_name, payload) pair into actual handler execution.
  # A dispatcher is any object responding to `#call(handler_name, payload)`.
  module Dispatchers
    # Default. Enqueues handler execution asynchronously via ActiveJob (Solid Queue, Sidekiq, ...).
    class ActiveJob
      def call(handler_name, payload)
        NtiEventBus::HandleEventJob.perform_later(handler_name, payload)
      end
    end

    # Runs the handler synchronously, in-process. Useful for tests or hosts without a job backend.
    class Inline
      def call(handler_name, payload)
        NtiEventBus::HandleEventJob.perform_now(handler_name, payload)
      end
    end
  end
end
