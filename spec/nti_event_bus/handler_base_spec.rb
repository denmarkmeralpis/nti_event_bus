# frozen_string_literal: true

RSpec.describe NtiEventBus::HandlerBase do
  describe '#initialize' do
    it 'wraps the payload with indifferent access and freezes it' do
      handler = described_class.new(foo: 'bar')

      expect(handler.payload[:foo]).to eq('bar')
      expect(handler.payload['foo']).to eq('bar')
      expect(handler.payload).to be_frozen
    end
  end

  describe '#call' do
    it 'raises NotImplementedError' do
      expect { described_class.new({}).call }
        .to raise_error(NotImplementedError, /HandlerBase#call must be implemented/)
    end
  end

  describe '#require_keys' do
    let(:subclass) do
      Class.new(described_class) do
        def extract(*keys)
          require_keys(*keys)
        end
      end
    end

    it 'returns the values for the given keys' do
      handler = subclass.new(foo: 'bar', baz: 'qux')

      expect(handler.extract(:foo, :baz)).to eq(%w[bar qux])
    end

    it 'raises KeyError when a key is missing' do
      handler = subclass.new(foo: 'bar')

      expect { handler.extract(:missing) }.to raise_error(KeyError)
    end
  end
end
