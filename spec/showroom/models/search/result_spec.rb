# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Showroom::Search::Result do
  # -----------------------------------------------------------------------
  # Empty hash — all accessors return []
  # -----------------------------------------------------------------------
  describe 'when initialized with an empty hash' do
    subject(:result) { described_class.new({}) }

    it 'returns [] for products' do
      expect(result.products).to eq([])
    end

    it 'returns [] for collections' do
      expect(result.collections).to eq([])
    end

    it 'returns [] for pages' do
      expect(result.pages).to eq([])
    end

    it 'returns [] for articles' do
      expect(result.articles).to eq([])
    end

    it 'returns [] for queries' do
      expect(result.queries).to eq([])
    end
  end

  # -----------------------------------------------------------------------
  # products
  # -----------------------------------------------------------------------
  describe '#products' do
    subject(:result) { described_class.new({ 'products' => raw_products }) }

    let(:raw_products) do
      [
        { 'id' => 3, 'title' => 'Zeta Bike',  'handle' => 'zeta-bike',  'price' => '300.00' },
        { 'id' => 1, 'title' => 'Alpha Bike', 'handle' => 'alpha-bike', 'price' => '1200.00' },
        { 'id' => 2, 'title' => 'Beta Bike',  'handle' => 'beta-bike',  'price' => '50.00' }
      ]
    end

    it 'returns an array of ProductSuggestion' do
      expect(result.products).to all(be_a(Showroom::Search::ProductSuggestion))
    end

    it 'preserves API order by default' do
      expect(result.products.map(&:title)).to eq(['Zeta Bike', 'Alpha Bike', 'Beta Bike'])
    end

    context 'with order: :title' do
      it 'sorts alphabetically by title' do
        expect(result.products(order: :title).map(&:title)).to eq(['Alpha Bike', 'Beta Bike', 'Zeta Bike'])
      end
    end

    context 'with order: :handle' do
      it 'sorts alphabetically by handle' do
        expect(result.products(order: :handle).map(&:handle)).to eq(%w[alpha-bike beta-bike zeta-bike])
      end
    end

    context 'with order: :id' do
      it 'sorts numerically by id' do
        expect(result.products(order: :id).map(&:id)).to eq([1, 2, 3])
      end
    end

    context 'with order: :price' do
      it 'sorts numerically by price' do
        expect(result.products(order: :price).map(&:price)).to eq(%w[50.00 300.00 1200.00])
      end
    end

    context 'with an unsupported order attribute' do
      it 'raises ArgumentError' do
        expect { result.products(order: :vendor) }.to raise_error(ArgumentError)
      end
    end
  end

  # -----------------------------------------------------------------------
  # collections
  # -----------------------------------------------------------------------
  describe '#collections' do
    subject(:result) do
      described_class.new({ 'collections' => [{ 'title' => 'Lorem Helmets', 'handle' => 'lorem-helmets' }] })
    end

    it 'returns an array of CollectionSuggestion' do
      expect(result.collections).to all(be_a(Showroom::Search::CollectionSuggestion))
    end

    it 'maps title correctly' do
      expect(result.collections.first.title).to eq('Lorem Helmets')
    end
  end

  # -----------------------------------------------------------------------
  # pages
  # -----------------------------------------------------------------------
  describe '#pages' do
    subject(:result) do
      described_class.new({ 'pages' => [{ 'title' => 'About Lorem Bikes', 'handle' => 'about-lorem-bikes' }] })
    end

    it 'returns an array of PageSuggestion' do
      expect(result.pages).to all(be_a(Showroom::Search::PageSuggestion))
    end

    it 'maps title correctly' do
      expect(result.pages.first.title).to eq('About Lorem Bikes')
    end
  end

  # -----------------------------------------------------------------------
  # articles
  # -----------------------------------------------------------------------
  describe '#articles' do
    subject(:result) do
      described_class.new({ 'articles' => [{ 'title' => 'How to Choose a Road Bike', 'handle' => 'how-to-choose' }] })
    end

    it 'returns an array of ArticleSuggestion' do
      expect(result.articles).to all(be_a(Showroom::Search::ArticleSuggestion))
    end

    it 'maps title correctly' do
      expect(result.articles.first.title).to eq('How to Choose a Road Bike')
    end
  end

  # -----------------------------------------------------------------------
  # queries
  # -----------------------------------------------------------------------
  describe '#queries' do
    subject(:result) do
      described_class.new({ 'queries' => [{ 'text' => 'lorem road bike' }] })
    end

    it 'returns an array of QuerySuggestion' do
      expect(result.queries).to all(be_a(Showroom::Search::QuerySuggestion))
    end

    it 'maps text correctly' do
      expect(result.queries.first.text).to eq('lorem road bike')
    end
  end

  # -----------------------------------------------------------------------
  # client propagation
  # -----------------------------------------------------------------------
  describe 'client propagation' do
    subject(:result) { described_class.new(data, client: client) }

    let(:client) { Showroom::Client.new(store: 'example.myshopify.com') }

    let(:data) do
      {
        'products' => [{ 'handle' => 'p1' }],
        'collections' => [{ 'handle' => 'c1' }],
        'pages' => [{ 'handle' => 'pg1' }],
        'articles' => [{ 'handle' => 'a1' }],
        'queries' => [{ 'text' => 'q1' }]
      }
    end

    it 'sets the client on product suggestions' do
      expect(result.products.first.client).to be(client)
    end

    it 'sets the client on collection suggestions' do
      expect(result.collections.first.client).to be(client)
    end

    it 'sets the client on page suggestions' do
      expect(result.pages.first.client).to be(client)
    end

    it 'sets the client on article suggestions' do
      expect(result.articles.first.client).to be(client)
    end

    it 'sets the client on query suggestions' do
      expect(result.queries.first.client).to be(client)
    end

    context 'when no client is given' do
      subject(:result) { described_class.new(data) }

      it 'leaves client nil on suggestions' do
        expect(result.products.first.client).to be_nil
      end
    end
  end
end
