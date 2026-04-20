# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Showroom::Collection do
  before do
    Showroom.configure { |c| c.store = 'example.myshopify.com' }
  end

  after do
    Showroom.reset!
  end

  let(:collections_body)        { fixture('collections.json') }
  let(:collection_body)         { fixture('collection.json') }
  let(:collection_products_body) { fixture('collection_products.json') }

  let(:base_url) { 'https://example.myshopify.com' }

  # -----------------------------------------------------------------------
  # .where
  # -----------------------------------------------------------------------
  describe '.where' do
    before do
      stub_request(:get, "#{base_url}/collections.json")
        .with(query: hash_including({}))
        .to_return(status: 200, body: collections_body, headers: { 'Content-Type' => 'application/json' })
    end

    it 'returns an array of Collection instances' do
      expect(described_class.where).to all(be_a(described_class))
    end

    it 'returns 2 collections from the fixture' do
      expect(described_class.where.length).to eq(2)
    end

    it 'maps the title of the first collection correctly' do
      expect(described_class.where.first.title).to eq('Lorem Helmets')
    end

    it 'maps the handle of the first collection correctly' do
      expect(described_class.where.first.handle).to eq('lorem-helmets')
    end

    it 'passes params as query parameters' do
      stub_request(:get, "#{base_url}/collections.json")
        .with(query: hash_including('title' => 'Lorem Helmets'))
        .to_return(status: 200, body: collections_body, headers: { 'Content-Type' => 'application/json' })

      result = described_class.where(title: 'Lorem Helmets')
      expect(result).not_to be_empty
    end

    context 'when the response has no collections' do
      before do
        stub_request(:get, "#{base_url}/collections.json")
          .with(query: hash_including({}))
          .to_return(status: 200, body: '{"collections":[]}',
                     headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns an empty array' do
        expect(described_class.where).to eq([])
      end
    end
  end

  # -----------------------------------------------------------------------
  # .find
  # -----------------------------------------------------------------------
  describe '.find' do
    context 'when the collection exists' do
      before do
        stub_request(:get, "#{base_url}/collections/lorem-helmets.json")
          .with(query: hash_including({}))
          .to_return(status: 200, body: collection_body, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns a Collection instance' do
        expect(described_class.find('lorem-helmets')).to be_a(described_class)
      end

      it 'returns the collection with the correct handle' do
        expect(described_class.find('lorem-helmets').handle).to eq('lorem-helmets')
      end

      it 'returns the collection with the correct title' do
        expect(described_class.find('lorem-helmets').title).to eq('Lorem Helmets')
      end

      it 'returns the collection with the correct id' do
        expect(described_class.find('lorem-helmets').id).to eq(4_000_000_000_001)
      end
    end

    context 'when the collection is not found (404)' do
      before do
        stub_request(:get, "#{base_url}/collections/nonexistent.json")
          .with(query: hash_including({}))
          .to_return(status: 404, body: '{"errors":"Not Found"}',
                     headers: { 'Content-Type' => 'application/json' })
      end

      it 'raises Showroom::NotFound' do
        expect { described_class.find('nonexistent') }.to raise_error(Showroom::NotFound)
      end
    end
  end

  # -----------------------------------------------------------------------
  # #products
  # -----------------------------------------------------------------------
  describe '#products' do
    subject(:collection) { described_class.new(JSON.parse(collection_body)['collection']) }

    before do
      stub_request(:get, "#{base_url}/collections/lorem-helmets/products.json")
        .with(query: hash_including({}))
        .to_return(status: 200, body: collection_products_body,
                   headers: { 'Content-Type' => 'application/json' })
    end

    it 'returns an array' do
      expect(collection.products).to be_an(Array)
    end

    it 'returns Showroom::Product instances' do
      expect(collection.products).to all(be_a(Showroom::Product))
    end

    it 'returns the correct number of products' do
      expect(collection.products.length).to eq(2)
    end

    it 'returns products with correct titles' do
      titles = collection.products.map(&:title)
      expect(titles).to include('Lorem Road Bike', 'Ipsum City Cruiser')
    end

    context 'when passing query parameters' do
      before do
        stub_request(:get, "#{base_url}/collections/lorem-helmets/products.json")
          .with(query: { 'limit' => '1' })
          .to_return(status: 200, body: collection_products_body,
                     headers: { 'Content-Type' => 'application/json' })
      end

      it 'forwards params to the API' do
        expect(collection.products(limit: 1)).not_to be_empty
      end
    end
  end

  # -----------------------------------------------------------------------
  # #url
  # -----------------------------------------------------------------------
  describe '#url' do
    subject(:collection) { described_class.new(JSON.parse(collection_body)['collection']) }

    it 'returns the storefront URL for the collection' do
      expect(collection.url).to eq('https://example.myshopify.com/collections/lorem-helmets')
    end

    context 'when fetched via a specific client' do
      let(:client) { Showroom::Client.new(store: 'other-store.myshopify.com') }

      it 'uses the instance client base_url' do
        collection.client = client
        expect(collection.url).to eq('https://other-store.myshopify.com/collections/lorem-helmets')
      end
    end
  end

  # -----------------------------------------------------------------------
  # #products — client awareness
  # -----------------------------------------------------------------------
  describe '#products (client awareness)' do
    let(:other_base_url) { 'https://other-store.myshopify.com' }
    let(:client) { Showroom::Client.new(store: 'other-store.myshopify.com') }
    let(:collection) do
      described_class.new(JSON.parse(collection_body)['collection']).tap { |c| c.client = client }
    end

    before do
      stub_request(:get, "#{other_base_url}/collections/lorem-helmets/products.json")
        .with(query: hash_including({}))
        .to_return(status: 200, body: collection_products_body,
                   headers: { 'Content-Type' => 'application/json' })
    end

    it 'uses the instance client instead of the global client' do
      products = collection.products
      expect(products).to all(be_a(Showroom::Product))
    end

    it 'propagates the client to returned products' do
      products = collection.products
      expect(products.first.client).to eq(client)
    end
  end

  # -----------------------------------------------------------------------
  # Module-level delegators
  # -----------------------------------------------------------------------
  describe 'Showroom.collections' do
    before do
      stub_request(:get, "#{base_url}/collections.json")
        .with(query: hash_including({}))
        .to_return(status: 200, body: collections_body, headers: { 'Content-Type' => 'application/json' })
    end

    it 'returns an array of Collection instances' do
      expect(Showroom.collections).to all(be_a(described_class))
    end
  end

  describe 'Showroom.collection' do
    before do
      stub_request(:get, "#{base_url}/collections/lorem-helmets.json")
        .with(query: hash_including({}))
        .to_return(status: 200, body: collection_body, headers: { 'Content-Type' => 'application/json' })
    end

    it 'returns a Collection instance' do
      expect(Showroom.collection('lorem-helmets')).to be_a(described_class)
    end
  end

  # -----------------------------------------------------------------------
  # Client instance methods
  # -----------------------------------------------------------------------
  describe 'client#collections' do
    before do
      stub_request(:get, "#{base_url}/collections.json")
        .with(query: hash_including({}))
        .to_return(status: 200, body: collections_body, headers: { 'Content-Type' => 'application/json' })
    end

    it 'returns an array of Collection instances' do
      expect(Showroom.client.collections).to all(be_a(described_class))
    end
  end

  describe 'client#collection' do
    before do
      stub_request(:get, "#{base_url}/collections/lorem-helmets.json")
        .with(query: hash_including({}))
        .to_return(status: 200, body: collection_body, headers: { 'Content-Type' => 'application/json' })
    end

    it 'returns a Collection instance' do
      expect(Showroom.client.collection('lorem-helmets')).to be_a(described_class)
    end
  end
end
