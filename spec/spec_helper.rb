# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

require 'webmock/rspec'
require 'showroom'

WebMock.disable_net_connect!

# Helper to load a fixture file from spec/fixtures/.
#
# @param path [String] relative path under spec/fixtures/
# @return [String] the fixture file contents
def fixture(path)
  File.read(File.join(__dir__, 'fixtures', path))
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.disable_monkey_patching!
  config.warnings = true
  config.order = :random
  Kernel.srand config.seed
end
