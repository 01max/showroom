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
    subject(:result) do
      described_class.new('products' => [{ 'title' => 'Lorem Road Bike', 'handle' => 'lorem-road-bike' }])
    end

    it 'returns an array of ProductSuggestion' do
      expect(result.products).to all(be_a(Showroom::Search::ProductSuggestion))
    end

    it 'maps title correctly' do
      expect(result.products.first.title).to eq('Lorem Road Bike')
    end

    it 'maps handle correctly' do
      expect(result.products.first.handle).to eq('lorem-road-bike')
    end
  end

  # -----------------------------------------------------------------------
  # collections
  # -----------------------------------------------------------------------
  describe '#collections' do
    subject(:result) do
      described_class.new('collections' => [{ 'title' => 'Lorem Helmets', 'handle' => 'lorem-helmets' }])
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
      described_class.new('pages' => [{ 'title' => 'About Lorem Bikes', 'handle' => 'about-lorem-bikes' }])
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
      described_class.new('articles' => [{ 'title' => 'How to Choose a Road Bike', 'handle' => 'how-to-choose' }])
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
      described_class.new('queries' => [{ 'text' => 'lorem road bike' }])
    end

    it 'returns an array of QuerySuggestion' do
      expect(result.queries).to all(be_a(Showroom::Search::QuerySuggestion))
    end

    it 'maps text correctly' do
      expect(result.queries.first.text).to eq('lorem road bike')
    end
  end
end
