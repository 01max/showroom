# frozen_string_literal: true

RSpec.describe Showroom::Core::Countable do
  let(:base_url) { 'https://example.myshopify.com' }
  let(:max)      { described_class::MAX_PER_PAGE }

  before { Showroom.configure { |c| c.store = 'example.myshopify.com' } }
  after  { Showroom.reset! }

  # Stub a page to return a given number of product hashes.
  # Pass size: :out_of_bounds to simulate Shopify's 400 for pages beyond the last.
  def stub_page(page, size)
    stub_request(:get, "#{base_url}/products.json")
      .with(query: hash_including('page' => page.to_s, 'limit' => max.to_s))
      .to_return(**stub_page_response(page, size))
  end

  def stub_page_response(page, size)
    return { status: 400, body: '{}', headers: { 'Content-Type' => 'application/json' } } if size == :out_of_bounds

    body = { 'products' => Array.new(size) { |i| { 'id' => (page * max) + i } } }.to_json
    { status: 200, body: body, headers: { 'Content-Type' => 'application/json' } }
  end

  describe '#calculate_count' do
    context 'when the store has no products' do
      before { stub_page(1, 0) }

      it 'returns 0' do
        expect(Showroom::Product.calculate_count).to eq(0)
      end
    end

    context 'when all products fit on one partial page' do
      before { stub_page(1, 42) }

      it 'returns the exact count' do
        expect(Showroom::Product.calculate_count).to eq(42)
      end
    end

    context 'when products fill exactly one full page' do
      before do
        stub_page(1, max)
        stub_page(2, 0)
      end

      it 'returns 250' do
        expect(Showroom::Product.calculate_count).to eq(max)
      end
    end

    context 'when products span multiple full pages plus a partial last page' do
      # 3 full pages (750) + 37 on page 4 = 787
      before do
        stub_page(1, max)
        stub_page(2, max)
        stub_page(3, max)
        stub_page(4, 37)
        stub_page(5, 0)
      end

      it 'returns the correct total' do
        expect(Showroom::Product.calculate_count).to eq((3 * max) + 37)
      end
    end

    context 'when products span many pages (exercises binary search)' do
      # 8 full pages + 100 on page 9 = 2100
      # Probe sequence: 1,2,4,8 (full) → 16 (empty) → binary search 8..16
      # Binary search hits: 12 (empty) → 10 (empty) → 9 (partial)
      before do
        (1..8).each { |p| stub_page(p, max) }
        stub_page(9, 100)
        [10, 11, 12, 13, 14, 15, 16].each { |p| stub_page(p, 0) }
      end

      it 'returns the correct total' do
        expect(Showroom::Product.calculate_count).to eq((8 * max) + 100)
      end
    end

    context 'when Shopify returns 400 for out-of-bounds pages' do
      # Same shape as above but out-of-range pages return 400 instead of empty array
      before do
        (1..8).each { |p| stub_page(p, max) }
        stub_page(9, 100)
        [10, 11, 12, 13, 14, 15, 16].each { |p| stub_page(p, :out_of_bounds) }
      end

      it 'treats 400 as an empty page and returns the correct total' do
        expect(Showroom::Product.calculate_count).to eq((8 * max) + 100)
      end
    end

    context 'when called on Collection' do
      before do
        body = { 'collections' => [{ 'id' => 1, 'handle' => 'lorem' }] }.to_json
        stub_request(:get, "#{base_url}/collections.json")
          .with(query: hash_including('page' => '1', 'limit' => max.to_s))
          .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })
        stub_request(:get, "#{base_url}/collections.json")
          .with(query: hash_including('page' => '2', 'limit' => max.to_s))
          .to_return(status: 200, body: '{"collections":[]}',
                     headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns the correct count for collections' do
        expect(Showroom::Collection.calculate_count).to eq(1)
      end
    end
  end
end
