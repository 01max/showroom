# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Showroom::ProductImage do
  subject(:image) { described_class.new(attrs) }

  let(:attrs) do
    {
      'id' => 3_000_000_000_001,
      'src' => 'https://cdn.shopify.com/s/files/1/img.jpg',
      'width' => 2048,
      'height' => 1365,
      'position' => 1,
      'variant_ids' => [],
      'created_at' => '2024-03-01T10:00:00+01:00',
      'updated_at' => '2024-03-01T10:00:00+01:00'
    }
  end

  it 'exposes id' do
    expect(image.id).to eq(3_000_000_000_001)
  end

  it 'exposes src' do
    expect(image.src).to eq('https://cdn.shopify.com/s/files/1/img.jpg')
  end

  it 'exposes width' do
    expect(image.width).to eq(2048)
  end

  it 'exposes height' do
    expect(image.height).to eq(1365)
  end

  it 'exposes position' do
    expect(image.position).to eq(1)
  end

  it 'exposes variant_ids as an array' do
    expect(image.variant_ids).to eq([])
  end

  it 'exposes created_at' do
    expect(image.created_at).to eq('2024-03-01T10:00:00+01:00')
  end

  it 'exposes updated_at' do
    expect(image.updated_at).to eq('2024-03-01T10:00:00+01:00')
  end

  it 'is a Resource' do
    expect(image).to be_a(Showroom::Resource)
  end
end
