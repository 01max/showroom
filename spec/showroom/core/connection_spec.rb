# frozen_string_literal: true

RSpec.describe Showroom::Core::Connection do
  subject(:client) { Showroom::Client.new(store: 'example.myshopify.com') }

  let(:store_url) { 'https://example.myshopify.com' }

  before do
    stub_request(:get, /example\.myshopify\.com/)
      .to_return(status: 200, body: '{"products":[]}', headers: { 'Content-Type' => 'application/json' })
  end

  describe '#agent' do
    it 'returns a Faraday::Connection' do
      expect(client.agent).to be_a(Faraday::Connection)
    end

    it 'memoizes the connection' do
      first_agent = client.agent
      expect(client.agent).to be(first_agent)
    end

    it 'sets the User-Agent header' do
      expect(client.agent.headers['User-Agent']).to match(%r{\AShowroom/})
    end
  end

  describe '#get' do
    it 'returns the parsed body' do
      result = client.get('/products.json')
      expect(result).to eq({ 'products' => [] })
    end

    it 'stores last_response' do
      client.get('/products.json')
      expect(client.last_response).not_to be_nil
    end

    context 'when response is 404' do
      before do
        stub_request(:get, %r{example\.myshopify\.com/missing})
          .to_return(status: 404, body: '{}', headers: { 'Content-Type' => 'application/json' })
      end

      it 'raises NotFound' do
        expect { client.get('/missing') }.to raise_error(Showroom::NotFound)
      end
    end

    context 'when response is 429' do
      before do
        stub_request(:get, %r{example\.myshopify\.com/products})
          .to_return(status: 429, body: '{}', headers: { 'Content-Type' => 'application/json' })
      end

      it 'raises TooManyRequests' do
        expect { client.get('/products') }.to raise_error(Showroom::TooManyRequests)
      end
    end

    context 'when response is 500' do
      before do
        stub_request(:get, %r{example\.myshopify\.com/products})
          .to_return(status: 500, body: '{}', headers: { 'Content-Type' => 'application/json' })
      end

      it 'raises ServerError' do
        expect { client.get('/products') }.to raise_error(Showroom::ServerError)
      end
    end

    context 'when response body is HTML' do
      before do
        stub_request(:get, %r{example\.myshopify\.com/products})
          .to_return(status: 200, body: '<html></html>',
                     headers: { 'Content-Type' => 'text/html; charset=utf-8' })
      end

      it 'raises InvalidResponse' do
        expect { client.get('/products') }.to raise_error(Showroom::InvalidResponse)
      end
    end
  end

  describe '#paginate' do
    context 'when pages return items then empty' do
      before do
        stub_request(:get, %r{example\.myshopify\.com/products\.json})
          .with(query: hash_including('page' => '1'))
          .to_return(
            status: 200,
            body: '{"products":[{"id":1},{"id":2}]}',
            headers: { 'Content-Type' => 'application/json' }
          )
        stub_request(:get, %r{example\.myshopify\.com/products\.json})
          .with(query: hash_including('page' => '2'))
          .to_return(
            status: 200,
            body: '{"products":[]}',
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'yields items and page number' do
        pages = []
        client.paginate('/products.json', 'products') { |items, page| pages << [items, page] }
        expect(pages).to eq([[[{ 'id' => 1 }, { 'id' => 2 }], 1]])
      end
    end

    context 'when pagination_depth is reached' do
      before do
        stub_request(:get, %r{example\.myshopify\.com/products\.json})
          .to_return(
            status: 200,
            body: '{"products":[{"id":1}]}',
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'stops after pagination_depth pages' do
        client.pagination_depth = 2
        count = 0
        client.paginate('/products.json', 'products') { |_items, _page| count += 1 }
        expect(count).to eq(2)
      end
    end
  end
end
