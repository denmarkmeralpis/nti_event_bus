# frozen_string_literal: true

RSpec.describe NtiEventBus do
  let(:dispatched) { [] }
  let(:recording_dispatcher) { ->(name, payload) { dispatched << [name, payload] } }

  around do |example|
    Dir.mktmpdir do |dir|
      @events_dir = dir
      File.write(File.join(dir, 'events.rb'), "draw :internal_events\n")
      File.write(File.join(dir, 'internal_events.rb'), <<~RUBY)
        on_event 'order.created' do
          perform FakeHandlerA
          perform FakeHandlerB
        end

        on_event 'order.voided' do
          perform FakeHandlerA
        end
      RUBY
      example.run
    end
  end

  before do
    stub_const('FakeHandlerA', Class.new)
    stub_const('FakeHandlerB', Class.new)

    NtiEventBus.configure do |config|
      config.root_events_file = File.join(@events_dir, 'events.rb')
      config.events_dir = @events_dir
      config.dispatcher = recording_dispatcher
    end
  end

  describe '.setup! / .registry' do
    it 'builds a deep-frozen registry from the event files, resolving draw' do
      NtiEventBus.setup!

      expect(NtiEventBus.registry.handlers_for('order.created')).to eq([FakeHandlerA, FakeHandlerB])
      expect(NtiEventBus.registry.handlers_for('order.created')).to be_frozen
    end

    it 'raises NotConfiguredError when read before setup!' do
      expect { NtiEventBus.registry }.to raise_error(NtiEventBus::NotConfiguredError)
    end

    it 'rebuilds and atomically swaps in a fresh registry on each call' do
      NtiEventBus.setup!
      first = NtiEventBus.registry

      NtiEventBus.setup!
      second = NtiEventBus.registry

      expect(second).not_to equal(first)
      expect(second.handlers_for('order.voided')).to eq([FakeHandlerA])
    end
  end

  describe '.publish' do
    before { NtiEventBus.setup! }

    it 'dispatches once per subscribed handler, by class name, with the payload' do
      payload = { order_id: 7 }

      NtiEventBus.publish('order.created', payload)

      expect(dispatched).to eq([['FakeHandlerA', payload], ['FakeHandlerB', payload]])
    end

    it 'is a no-op for events with no subscribers' do
      expect(NtiEventBus.publish('unknown.event', {})).to be_nil
      expect(dispatched).to be_empty
    end

    it 'returns nil' do
      expect(NtiEventBus.publish('order.voided', {})).to be_nil
    end
  end

  describe 'default asynchronous dispatch via ActiveJob' do
    before do
      NtiEventBus.configuration.dispatcher = NtiEventBus::Dispatchers::ActiveJob.new
      NtiEventBus.setup!
    end

    it 'enqueues one HandleEventJob per subscribed handler' do
      expect { NtiEventBus.publish('order.created', { order_id: 1 }) }
        .to change { ActiveJob::Base.queue_adapter.enqueued_jobs.size }.by(2)
    end
  end
end
