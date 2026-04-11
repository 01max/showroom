# frozen_string_literal: true

module Showroom
  # Represents a Shopify collection with class-level query methods
  # that delegate to {Showroom.client} and an instance-level products fetcher.
  #
  # @example Fetching collections
  #   collections = Showroom::Collection.where
  #   collection  = Showroom::Collection.find('lorem-helmets')
  #
  # @example Fetching products in a collection
  #   collection.products(limit: 10)
  class Collection < Resource
    main_attrs :id, :title, :handle

    class << self
      # Fetches collections matching the given query parameters.
      #
      # @param params [Hash] Shopify query parameters
      # @return [Array<Collection>]
      def where(**params)
        Showroom.client.get('/collections.json', params)
                .fetch('collections', [])
                .map { |h| new(h) }
      end

      # Fetches a single collection by handle.
      #
      # @param handle [String] the collection handle
      # @return [Collection]
      # @raise [Showroom::NotFound] when the collection is not found
      def find(handle)
        Showroom.client.get("/collections/#{handle}.json")
                .fetch('collection') { raise Showroom::NotFound, handle }
                .then { |h| new(h) }
      end
    end

    # Fetches a single page of products belonging to this collection.
    #
    # Returns at most one page of results. Use +limit: 250+ to maximise the
    # number of products returned in a single request. For collections with
    # more products than the page size, pass +page:+ explicitly to retrieve
    # subsequent pages.
    #
    # @param params [Hash] Shopify query parameters (e.g. +limit:+, +page:+)
    # @return [Array<Product>]
    def products(**params)
      Showroom.client.get("/collections/#{handle}/products.json", params)
              .fetch('products', [])
              .map { |h| Product.new(h) }
    end
  end
end
