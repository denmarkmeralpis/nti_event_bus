# frozen_string_literal: true

require 'active_support/core_ext/hash/indifferent_access'

module NtiEventBus
  # Base class for all event handlers.
  #
  # A handler lives inside the *subscribing* module and is responsible for:
  #   1. Extracting what it needs from the raw event payload
  #   2. Doing any lookups / transformations
  #   3. Calling the module's Main interactor (or service) with normalized params
  #
  # Subclasses must implement #call.
  #
  # Example:
  #   class CreateAuditLog::Handlers::OrderVoided < NtiEventBus::HandlerBase
  #     def call
  #       CreateAuditLog::Main.call(
  #         cashier_id: payload.fetch(:cashier_id),
  #         ...
  #       )
  #     end
  #   end
  class HandlerBase
    attr_reader :payload

    def initialize(payload)
      @payload = payload.with_indifferent_access.freeze
    end

    def call
      raise NotImplementedError, "#{self.class}#call must be implemented"
    end

    private

    # Convenience — fetch multiple required keys at once.
    # Raises KeyError with a clear message if any are missing.
    #
    #   cashier_id, order_id = require_keys(:cashier_id, :order_id)
    #
    def require_keys(*keys)
      keys.map { |key| payload.fetch(key) }
    end
  end
end
