# frozen_string_literal: true

RSpec.describe Showroom::Core::Configurable do
  # Use a dedicated test class to isolate configurable behaviour from the
  # module-level Showroom singleton.
  subject(:obj) { klass.new }

  let(:klass) do
    Class.new do
      include Showroom::Core::Configurable
    end
  end

  before { obj.reset! }

  describe '#reset!' do
    it 'sets per_page to the default' do
      obj.per_page = 10
      obj.reset!
      expect(obj.per_page).to eq(Showroom::Core::Default.per_page)
    end

    it 'sets timeout to the default' do
      obj.timeout = 999
      obj.reset!
      expect(obj.timeout).to eq(Showroom::Core::Default.timeout)
    end

    it 'sets store to nil by default' do
      obj.store = 'something.fr'
      obj.reset!
      expect(obj.store).to be_nil
    end
  end

  describe '#configure' do
    it 'yields self' do
      yielded = nil
      obj.configure { |c| yielded = c }
      expect(yielded).to be(obj)
    end

    it 'returns self' do
      result = obj.configure { |c| c.timeout = 99 }
      expect(result).to be(obj)
    end

    it 'applies changes made inside the block' do
      obj.configure { |c| c.store = 'example.myshopify.com' }
      expect(obj.store).to eq('example.myshopify.com')
    end
  end

  describe '#options' do
    it 'returns a hash with all KEYS' do
      expect(obj.options.keys).to match_array(Showroom::Core::Configurable::KEYS)
    end

    it 'returns a frozen hash' do
      expect(obj.options).to be_frozen
    end

    it 'reflects current values' do
      obj.store = 'test.myshopify.com'
      expect(obj.options[:store]).to eq('test.myshopify.com')
    end
  end

  describe '#same_options?' do
    it 'returns true when options match' do
      expect(obj.same_options?(obj.options)).to be(true)
    end

    it 'returns false when options differ' do
      other = obj.options.merge(store: 'different.fr')
      expect(obj.same_options?(other)).to be(false)
    end
  end

  describe '#per_page=' do
    it 'clamps values above MAX_PER_PAGE' do
      obj.per_page = 9999
      expect(obj.per_page).to eq(Showroom::Core::Default::MAX_PER_PAGE)
    end

    it 'accepts values at or below MAX_PER_PAGE' do
      obj.per_page = 100
      expect(obj.per_page).to eq(100)
    end

    it 'accepts the maximum value exactly' do
      obj.per_page = Showroom::Core::Default::MAX_PER_PAGE
      expect(obj.per_page).to eq(Showroom::Core::Default::MAX_PER_PAGE)
    end
  end
end
