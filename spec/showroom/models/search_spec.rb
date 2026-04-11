# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Showroom::Search do
  let(:base_url) { 'https://example.myshopify.com' }
  let(:suggest_url) { "#{base_url}/search/suggest.json" }
  let(:body) { fixture('search_suggest.json') }

  before do
    Showroom.configure { |c| c.store = 'example.myshopify.com' }
    stub_request(:get, suggest_url)
      .with(query: hash_including('q' => 'lorem'))
      .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })
  end

  after { Showroom.reset! }

  # -----------------------------------------------------------------------
  # .suggest — return type
  # -----------------------------------------------------------------------
  describe '.suggest' do
    it 'returns a Search::Result' do
      expect(described_class.suggest('lorem')).to be_a(Showroom::Search::Result)
    end

    # -----------------------------------------------------------------------
    # Query param serialization
    # -----------------------------------------------------------------------
    it 'sets resources[type] to comma-joined type names' do
      stub_request(:get, suggest_url)
        .with(query: hash_including('resources[type]' => 'product,collection'))
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })

      expect(described_class.suggest('lorem', types: %i[product collection])).to be_a(Showroom::Search::Result)
    end

    it 'sets resources[limit] from the limit: keyword' do
      stub_request(:get, suggest_url)
        .with(query: hash_including('resources[limit]' => '5'))
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })

      expect(described_class.suggest('lorem', limit: 5)).to be_a(Showroom::Search::Result)
    end

    it 'omits resources[type] when types is empty' do
      stub_request(:get, suggest_url)
        .with(query: hash_excluding('resources[type]'))
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })

      expect(described_class.suggest('lorem', types: [])).to be_a(Showroom::Search::Result)
    end

    it 'sets q to the query string' do
      stub_request(:get, suggest_url)
        .with(query: hash_including('q' => 'lorem'))
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })

      expect(described_class.suggest('lorem')).to be_a(Showroom::Search::Result)
    end

    # -----------------------------------------------------------------------
    # Result content
    # -----------------------------------------------------------------------
    it 'result.products returns an array of ProductSuggestion' do
      result = described_class.suggest('lorem')
      expect(result.products).to all(be_a(Showroom::Search::ProductSuggestion))
    end

    it 'result.products has 2 entries from the fixture' do
      expect(described_class.suggest('lorem').products.length).to eq(2)
    end

    it 'result.products first entry has the correct handle' do
      expect(described_class.suggest('lorem').products.first.handle).to eq('lorem-road-bike')
    end

    it 'result.queries returns QuerySuggestion instances' do
      result = described_class.suggest('lorem')
      expect(result.queries).to all(be_a(Showroom::Search::QuerySuggestion))
    end

    it 'result.queries first entry has the correct text' do
      expect(described_class.suggest('lorem').queries.first.text).to eq('lorem road bike')
    end
  end

  # -----------------------------------------------------------------------
  # Showroom.search delegator
  # -----------------------------------------------------------------------
  describe 'Showroom.search' do
    it 'returns a Search::Result' do
      expect(Showroom.search('lorem')).to be_a(Showroom::Search::Result)
    end
  end

  # -----------------------------------------------------------------------
  # Client#search
  # -----------------------------------------------------------------------
  describe 'client#search' do
    it 'returns a Search::Result' do
      expect(Showroom.client.search('lorem')).to be_a(Showroom::Search::Result)
    end

    it 'returns products with correct type' do
      result = Showroom.client.search('lorem')
      expect(result.products).to all(be_a(Showroom::Search::ProductSuggestion))
    end
  end
end
