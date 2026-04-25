# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Showroom::Search::CollectionSuggestion do
  describe '#url' do
    let(:suggestion) { described_class.new('handle' => 'lorem-helmets') }

    context 'with no instance client set' do
      before { Showroom.configure { |c| c.store = 'example.myshopify.com' } }
      after  { Showroom.reset! }

      it 'falls back to Showroom.client base_url' do
        expect(suggestion.url).to eq('https://example.myshopify.com/collections/lorem-helmets')
      end
    end

    context 'with an instance client set' do
      it 'uses the instance client base_url' do
        suggestion.client = Showroom::Client.new(store: 'other-store.myshopify.com')
        expect(suggestion.url).to eq('https://other-store.myshopify.com/collections/lorem-helmets')
      end
    end
  end
end
