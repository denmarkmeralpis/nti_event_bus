# frozen_string_literal: true

module NtiEventBus
  # Maps event names to the ordered, de-duplicated list of handler classes subscribed to them.
  #
  # Built once during `NtiEventBus.setup!` and then deep-frozen via `#finalize!`, which makes reads
  # (`#handlers_for`) lock-free and allocation-free on the hot path.
  class Registry
    EMPTY = [].freeze

    def initialize
      @handlers = Hash.new { |hash, key| hash[key] = [] }
    end

    def add(event_name, handler)
      list = @handlers[event_name]
      list << handler unless list.include?(handler)
    end

    def finalize!
      @handlers.each_value(&:freeze)
      @handlers.freeze
      self
    end

    def handlers_for(event_name)
      @handlers.fetch(event_name, EMPTY)
    end
  end
end
