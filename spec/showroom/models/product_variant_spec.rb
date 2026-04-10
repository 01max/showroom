# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Showroom::ProductVariant do
  describe '#available?' do
    it 'returns true when available is true' do
      v = described_class.new('available' => true)
      expect(v.available?).to be(true)
    end

    it 'returns false when available is false' do
      v = described_class.new('available' => false)
      expect(v.available?).to be(false)
    end

    it 'returns false when available is absent' do
      v = described_class.new({})
      expect(v.available?).to be(false)
    end

    context 'with fixture data (S/Red variant — available)' do
      subject(:variant) do
        described_class.new(
          'id' => 2_000_000_000_001, 'title' => 'S / Red',
          'price' => '899.00', 'compare_at_price' => nil, 'available' => true
        )
      end

      it { is_expected.to be_available }
    end

    context 'with fixture data (City Cruiser variant — unavailable)' do
      subject(:variant) do
        described_class.new(
          'id' => 2_000_000_000_003, 'title' => 'Default Title',
          'price' => '499.00', 'compare_at_price' => '649.00', 'available' => false
        )
      end

      it { is_expected.not_to be_available }
    end
  end

  describe '#on_sale?' do
    it 'returns false when compare_at_price is nil' do
      v = described_class.new('price' => '899.00', 'compare_at_price' => nil)
      expect(v.on_sale?).to be(false)
    end

    it 'returns false when compare_at_price is an empty string' do
      v = described_class.new('price' => '899.00', 'compare_at_price' => '')
      expect(v.on_sale?).to be(false)
    end

    it 'returns true when compare_at_price > price' do
      v = described_class.new('price' => '749.00', 'compare_at_price' => '899.00')
      expect(v.on_sale?).to be(true)
    end

    it 'returns false when compare_at_price <= price' do
      v = described_class.new('price' => '899.00', 'compare_at_price' => '799.00')
      expect(v.on_sale?).to be(false)
    end

    context 'with fixture data (S/Red — no compare_at_price)' do
      subject(:variant) do
        described_class.new('price' => '899.00', 'compare_at_price' => nil)
      end

      it { is_expected.not_to be_on_sale }
    end

    context 'with fixture data (M/Blue — compare_at_price 899 > price 749)' do
      subject(:variant) do
        described_class.new('price' => '749.00', 'compare_at_price' => '899.00')
      end

      it { is_expected.to be_on_sale }
    end

    context 'with fixture data (City Cruiser — compare_at_price 649 > price 499)' do
      subject(:variant) do
        described_class.new('price' => '499.00', 'compare_at_price' => '649.00')
      end

      it { is_expected.to be_on_sale }
    end
  end

  describe '#options' do
    it 'returns non-nil option values in order' do
      v = described_class.new('option1' => 'S', 'option2' => 'Red', 'option3' => nil)
      expect(v.options).to eq(%w[S Red])
    end

    it 'returns empty array when all options are nil' do
      v = described_class.new({})
      expect(v.options).to eq([])
    end
  end
end
