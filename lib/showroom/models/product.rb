# frozen_string_literal: true

module Showroom
  # Represents a Shopify product with associations, convenience methods,
  # and class-level query methods that delegate to {Showroom.client}.
  #
  # @example Fetching products
  #   products = Showroom::Product.where(product_type: 'Road Bike')
  #   product  = Showroom::Product.find('lorem-road-bike')
  class Product < Resource
    main_attrs :id, :title, :handle, :vendor, :product_type

    has_many :variants, ProductVariant
    has_many :images,   ProductImage
    has_many :options,  ProductOption

    # Fetches products matching the given query parameters.
    #
    # @param params [Hash] Shopify query parameters (e.g. product_type:, vendor:)
    # @return [Array<Product>]
    def self.where(**params)
      Showroom.client.get('/products.json', params)
              .fetch('products', [])
              .map { |h| new(h) }
    end

    # Fetches a single product by handle.
    #
    # @param handle [String] the product handle
    # @return [Product]
    # @raise [Showroom::NotFound] when the product is not found
    def self.find(handle)
      Showroom.client.get("/products/#{handle}.json")
              .fetch('product') { raise Showroom::NotFound, handle }
              .then { |h| new(h) }
    end

    # Returns an Enumerator that lazily iterates over all products across pages.
    #
    # @param params [Hash] additional query parameters
    # @return [Enumerator<Product>]
    def self.all(**params)
      Enumerator.new do |yielder|
        each_page(**params) do |page_products, _page|
          page_products.each { |p| yielder << p }
        end
      end
    end

    # Iterates through pages of products, yielding each page.
    #
    # @param limit [Integer] results per page (defaults to {Showroom.per_page})
    # @param params [Hash] additional query parameters
    # @yield [products, page] the array of products for the page and the 1-based page number
    # @yieldparam products [Array<Product>]
    # @yieldparam page [Integer]
    # @return [void]
    def self.each_page(limit: Showroom.per_page, **params, &blk)
      Showroom.client.paginate('/products.json', 'products', params.merge(limit: limit)) do |items, page|
        blk.call(items.map { |h| new(h) }, page)
      end
    end

    # Returns the lowest variant price as a String.
    #
    # @return [String, nil]
    def price
      variants.min_by { |v| v['price'].to_f }&.then { |v| v['price'] }
    end

    # Returns a price range string ("min–max") or just the price if all variants
    # share the same price.
    #
    # @return [String, nil]
    def price_range
      prices = variants.map { |v| v['price'] }.uniq
      return nil if prices.empty?

      prices.length == 1 ? prices.first : "#{prices.min}–#{prices.max}"
    end

    # Returns true when at least one variant is available for purchase.
    #
    # @return [Boolean]
    def available?
      variants.any?(&:available?)
    end

    # Returns the first image, or nil if there are no images.
    #
    # @return [ProductImage, nil]
    def featured_image
      images.first
    end
  end
end
