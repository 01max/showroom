# frozen_string_literal: true

RSpec.describe Showroom::Client do
  describe '#initialize' do
    it 'accepts a store: keyword argument' do
      client = described_class.new(store: 'example.myshopify.com')
      expect(client.store).to eq('example.myshopify.com')
    end

    it 'starts with default per_page when not provided' do
      client = described_class.new(store: 'example.myshopify.com')
      expect(client.per_page).to eq(Showroom::Core::Default.per_page)
    end

    it 'accepts per_page override' do
      client = described_class.new(store: 'example.myshopify.com', per_page: 100)
      expect(client.per_page).to eq(100)
    end

    it 'clamps per_page to MAX_PER_PAGE' do
      client = described_class.new(store: 'example.myshopify.com', per_page: 9999)
      expect(client.per_page).to eq(Showroom::Core::Default::MAX_PER_PAGE)
    end

    it 'accepts timeout override' do
      client = described_class.new(store: 'example.myshopify.com', timeout: 60)
      expect(client.timeout).to eq(60)
    end
  end

  describe '#options snapshot' do
    subject(:client) { described_class.new(store: 'example.myshopify.com') }

    it 'includes all KEYS' do
      expect(client.options.keys).to match_array(Showroom::Core::Configurable::KEYS)
    end

    it 'reflects the configured store' do
      expect(client.options[:store]).to eq('example.myshopify.com')
    end
  end

  describe 'connection delegation' do
    subject(:client) { described_class.new(store: 'example.myshopify.com') }

    before do
      stub_request(:get, %r{example\.myshopify\.com/products\.json})
        .to_return(
          status: 200,
          body: '{"products":[{"id":42}]}',
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'can perform a GET request' do
      result = client.get('/products.json')
      expect(result).to eq({ 'products' => [{ 'id' => 42 }] })
    end

    it 'stores last_response after a request' do
      client.get('/products.json')
      expect(client.last_response).not_to be_nil
    end
  end
end
