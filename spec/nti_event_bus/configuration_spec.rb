# frozen_string_literal: true

RSpec.describe NtiEventBus::Configuration do
  subject(:config) { described_class.new }

  it 'defaults the queue name to :events' do
    expect(config.queue_name).to eq(:events)
  end

  it 'defaults the dispatcher to asynchronous ActiveJob dispatch' do
    expect(config.dispatcher).to be_a(NtiEventBus::Dispatchers::ActiveJob)
  end

  it 'memoizes the default dispatcher' do
    expect(config.dispatcher).to equal(config.dispatcher)
  end

  it 'accepts a custom dispatcher' do
    custom = ->(_name, _payload) {}
    config.dispatcher = custom

    expect(config.dispatcher).to equal(custom)
  end

  describe '#root_events_file!' do
    it 'raises NotConfiguredError when unset' do
      expect { config.root_events_file! }.to raise_error(NtiEventBus::NotConfiguredError)
    end

    it 'returns the path when set' do
      config.root_events_file = '/tmp/events.rb'

      expect(config.root_events_file!).to eq('/tmp/events.rb')
    end
  end
end
