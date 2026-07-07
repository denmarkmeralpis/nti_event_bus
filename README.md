# NTI Event Bus

A small, production-grade **publish/subscribe event bus** for Ruby & Rails.

Declare `domain.action` subscriptions in a compact DSL, `publish` events, and fan them out to handler classes **asynchronously** via ActiveJob. The subscription registry is built once at boot and **deep-frozen**, so publishing is a lock-free hash lookup with no per-call allocation and no long-lived, unbounded state — no thread pools, no notification subscribers, nothing to leak.

```
publisher → NtiEventBus.publish("order.created", payload)
              → registry.handlers_for("order.created")   # frozen O(1) lookup
                  → dispatcher.call(handler_name, payload)
                      → NtiEventBus::HandleEventJob (ActiveJob, async)
                          → Handler.new(payload).call
```

## Installation

```ruby
gem 'nti_event_bus'
```

## Rails usage

On Rails the bundled `NtiEventBus::Railtie` wires everything up automatically:

- Defaults `configuration.root_events_file` to `config/events.rb` and `configuration.events_dir` to
  `config/events/`.
- Rebuilds the registry on every `to_prepare` (once in production; per code-reload in development, so edits to event files are picked up and old handler references are released).

Define the root events file and one or more drawn files:

```ruby
# config/events.rb
draw :internal_events

# config/events/internal_events.rb
on_event 'order.created' do
  perform Orders::Handlers::Created
  perform Notifications::Handlers::OrderCreated
end
```

Publish from anywhere:

```ruby
NtiEventBus.publish('order.created', { order_id: order.id })
```

Write handlers by subclassing `HandlerBase`:

```ruby
module Orders::Handlers
  class Created < NtiEventBus::HandlerBase
    def call
      order_id = payload.fetch(:order_id)   # payload is an indifferent-access, frozen hash
      # ...
    end
  end
end
```

## Configuration

```ruby
NtiEventBus.configure do |config|
  config.root_events_file = Rails.root.join('config/events.rb').to_s  # defaulted by the Railtie
  config.events_dir       = Rails.root.join('config/events').to_s     # defaulted by the Railtie
  config.queue_name       = :events                                   # ActiveJob queue (default)
  config.dispatcher       = NtiEventBus::Dispatchers::ActiveJob.new    # default; async
  config.logger           = Rails.logger                              # optional
end
```

### Dispatchers

- `NtiEventBus::Dispatchers::ActiveJob` (default) — enqueues `HandleEventJob` on `config.queue_name`.
- `NtiEventBus::Dispatchers::Inline` — runs the handler synchronously in-process (tests / non-ActiveJob hosts).
- Any object responding to `#call(handler_name, payload)` may be used.

## Non-Rails usage

```ruby
NtiEventBus.configure do |config|
  config.root_events_file = '/path/to/events.rb'
  config.events_dir       = '/path/to/events'
end
NtiEventBus.setup!          # build the registry
NtiEventBus.publish('order.created', { order_id: 1 })
```

## Thread-safety & reloads

`setup!` builds a fresh `Registry`, deep-freezes it, and atomically swaps it in under a mutex. Readers always see a fully-frozen registry (the previous one or the new one), so `publish` never locks and never observes a half-built registry.

## Event naming

Event names must be non-empty strings in `domain.action` form (they must contain a `.`). This is enforced at subscription time by the DSL.

## License

MIT.
