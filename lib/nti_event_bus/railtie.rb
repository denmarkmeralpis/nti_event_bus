# frozen_string_literal: true

require 'rails/railtie'

module NtiEventBus
  # Rails integration: sets sensible event-file path defaults and (re)builds the registry whenever the
  # framework prepares the app. `to_prepare` runs once during boot in production and on every code
  # reload in development, so event-file edits are picked up and stale handler references are released.
  class Railtie < ::Rails::Railtie
    initializer 'nti_event_bus.set_defaults' do
      NtiEventBus.configure do |config|
        config.root_events_file ||= Rails.root.join('config/events.rb').to_s
        config.events_dir ||= Rails.root.join('config/events').to_s
      end
    end

    config.to_prepare do
      NtiEventBus.setup!
    end
  end
end
