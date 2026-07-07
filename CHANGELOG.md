# Changelog

## [0.1.0] - 2026-07-07

- Initial release. Extracted from the Tindahang Tapat OnPrem application.
- `NtiEventBus.publish` fans a `domain.action` event out to subscribed handler classes.
- `NtiEventBus::DSL` (`draw` / `on_event` / `perform`) declares subscriptions loaded from event files.
- `NtiEventBus::Registry` — deep-frozen after `finalize!` for lock-free reads.
- `NtiEventBus::HandlerBase` — base class for handlers (indifferent-access frozen payload, `require_keys`).
- `NtiEventBus::HandleEventJob` — ActiveJob-backed asynchronous dispatch on a configurable queue.
- `NtiEventBus::Dispatchers::ActiveJob` (default) and `NtiEventBus::Dispatchers::Inline`.
- `NtiEventBus::Railtie` — sets event-file path defaults and rebuilds the registry on `to_prepare`.
