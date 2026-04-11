# frozen_string_literal: true

require_relative 'showroom/core/version'
require_relative 'showroom/core/error'
require_relative 'showroom/core/default'
require_relative 'showroom/core/configurable'
require_relative 'showroom/core/store_url'
require_relative 'showroom/http/middleware/raise_error'
require_relative 'showroom/core/connection'
require_relative 'showroom/client'
require_relative 'showroom/models'

# Top-level namespace for the Showroom gem.
#
# Acts as a module-level client with {Core::Configurable} mixed in, so you can
# configure and use Showroom directly without instantiating a {Client}.
#
# @example Global configuration
#   Showroom.configure do |c|
#     c.store = 'example.myshopify.com'
#   end
#
# @example Module-level request
#   Showroom.client.get('/products.json')
module Showroom
  extend Core::Configurable

  reset!

  # Returns the memoized module-level {Client}.
  #
  # @return [Client]
  def self.client
    @client ||= Client.new(**options)
  end

  # Configures the module and resets the memoized client so the next call to
  # {.client} picks up the new settings.
  #
  # @yield [self]
  # @return [self]
  def self.configure
    super.tap { @client = nil }
  end

  # Resets all configuration to defaults and clears the memoized client.
  #
  # @return [void]
  def self.reset!
    super
    @client = nil
  end

  # Alias for {.configure} — yields self for block-style setup.
  #
  # @yield [self]
  # @return [self]
  def self.setup(&)
    configure(&)
  end

  # Fetches products from the configured store.
  #
  # @param params [Hash] Shopify query parameters
  # @return [Array<Product>]
  def self.products(**params)
    Product.where(**params)
  end

  # Fetches a single product by handle from the configured store.
  #
  # @param handle [String] the product handle
  # @return [Product]
  # @raise [Showroom::NotFound] when the product is not found
  def self.product(handle)
    Product.find(handle)
  end

  # Fetches collections from the configured store.
  #
  # @param params [Hash] Shopify query parameters
  # @return [Array<Collection>]
  def self.collections(**params)
    Collection.where(**params)
  end

  # Fetches a single collection by handle from the configured store.
  #
  # @param handle [String] the collection handle
  # @return [Collection]
  # @raise [Showroom::NotFound] when the collection is not found
  def self.collection(handle)
    Collection.find(handle)
  end

  # Calls the Shopify search suggest endpoint and returns a {Search::Result}.
  #
  # @param query_str [String] the search query
  # @param params [Hash] keyword arguments forwarded to {Search.suggest}
  # @return [Search::Result]
  def self.search(query_str, **)
    Search.suggest(query_str, **)
  end
end
