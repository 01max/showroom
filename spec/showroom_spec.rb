# frozen_string_literal: true

RSpec.describe Showroom do
  describe 'VERSION' do
    it 'is a string' do
      expect(Showroom::Core::VERSION).to be_a(String)
    end

    it 'matches semver format' do
      expect(Showroom::Core::VERSION).to match(/\A\d+\.\d+\.\d+(-[a-zA-Z0-9.]+)?\z/)
    end
  end
end
