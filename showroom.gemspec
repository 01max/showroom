# frozen_string_literal: true

require_relative 'lib/showroom/core/version'

Gem::Specification.new do |spec|
  spec.name    = 'showroom'
  spec.version = Showroom::Core::VERSION
  spec.authors = ['01max']
  spec.email   = []

  spec.summary     = "An unauthenticated Ruby client for Shopify's public API."
  spec.description = 'A standalone Ruby gem providing a Faraday-based client
    to interact with the Shopify public API.'
  spec.license     = 'GPL-3.0-or-later'

  spec.homepage              = 'https://github.com/01max/showroom'
  spec.required_ruby_version = '>= 3.2'

  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = spec.homepage
  spec.metadata['changelog_uri']         = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir[
    'lib/**/*.rb',
    'LICENSE',
    'README.md',
    'CHANGELOG.md'
  ]
  spec.require_paths = ['lib']

  spec.add_dependency 'faraday', '>= 1', '< 3'
end
