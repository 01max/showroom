# frozen_string_literal: true

RSpec.describe Showroom::Http::Middleware::RaiseError do
  let(:store_url) { 'https://example.myshopify.com' }

  # Build a minimal Faraday connection with only our middleware under test.
  let(:conn) do
    Faraday.new(url: store_url) do |f|
      f.use described_class
      f.response :json, content_type: /\bjson\b/, parser_options: { symbolize_names: false }
      f.adapter :test, stubs
    end
  end

  let(:stubs) { Faraday::Adapter::Test::Stubs.new }

  describe 'status → error class mapping' do
    {
      400 => Showroom::BadRequest,
      404 => Showroom::NotFound,
      422 => Showroom::UnprocessableEntity,
      429 => Showroom::TooManyRequests,
      403 => Showroom::ClientError,
      410 => Showroom::ClientError,
      500 => Showroom::ServerError,
      503 => Showroom::ServerError
    }.each do |status, klass|
      it "raises #{klass} for HTTP #{status}" do
        stubs.get('/test') { [status, { 'Content-Type' => 'application/json' }, '{}'] }
        expect { conn.get('/test') }.to raise_error(klass)
      end
    end
  end

  describe 'ResponseError attributes' do
    subject(:error) do
      conn.get('/test')
    rescue Showroom::ResponseError => e
      e
    end

    before { stubs.get('/test') { [404, { 'Content-Type' => 'application/json' }, '{"error":"not found"}'] } }

    it 'exposes the status code' do
      expect(error.status).to eq(404)
    end
  end

  describe 'Faraday::ParsingError → InvalidResponse' do
    it 'raises InvalidResponse with a descriptive message' do
      # Trigger a parsing error by returning HTML with a json content-type header
      # so Faraday tries — and fails — to parse it.
      stubs.get('/test') { [200, { 'Content-Type' => 'application/json' }, '<html>oops</html>'] }
      expect { conn.get('/test') }
        .to raise_error(Showroom::InvalidResponse, /not JSON/)
    end
  end

  describe '200 with HTML content-type → InvalidResponse' do
    it 'raises InvalidResponse when response is HTML' do
      stubs.get('/test') { [200, { 'Content-Type' => 'text/html; charset=utf-8' }, '<html></html>'] }
      expect { conn.get('/test') }
        .to raise_error(Showroom::InvalidResponse, /not JSON/)
    end
  end

  describe 'successful JSON response' do
    it 'does not raise and returns body' do
      stubs.get('/test') { [200, { 'Content-Type' => 'application/json' }, '{"ok":true}'] }
      expect { conn.get('/test') }.not_to raise_error
    end
  end
end
