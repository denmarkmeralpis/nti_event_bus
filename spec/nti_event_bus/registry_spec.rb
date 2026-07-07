# frozen_string_literal: true

RSpec.describe NtiEventBus::Registry do
  subject(:registry) { described_class.new }

  let(:handler_a) { Class.new }
  let(:handler_b) { Class.new }

  describe '#add / #handlers_for' do
    it 'stores handlers per event, preserving declaration order' do
      registry.add('order.created', handler_a)
      registry.add('order.created', handler_b)

      expect(registry.handlers_for('order.created')).to eq([handler_a, handler_b])
    end

    it 'de-duplicates the same handler for an event' do
      registry.add('order.created', handler_a)
      registry.add('order.created', handler_a)

      expect(registry.handlers_for('order.created')).to eq([handler_a])
    end

    it 'returns the shared frozen EMPTY array for unknown events' do
      expect(registry.handlers_for('nope.none')).to equal(NtiEventBus::Registry::EMPTY)
      expect(registry.handlers_for('nope.none')).to be_frozen
    end
  end

  describe '#finalize!' do
    before do
      registry.add('order.created', handler_a)
      registry.finalize!
    end

    it 'freezes each handler list' do
      expect(registry.handlers_for('order.created')).to be_frozen
    end

    it 'prevents any further mutation' do
      expect { registry.add('order.created', handler_b) }.to raise_error(FrozenError)
    end

    it 'returns the registry' do
      expect(described_class.new.finalize!).to be_a(described_class)
    end
  end
end
