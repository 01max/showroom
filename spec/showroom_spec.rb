# frozen_string_literal: true

RSpec.describe Showroom do
  after { described_class.reset! }

  describe 'VERSION' do
    it 'is a string' do
      expect(Showroom::Core::VERSION).to be_a(String)
    end

    it 'matches semver format' do
      expect(Showroom::Core::VERSION).to match(/\A\d+\.\d+\.\d+(-[a-zA-Z0-9.]+)?\z/)
    end
  end

  describe '.configure' do
    it 'yields the module itself' do
      yielded = nil
      described_class.configure { |c| yielded = c }
      expect(yielded).to be(described_class)
    end

    it 'persists configuration' do
      described_class.configure { |c| c.store = 'configured.myshopify.com' }
      expect(described_class.store).to eq('configured.myshopify.com')
    end

    it 'resets the memoized client' do
      described_class.configure { |c| c.store = 'first.fr' }
      first_client = described_class.client
      described_class.configure { |c| c.store = 'second.fr' }
      expect(described_class.client).not_to be(first_client)
    end
  end

  describe '.client' do
    it 'returns a Showroom::Client' do
      described_class.configure { |c| c.store = 'example.myshopify.com' }
      expect(described_class.client).to be_a(Showroom::Client)
    end

    it 'is memoized across calls' do
      described_class.configure { |c| c.store = 'example.myshopify.com' }
      first_client = described_class.client
      expect(described_class.client).to be(first_client)
    end
  end

  describe '.reset!' do
    it 'clears the memoized client' do
      described_class.configure { |c| c.store = 'example.myshopify.com' }
      old_client = described_class.client
      described_class.reset!
      described_class.configure { |c| c.store = 'example.myshopify.com' }
      expect(described_class.client).not_to be(old_client)
    end

    it 'resets store to the default' do
      described_class.configure { |c| c.store = 'example.myshopify.com' }
      described_class.reset!
      expect(described_class.store).to be_nil
    end
  end

  describe '.setup' do
    it 'is an alias for configure' do
      described_class.setup { |c| c.store = 'setup.fr' }
      expect(described_class.store).to eq('setup.fr')
    end
  end
end
