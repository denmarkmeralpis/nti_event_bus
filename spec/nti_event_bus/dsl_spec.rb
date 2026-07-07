# frozen_string_literal: true

RSpec.describe NtiEventBus::DSL do
  subject(:dsl) { described_class.new(registry, events_dir) }

  let(:registry) { NtiEventBus::Registry.new }
  let(:events_dir) { nil }
  let(:first_handler) { Class.new }
  let(:second_handler) { Class.new }

  describe '#on_event / #perform' do
    it 'registers handlers declared inside an event block' do
      first = first_handler
      second = second_handler

      dsl.instance_eval do
        on_event 'order.created' do
          perform first
          perform second
        end
      end

      expect(registry.handlers_for('order.created')).to eq([first_handler, second_handler])
    end

    it 'accepts an array of handlers in a single perform' do
      handlers = [first_handler, second_handler]

      dsl.instance_eval { on_event('order.created') { perform handlers } }

      expect(registry.handlers_for('order.created')).to eq([first_handler, second_handler])
    end

    it 'resets the current event after each block so sibling events register independently' do
      first = first_handler
      second = second_handler

      dsl.instance_eval do
        on_event('order.created') { perform first }
        on_event('order.voided') { perform second }
      end

      expect(registry.handlers_for('order.created')).to eq([first_handler])
      expect(registry.handlers_for('order.voided')).to eq([second_handler])
    end

    it 'raises when perform is called outside on_event' do
      expect { dsl.perform(first_handler) }.to raise_error(ArgumentError, /perform must be inside/)
    end

    it 'raises on nested on_event' do
      expect do
        dsl.instance_eval { on_event('order.created') { on_event('x.y') {} } }
      end.to raise_error(ArgumentError, /Nested/)
    end

    it 'raises when no block is given' do
      expect { dsl.on_event('order.created') }.to raise_error(ArgumentError, /Block required/)
    end
  end

  describe 'event-name validation' do
    it 'rejects non-strings' do
      expect { dsl.on_event(:symbol) {} }.to raise_error(ArgumentError, /must be a String/)
    end

    it 'rejects blank names' do
      expect { dsl.on_event('   ') {} }.to raise_error(ArgumentError, /cannot be empty/)
    end

    it "rejects names that are not in 'domain.action' form" do
      expect { dsl.on_event('created') {} }.to raise_error(ArgumentError, /domain\.action/)
    end
  end

  describe '#draw' do
    let(:events_dir) { Dir.mktmpdir }

    after { FileUtils.remove_entry(events_dir) }

    it 'evaluates a nested event file resolved from events_dir' do
      handler = first_handler
      stub_const('DrawnHandler', handler)
      File.write(File.join(events_dir, 'more.rb'), <<~RUBY)
        on_event 'billing.charged' do
          perform DrawnHandler
        end
      RUBY

      dsl.draw('more')

      expect(registry.handlers_for('billing.charged')).to eq([handler])
    end

    it 'raises LoadError when the drawn file is missing' do
      expect { dsl.draw('missing') }.to raise_error(LoadError, /Event file not found/)
    end

    it 'raises NotConfiguredError when events_dir is not set' do
      dsl_without_dir = described_class.new(registry, nil)

      expect { dsl_without_dir.draw('more') }.to raise_error(NtiEventBus::NotConfiguredError)
    end
  end
end
