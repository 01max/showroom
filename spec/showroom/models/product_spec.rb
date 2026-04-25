# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Showroom::Product do
  before do
    Showroom.configure { |c| c.store = 'example.myshopify.com' }
  end

  after do
    Showroom.reset!
  end

  let(:products_body)       { fixture('products.json') }
  let(:product_body)        { fixture('product.json') }
  let(:products_empty_body) { fixture('products_empty.json') }

  let(:base_url) { 'https://example.myshopify.com' }

  # -----------------------------------------------------------------------
  # Associations
  # -----------------------------------------------------------------------
  describe 'associations from fixture data' do
    subject(:product) { described_class.new(raw_hash) }

    let(:raw_hash) { JSON.parse(products_body)['products'][0] }

    it 'wraps variants as ProductVariant instances' do
      expect(product.variants.first).to be_a(Showroom::ProductVariant)
    end

    it 'wraps images as ProductImage instances' do
      expect(product.images.first).to be_a(Showroom::ProductImage)
    end

    it 'wraps options as ProductOption instances' do
      expect(product.options.first).to be_a(Showroom::ProductOption)
    end

    it 'has the correct number of variants' do
      expect(product.variants.length).to eq(2)
    end

    it 'has the correct number of images' do
      expect(product.images.length).to eq(3)
    end
  end

  # -----------------------------------------------------------------------
  # Convenience methods
  # -----------------------------------------------------------------------
  describe '#available?' do
    context 'when at least one variant is available (Lorem Road Bike)' do
      let(:product) { described_class.new(JSON.parse(products_body)['products'][0]) }

      it { expect(product.available?).to be(true) }
    end

    context 'when no variant is available (Ipsum City Cruiser)' do
      let(:product) { described_class.new(JSON.parse(products_body)['products'][1]) }

      it { expect(product.available?).to be(false) }
    end

    context 'when a top-level available key is present (true)' do
      let(:product) do
        described_class.new('available' => true,
                            'variants' => [{ 'available' => false }])
      end

      it 'short-circuits and returns true without consulting variants' do
        expect(product.available?).to be(true)
      end
    end

    context 'when a top-level available key is present (false)' do
      let(:product) do
        described_class.new('available' => false,
                            'variants' => [{ 'available' => true }])
      end

      it 'short-circuits and returns false without consulting variants' do
        expect(product.available?).to be(false)
      end
    end

    context 'when no variant exposes availability' do
      let(:product) do
        described_class.new('variants' => [{ 'price' => '10.00' }, { 'price' => '12.00' }])
      end

      it 'returns nil' do
        expect(product.available?).to be_nil
      end
    end

    context 'when variants mix unknown and false' do
      let(:product) do
        described_class.new('variants' => [{ 'available' => false }, { 'price' => '10.00' }])
      end

      it 'returns nil since at least one variant might be available' do
        expect(product.available?).to be_nil
      end
    end

    context 'when variants mix unknown and true' do
      let(:product) do
        described_class.new('variants' => [{ 'available' => true }, { 'price' => '10.00' }])
      end

      it 'returns true' do
        expect(product.available?).to be(true)
      end
    end
  end

  describe '#availability_known?' do
    context 'when the top-level available key is present' do
      let(:product) { described_class.new('available' => false, 'variants' => []) }

      it { expect(product.availability_known?).to be(true) }
    end

    context 'when at least one variant exposes availability' do
      let(:product) do
        described_class.new('variants' => [{ 'price' => '10.00' }, { 'available' => false }])
      end

      it { expect(product.availability_known?).to be(true) }
    end

    context 'when neither the product nor any variant exposes availability' do
      let(:product) do
        described_class.new('variants' => [{ 'price' => '10.00' }, { 'price' => '12.00' }])
      end

      it { expect(product.availability_known?).to be(false) }
    end
  end

  describe '#price' do
    context 'with Lorem Road Bike (prices 899.00 and 749.00)' do
      let(:product) { described_class.new(JSON.parse(products_body)['products'][0]) }

      it 'returns the lowest variant price' do
        expect(product.price).to eq('749.00')
      end
    end

    context 'with no variants' do
      let(:product) { described_class.new('variants' => []) }

      it 'returns nil' do
        expect(product.price).to be_nil
      end
    end
  end

  describe '#price_range' do
    context 'with multiple distinct prices' do
      let(:product) { described_class.new(JSON.parse(products_body)['products'][0]) }

      it 'returns a min–max string' do
        expect(product.price_range).to eq('749.00 - 899.00')
      end
    end

    context 'with a single price (Ipsum City Cruiser)' do
      let(:product) { described_class.new(JSON.parse(products_body)['products'][1]) }

      it 'returns the single price string' do
        expect(product.price_range).to eq('499.00')
      end
    end

    context 'with no variants' do
      let(:product) { described_class.new('variants' => []) }

      it 'returns nil' do
        expect(product.price_range).to be_nil
      end
    end
  end

  describe '#url' do
    let(:product) { described_class.new(JSON.parse(products_body)['products'][0]) }

    it 'returns the storefront URL for the product' do
      expect(product.url).to eq('https://example.myshopify.com/products/lorem-road-bike')
    end

    context 'when fetched via a specific client' do
      it 'uses the instance client base_url' do
        product.client = Showroom::Client.new(store: 'other-store.myshopify.com')
        expect(product.url).to eq('https://other-store.myshopify.com/products/lorem-road-bike')
      end
    end
  end

  describe '#prices' do
    context 'with multiple distinct variant prices (Lorem Road Bike)' do
      let(:product) { described_class.new(JSON.parse(products_body)['products'][0]) }

      it 'returns a unique array of prices' do
        expect(product.prices).to contain_exactly('899.00', '749.00')
      end
    end

    context 'with a single price (Ipsum City Cruiser)' do
      let(:product) { described_class.new(JSON.parse(products_body)['products'][1]) }

      it 'returns a single-element array' do
        expect(product.prices).to eq(['499.00'])
      end
    end

    context 'with no variants' do
      let(:product) { described_class.new('variants' => []) }

      it 'returns an empty array' do
        expect(product.prices).to eq([])
      end
    end
  end

  describe '#main_image' do
    context 'when images include one with position 1' do
      let(:product) { described_class.new(JSON.parse(products_body)['products'][0]) }

      it 'returns a ProductImage instance' do
        expect(product.main_image).to be_a(Showroom::ProductImage)
      end

      it 'returns the image with position 1' do
        expect(product.main_image.position).to eq(1)
      end
    end

    context 'when there are no images' do
      let(:product) { described_class.new('images' => []) }

      it 'returns nil' do
        expect(product.main_image).to be_nil
      end
    end
  end

  describe '#featured_image' do
    context 'when images are present' do
      let(:product) { described_class.new(JSON.parse(products_body)['products'][0]) }

      it 'returns a ProductImage instance' do
        expect(product.featured_image).to be_a(Showroom::ProductImage)
      end

      it 'returns the first image regardless of position' do
        expect(product.featured_image).to eq(product.images.first)
      end
    end

    context 'when there are no images' do
      let(:product) { described_class.new('images' => []) }

      it 'returns nil' do
        expect(product.featured_image).to be_nil
      end
    end
  end

  # -----------------------------------------------------------------------
  # #similar
  # -----------------------------------------------------------------------
  describe '#similar' do
    let(:suggest_url)  { "#{base_url}/search/suggest.json" }
    let(:suggest_body) { fixture('search_suggest.json') }

    context 'when the handle ends with a SKU fragment' do
      let(:product) do
        described_class.new(
          'handle' => 'o2feel-equo-42-rr2px5',
          'variants' => [{ 'sku' => 'RR2PX5' }]
        )
      end

      before do
        stub_request(:get, suggest_url)
          .with(query: hash_including('q' => 'o2feel-equo-42'))
          .to_return(status: 200, body: suggest_body, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns an array of ProductSuggestion instances' do
        expect(product.similar).to all(be_a(Showroom::Search::ProductSuggestion))
      end

      it 'searches with the handle stripped of the SKU' do
        product.similar
        expect(WebMock).to have_requested(:get, suggest_url)
          .with(query: hash_including('q' => 'o2feel-equo-42'))
      end
    end

    context 'when the handle does not contain any SKU fragment' do
      let(:product) { described_class.new(JSON.parse(products_body)['products'][0]) }

      before do
        stub_request(:get, suggest_url)
          .with(query: hash_including('q' => 'lorem-road-bike'))
          .to_return(status: 200, body: suggest_body, headers: { 'Content-Type' => 'application/json' })
      end

      it 'searches with the original handle unchanged' do
        product.similar
        expect(WebMock).to have_requested(:get, suggest_url)
          .with(query: hash_including('q' => 'lorem-road-bike'))
      end
    end

    context 'when the product has no variants' do
      let(:product) { described_class.new('handle' => 'some-product', 'variants' => []) }

      before do
        stub_request(:get, suggest_url)
          .with(query: hash_including('q' => 'some-product'))
          .to_return(status: 200, body: suggest_body, headers: { 'Content-Type' => 'application/json' })
      end

      it 'searches with the original handle' do
        product.similar
        expect(WebMock).to have_requested(:get, suggest_url)
          .with(query: hash_including('q' => 'some-product'))
      end
    end

    context 'when handle search returns no results (falls back to title)' do
      let(:empty_suggest_body) { '{"resources":{"results":{"products":[]}}}' }
      let(:product) do
        described_class.new(
          'title' => 'O2Feel Equo',
          'handle' => 'o2feel-equo-42-rr2px5',
          'variants' => [{ 'sku' => 'RR2PX5' }]
        )
      end

      before do
        stub_request(:get, suggest_url)
          .with(query: hash_including('q' => 'o2feel-equo-42'))
          .to_return(status: 200, body: empty_suggest_body, headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, suggest_url)
          .with(query: hash_including('q' => 'O2Feel Equo'))
          .to_return(status: 200, body: suggest_body, headers: { 'Content-Type' => 'application/json' })
      end

      it 'falls back to searching by title' do
        product.similar
        expect(WebMock).to have_requested(:get, suggest_url)
          .with(query: hash_including('q' => 'O2Feel Equo'))
      end
    end

    context 'when the product has an instance client' do
      let(:other_url) { 'https://other-store.myshopify.com/search/suggest.json' }
      let(:product) do
        described_class.new(
          'handle' => 'bike-abc123',
          'variants' => [{ 'sku' => 'ABC123' }]
        ).tap { |p| p.client = Showroom::Client.new(store: 'other-store.myshopify.com') }
      end

      before do
        stub_request(:get, other_url)
          .with(query: hash_including('q' => 'bike'))
          .to_return(status: 200, body: suggest_body, headers: { 'Content-Type' => 'application/json' })
      end

      it 'uses the instance client' do
        product.similar
        expect(WebMock).to have_requested(:get, other_url)
          .with(query: hash_including('q' => 'bike'))
      end
    end
  end

  # -----------------------------------------------------------------------
  # Class methods
  # -----------------------------------------------------------------------
  describe '.where' do
    before do
      stub_request(:get, "#{base_url}/products.json")
        .with(query: hash_including({}))
        .to_return(status: 200, body: products_body, headers: { 'Content-Type' => 'application/json' })
    end

    it 'returns an array of Product instances' do
      result = described_class.where
      expect(result).to all(be_a(described_class))
    end

    it 'returns 2 products from the fixture' do
      expect(described_class.where.length).to eq(2)
    end

    it 'passes params as query parameters' do
      stub_request(:get, "#{base_url}/products.json")
        .with(query: hash_including('product_type' => 'Road Bike'))
        .to_return(status: 200, body: products_body, headers: { 'Content-Type' => 'application/json' })

      result = described_class.where(product_type: 'Road Bike')
      expect(result).not_to be_empty
    end

    context 'when the response has no products' do
      before do
        stub_request(:get, "#{base_url}/products.json")
          .with(query: hash_including({}))
          .to_return(status: 200, body: products_empty_body, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns an empty array' do
        expect(described_class.where).to eq([])
      end
    end
  end

  describe '.find' do
    context 'when the product exists' do
      before do
        stub_request(:get, "#{base_url}/products/lorem-road-bike.json")
          .with(query: hash_including({}))
          .to_return(status: 200, body: product_body, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns a Product instance' do
        result = described_class.find('lorem-road-bike')
        expect(result).to be_a(described_class)
      end

      it 'returns the product with the correct handle' do
        expect(described_class.find('lorem-road-bike').handle).to eq('lorem-road-bike')
      end

      it 'returns the product with the correct title' do
        expect(described_class.find('lorem-road-bike').title).to eq('Lorem Road Bike')
      end
    end

    context 'when the product is not found (404)' do
      before do
        stub_request(:get, "#{base_url}/products/nonexistent.json")
          .with(query: hash_including({}))
          .to_return(status: 404, body: '{"errors":"Not Found"}', headers: { 'Content-Type' => 'application/json' })
      end

      it 'raises Showroom::NotFound' do
        expect { described_class.find('nonexistent') }.to raise_error(Showroom::NotFound)
      end
    end
  end

  describe '.all' do
    before do
      stub_request(:get, "#{base_url}/products.json")
        .with(query: hash_including('page' => '1'))
        .to_return(status: 200, body: products_body, headers: { 'Content-Type' => 'application/json' })

      stub_request(:get, "#{base_url}/products.json")
        .with(query: hash_including('page' => '2'))
        .to_return(status: 200, body: products_empty_body, headers: { 'Content-Type' => 'application/json' })
    end

    it 'returns an Enumerator' do
      expect(described_class.all(max_pages: 2)).to be_a(Enumerator)
    end

    it 'yields the correct number of products across pages' do
      expect(described_class.all(max_pages: 2).to_a.length).to eq(2)
    end

    it 'yields Product instances' do
      expect(described_class.all(max_pages: 2).to_a).to all(be_a(described_class))
    end

    it 'raises ArgumentError without max_pages: or force_all_without_limit:' do
      expect { described_class.all.to_a }.to raise_error(ArgumentError, /max_pages/)
    end
  end

  describe '.each_page' do
    before do
      stub_request(:get, "#{base_url}/products.json")
        .with(query: hash_including('page' => '1'))
        .to_return(status: 200, body: products_body, headers: { 'Content-Type' => 'application/json' })

      stub_request(:get, "#{base_url}/products.json")
        .with(query: hash_including('page' => '2'))
        .to_return(status: 200, body: products_empty_body, headers: { 'Content-Type' => 'application/json' })
    end

    it 'raises ArgumentError without max_pages: or force_all_without_limit:' do
      expect { described_class.each_page { |_p, _n| nil } }.to raise_error(ArgumentError, /max_pages/)
    end

    it 'yields one page of results' do
      pages = []
      described_class.each_page(max_pages: 2) { |products, page| pages << [products, page] }
      expect(pages.length).to eq(1)
    end

    it 'yields the correct page number' do
      pages = []
      described_class.each_page(max_pages: 2) { |products, page| pages << [products, page] }
      expect(pages[0][1]).to eq(1)
    end

    it 'yields Product instances' do
      pages = []
      described_class.each_page(max_pages: 2) { |products, page| pages << [products, page] }
      expect(pages[0][0]).to all(be_a(described_class))
    end

    it 'emits a warning with force_all_without_limit: true' do
      expect do
        described_class.each_page(force_all_without_limit: true) { |_p, _n| nil }
      end.to output(/unbounded/).to_stderr
    end
  end

  # -----------------------------------------------------------------------
  # Module-level delegators
  # -----------------------------------------------------------------------
  describe 'Showroom.products' do
    before do
      stub_request(:get, "#{base_url}/products.json")
        .with(query: hash_including({}))
        .to_return(status: 200, body: products_body, headers: { 'Content-Type' => 'application/json' })
    end

    it 'returns an array of Product instances' do
      expect(Showroom.products).to all(be_a(described_class))
    end
  end

  describe 'Showroom.product' do
    before do
      stub_request(:get, "#{base_url}/products/lorem-road-bike.json")
        .with(query: hash_including({}))
        .to_return(status: 200, body: product_body, headers: { 'Content-Type' => 'application/json' })
    end

    it 'returns a Product instance' do
      expect(Showroom.product('lorem-road-bike')).to be_a(described_class)
    end
  end

  # -----------------------------------------------------------------------
  # Client instance methods
  # -----------------------------------------------------------------------
  describe 'client#products' do
    before do
      stub_request(:get, "#{base_url}/products.json")
        .with(query: hash_including({}))
        .to_return(status: 200, body: products_body, headers: { 'Content-Type' => 'application/json' })
    end

    it 'returns an array of Product instances' do
      expect(Showroom.client.products).to all(be_a(described_class))
    end
  end

  describe 'client#product' do
    before do
      stub_request(:get, "#{base_url}/products/lorem-road-bike.json")
        .with(query: hash_including({}))
        .to_return(status: 200, body: product_body, headers: { 'Content-Type' => 'application/json' })
    end

    it 'returns a Product instance' do
      expect(Showroom.client.product('lorem-road-bike')).to be_a(described_class)
    end
  end
end
