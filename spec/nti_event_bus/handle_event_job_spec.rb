# frozen_string_literal: true

RSpec.describe NtiEventBus::HandleEventJob do
  describe '#perform' do
    let(:handler_instance) { instance_double(NtiEventBus::HandlerBase, call: true) }
    let(:handler_class) { class_double(NtiEventBus::HandlerBase, new: handler_instance) }
    let(:payload) { { 'data' => 'some data', 'routing_key' => 'order.created' } }

    before { stub_const('SomeHandler', handler_class) }

    it 'resolves the handler by name, instantiates it with the payload, and calls it' do
      described_class.new.perform('SomeHandler', payload)

      expect(handler_class).to have_received(:new).with(payload)
      expect(handler_instance).to have_received(:call)
    end

    it 'raises NameError when the handler class does not exist' do
      expect { described_class.new.perform('NonExistent::Handler', payload) }.to raise_error(NameError)
    end
  end

  describe 'queue routing' do
    before { stub_const('SomeHandler', Class.new) }

    it 'enqueues on the configured queue name' do
      NtiEventBus.configuration.queue_name = :custom_events

      described_class.perform_later('SomeHandler', {})

      job = ActiveJob::Base.queue_adapter.enqueued_jobs.last
      expect(job[:queue]).to eq('custom_events')
    end
  end
end
