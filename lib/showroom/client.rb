# frozen_string_literal: true

require_relative 'core/configurable'
require_relative 'core/connection'
require_relative 'models'

module Showroom
  # A configured HTTP client for a single Showroom store.
  #
  # Combines {Core::Configurable} (configuration DSL) with
  # {Core::Connection} (Faraday-based HTTP).
  #
  # @example Single-store usage
  #   client = Showroom::Client.new(store: 'example.myshopify.com')
  #   client.get('/products.json', limit: 10)
  #
  # @example Multi-store usage
  #   eu_client = Showroom::Client.new(store: 'eu.shop.com')
  #   us_client = Showroom::Client.new(store: 'us.shop.com')
  class Client
    include Core::Configurable
    include Core::Connection

    # Initializes a new Client with the given options.
    #
    # Resets all keys to defaults first, then applies any provided options.
    #
    # @param opts [Hash] configuration overrides (keys from {Core::Configurable::KEYS})
    # @option opts [String] :store the Shopify store domain or URL
    # @option opts [String] :user_agent custom User-Agent string
    # @option opts [Integer] :per_page results per page (clamped to MAX_PER_PAGE)
    # @option opts [Integer] :pagination_depth maximum pages to fetch
    # @option opts [Integer] :open_timeout connection timeout in seconds
    # @option opts [Integer] :timeout read timeout in seconds
    # @option opts [#call, nil] :middleware Faraday middleware proc
    # @option opts [Hash] :connection_options extra Faraday connection options
    def initialize(**opts)
      reset!
      opts.each { |key, value| send(:"#{key}=", value) }
    end

    # Fetches products from the store.
    #
    # @param params [Hash] Shopify query parameters
    # @return [Array<Product>]
    def products(**params)
      get('/products.json', params).fetch('products', []).map { |h| Product.new(h) }
    end

    # Fetches a single product by handle.
    #
    # @param handle [String] the product handle
    # @return [Product]
    # @raise [Showroom::NotFound] when the product is not found
    def product(handle)
      get("/products/#{handle}.json")
        .fetch('product') { raise Showroom::NotFound, handle }
        .then { |h| Product.new(h) }
    end

    # Fetches collections from the store.
    #
    # @param params [Hash] Shopify query parameters
    # @return [Array<Collection>]
    def collections(**params)
      get('/collections.json', params).fetch('collections', []).map { |h| Collection.new(h) }
    end

    # Fetches a single collection by handle.
    #
    # @param handle [String] the collection handle
    # @return [Collection]
    # @raise [Showroom::NotFound] when the collection is not found
    def collection(handle)
      get("/collections/#{handle}.json")
        .fetch('collection') { raise Showroom::NotFound, handle }
        .then { |h| Collection.new(h) }
    end

    # Calls the Shopify search suggest endpoint and returns a {Search::Result}.
    #
    # @param query_str [String] the search query
    # @param types [Array<Symbol>] resource types to search (e.g. +:product+, +:collection+)
    # @param limit [Integer] maximum results per type (defaults to {#per_page})
    # @param params [Hash] additional query parameters forwarded to the API
    # @return [Search::Result]
    def search(query_str, types: %i[product collection], limit: per_page, **params)
      query = { q: query_str, 'resources[limit]' => limit }
      query['resources[type]'] = types.join(',') unless types.empty?
      query.merge!(params)
      raw = get('/search/suggest.json', query)
      Search::Result.new(raw.dig('resources', 'results') || {})
    end
  end
end
