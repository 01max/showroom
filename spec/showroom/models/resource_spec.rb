# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Showroom::Resource do
  subject(:resource) { described_class.new(attrs) }

  let(:attrs) { { 'id' => 1, 'title' => 'Test', 'nested' => { 'key' => 'val' } } }

  describe '#initialize' do
    it 'normalizes symbol id key to string' do
      r = described_class.new(id: 42, title: 'Sym')
      expect(r['id']).to eq(42)
    end

    it 'normalizes symbol title key to string' do
      r = described_class.new(id: 42, title: 'Sym')
      expect(r['title']).to eq('Sym')
    end

    it 'stores string keys as-is' do
      expect(resource['id']).to eq(1)
    end
  end

  describe 'dot-notation attribute access via method_missing' do
    it 'delegates id to attrs' do
      expect(resource.id).to eq(1)
    end

    it 'delegates title to attrs' do
      expect(resource.title).to eq('Test')
    end

    it 'raises NoMethodError for unknown keys' do
      expect { resource.nonexistent }.to raise_error(NoMethodError)
    end

    it 'caches the method after first call' do
      resource.id # prime cache
      expect(resource.class.method_defined?(:id)).to be(true)
    end
  end

  describe '#respond_to_missing?' do
    it 'returns true for known attribute keys' do
      expect(resource.respond_to?(:title)).to be(true)
    end

    it 'returns false for unknown keys' do
      expect(resource.respond_to?(:nonexistent)).to be(false)
    end
  end

  describe '#[]' do
    it 'allows raw access by string key' do
      expect(resource['title']).to eq('Test')
    end

    it 'allows raw access by symbol key' do
      expect(resource[:title]).to eq('Test')
    end
  end

  describe '.main_attrs' do
    let(:klass) do
      Class.new(described_class) do
        main_attrs :id, :title
      end
    end

    it 'stores the specified keys' do
      expect(klass.main_attr_keys).to eq(%w[id title])
    end
  end

  describe '#inspect' do
    let(:klass) do
      Class.new(described_class) do
        main_attrs :id, :title

        def self.name
          'TestResource'
        end
      end
    end

    it 'includes class name in inspect output' do
      r = klass.new('id' => 7, 'title' => 'Hello')
      expect(r.inspect).to include('TestResource')
    end

    it 'includes id value in inspect output' do
      r = klass.new('id' => 7, 'title' => 'Hello')
      expect(r.inspect).to include('id: 7')
    end

    it 'includes title value in inspect output' do
      r = klass.new('id' => 7, 'title' => 'Hello')
      expect(r.inspect).to include('title: "Hello"')
    end

    it 'omits keys not present in attrs' do
      r = klass.new('id' => 7)
      expect(r.inspect).not_to include('title')
    end
  end

  describe '.has_many' do
    let(:child_class) do
      Class.new(described_class)
    end

    let(:parent_class) do
      cc = child_class
      Class.new(described_class) do
        has_many :children, cc
      end
    end

    it 'wraps array elements as instances of the given class' do
      parent = parent_class.new('children' => [{ 'id' => 1 }, { 'id' => 2 }])
      expect(parent.children).to all(be_a(child_class))
    end

    it 'returns an empty array when the key is absent' do
      parent = parent_class.new({})
      expect(parent.children).to eq([])
    end

    it 'does not double-wrap already-wrapped instances' do
      child  = child_class.new('id' => 1)
      parent = parent_class.new('children' => [child])
      expect(parent.children.first).to be(child)
    end
  end

  describe '.has_one' do
    let(:child_class) do
      Class.new(described_class)
    end

    let(:parent_class) do
      cc = child_class
      Class.new(described_class) do
        has_one :child, cc
      end
    end

    it 'wraps the value as an instance of the given class' do
      parent = parent_class.new('child' => { 'id' => 5 })
      expect(parent.child).to be_a(child_class)
    end

    it 'provides access to wrapped attributes' do
      parent = parent_class.new('child' => { 'id' => 5 })
      expect(parent.child['id']).to eq(5)
    end

    it 'returns nil when the key is absent' do
      parent = parent_class.new({})
      expect(parent.child).to be_nil
    end

    it 'does not double-wrap already-wrapped instances' do
      child  = child_class.new('id' => 5)
      parent = parent_class.new('child' => child)
      expect(parent.child).to be(child)
    end
  end

  describe '#to_h' do
    it 'returns a plain Hash' do
      expect(resource.to_h).to be_a(Hash)
    end

    it 'deep-unwraps nested Resources' do
      child_class = Class.new(described_class)
      parent_class = Class.new(described_class) { has_many :items, child_class }
      parent = parent_class.new('items' => [{ 'id' => 1 }])
      parent.items # trigger wrapping
      expect(parent.to_h['items']).to eq([{ 'id' => 1 }])
    end
  end

  describe '#==' do
    it 'returns true for resources with identical attrs' do
      other = described_class.new(attrs)
      expect(resource).to eq(other)
    end

    it 'returns false for resources with different attrs' do
      other = described_class.new('id' => 99)
      expect(resource).not_to eq(other)
    end

    it 'returns false when compared to a non-Resource' do
      expect(resource).not_to eq(attrs)
    end
  end
end
