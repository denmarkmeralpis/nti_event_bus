# frozen_string_literal: true

require 'active_job'
require 'active_support/core_ext/string/inflections'

module NtiEventBus
  # ActiveJob that runs a single handler for a published event.
  #
  # The handler is passed by name (a String) rather than as a class so the argument serializes
  # cleanly and is re-resolved to the current class version at run time (reload-safe). The queue is
  # read from configuration at enqueue time so hosts can route event work to a dedicated queue.
  class HandleEventJob < ::ActiveJob::Base
    queue_as { NtiEventBus.configuration.queue_name }

    def perform(handler_name, payload)
      handler = handler_name.constantize

      handler.new(payload).call
    end
  end
end
