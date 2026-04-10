# frozen_string_literal: true

RSpec.describe Showroom::Error do
  it 'is a StandardError' do
    expect(described_class.ancestors).to include(StandardError)
  end

  describe Showroom::ConfigurationError do
    it 'inherits from Error' do
      expect(described_class.ancestors).to include(Showroom::Error)
    end
  end

  describe Showroom::ConnectionError do
    it 'inherits from Error' do
      expect(described_class.ancestors).to include(Showroom::Error)
    end
  end

  describe Showroom::InvalidResponse do
    it 'inherits from Error' do
      expect(described_class.ancestors).to include(Showroom::Error)
    end
  end

  describe Showroom::ResponseError do
    subject(:error) { described_class.new('oops', status: 404, body: 'not found', headers: { 'x-id' => '1' }) }

    it 'inherits from Error' do
      expect(described_class.ancestors).to include(Showroom::Error)
    end

    it 'exposes status' do
      expect(error.status).to eq(404)
    end

    it 'exposes body' do
      expect(error.body).to eq('not found')
    end

    it 'exposes headers' do
      expect(error.headers).to eq({ 'x-id' => '1' })
    end

    it 'uses the provided message' do
      expect(error.message).to eq('oops')
    end

    context 'when no message is provided' do
      subject(:error) { described_class.new(status: 500) }

      it 'defaults message to "HTTP <status>"' do
        expect(error.message).to eq('HTTP 500')
      end
    end

    context 'when no headers are provided' do
      subject(:error) { described_class.new(status: 503) }

      it 'defaults headers to empty hash' do
        expect(error.headers).to eq({})
      end
    end
  end

  describe Showroom::ClientError do
    it 'inherits from ResponseError' do
      expect(described_class.ancestors).to include(Showroom::ResponseError)
    end

    describe Showroom::BadRequest do
      it 'inherits from ClientError' do
        expect(described_class.ancestors).to include(Showroom::ClientError)
      end
    end

    describe Showroom::NotFound do
      it 'inherits from ClientError' do
        expect(described_class.ancestors).to include(Showroom::ClientError)
      end
    end

    describe Showroom::UnprocessableEntity do
      it 'inherits from ClientError' do
        expect(described_class.ancestors).to include(Showroom::ClientError)
      end
    end

    describe Showroom::TooManyRequests do
      it 'inherits from ClientError' do
        expect(described_class.ancestors).to include(Showroom::ClientError)
      end
    end
  end

  describe Showroom::ServerError do
    it 'inherits from ResponseError' do
      expect(described_class.ancestors).to include(Showroom::ResponseError)
    end
  end
end
