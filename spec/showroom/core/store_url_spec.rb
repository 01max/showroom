# frozen_string_literal: true

RSpec.describe Showroom::Core::StoreUrl do
  describe '.resolve' do
    # Table of valid input → expected output pairs.
    valid_cases = {
      'example.com' => 'https://example.com',
      'https://example.com/' => 'https://example.com',
      'http://example.com' => 'https://example.com',
      'example.myshopify.com' => 'https://example.myshopify.com',
      'https://example.myshopify.com' => 'https://example.myshopify.com',
      '  example.com  ' => 'https://example.com'
    }

    valid_cases.each do |input, expected|
      it "resolves #{input.inspect} to #{expected.inspect}" do
        expect(described_class.resolve(input)).to eq(expected)
      end
    end

    context 'with blank or nil store' do
      it 'raises ConfigurationError for nil' do
        expect { described_class.resolve(nil) }
          .to raise_error(Showroom::ConfigurationError, /blank/)
      end

      it 'raises ConfigurationError for empty string' do
        expect { described_class.resolve('') }
          .to raise_error(Showroom::ConfigurationError, /blank/)
      end

      it 'raises ConfigurationError for whitespace-only string' do
        expect { described_class.resolve('   ') }
          .to raise_error(Showroom::ConfigurationError, /blank/)
      end
    end

    context 'with a non-root path' do
      it 'raises ConfigurationError for example.myshopify.com/shop' do
        expect { described_class.resolve('example.myshopify.com/shop') }
          .to raise_error(Showroom::ConfigurationError, /path/)
      end

      it 'raises ConfigurationError for https://example.myshopify.com/collections' do
        expect { described_class.resolve('https://example.myshopify.com/collections') }
          .to raise_error(Showroom::ConfigurationError, /path/)
      end
    end
  end
end
