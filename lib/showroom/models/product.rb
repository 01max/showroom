# frozen_string_literal: true

module Showroom
  # Represents a Shopify product with associations, convenience methods,
  # and class-level query methods that delegate to {Showroom.client}.
  #
  # @example Fetching products
  #   products = Showroom::Product.where(product_type: 'Road Bike')
  #   product  = Showroom::Product.find('lorem-road-bike')
  class Product < Resource
    main_attrs :id, :title, :handle, :vendor, :product_type, :price, :price_range

    has_many :variants, ProductVariant
    has_many :images,   ProductImage
    has_many :options,  ProductOption

    class << self
      include Core::Countable

      def index_path = '/products.json'
      def index_key  = 'products'
      private :index_path, :index_key

      # Fetches products matching the given query parameters.
      #
      # @param params [Hash] Shopify query parameters (e.g. product_type:, vendor:)
      # @return [Array<Product>]
      def where(limit: Showroom.per_page, **params)
        Showroom.client.get('/products.json', params.merge(limit: limit))
                .fetch('products', [])
                .map { |h| new(h) }
      end

      # Fetches a single product by handle.
      #
      # @param handle [String] the product handle
      # @return [Product]
      # @raise [Showroom::NotFound] when the product is not found
      def find(handle)
        Showroom.client.get("/products/#{handle}.json")
                .fetch('product') { raise Showroom::NotFound, handle }
                .then { |h| new(h) }
      end

      # Returns an Enumerator that iterates over products across multiple pages.
      #
      # You must pass either +max_pages:+ (an explicit ceiling) or set
      # +force_all_without_limit: true+ to acknowledge that the number of
      # requests is unbounded. The latter emits a warning.
      #
      # @param max_pages [Integer, nil] maximum number of pages to fetch
      # @param force_all_without_limit [Boolean] when true, fetch all pages
      #   up to +pagination_depth+ without a hard cap (emits a warning)
      # @param params [Hash] additional query parameters
      # @return [Enumerator<Product>]
      # @raise [ArgumentError] when neither +max_pages:+ nor
      #   +force_all_without_limit: true+ is given
      def all(max_pages: nil, force_all_without_limit: false, **params)
        Enumerator.new do |yielder|
          each_page(max_pages: max_pages, force_all_without_limit: force_all_without_limit,
                    **params) do |page_products, _page|
            page_products.each { |p| yielder << p }
          end
        end
      end

      # Iterates through pages of products, yielding each page.
      #
      # You must pass either +max_pages:+ or +force_all_without_limit: true+.
      # Without an explicit ceiling, unbounded pagination can issue dozens of
      # HTTP requests silently. When +force_all_without_limit: true+ is given,
      # a warning is emitted and iteration proceeds up to +pagination_depth+.
      #
      # @param max_pages [Integer, nil] maximum number of pages to fetch
      # @param force_all_without_limit [Boolean] bypass the requirement at your
      #   own risk; emits a +Kernel.warn+ and uses +pagination_depth+ as the cap
      # @param limit [Integer] results per page (defaults to +Showroom.per_page+)
      # @param params [Hash] additional query parameters
      # @yield [products, page] the products for this page and the 1-based page number
      # @yieldparam products [Array<Product>]
      # @yieldparam page [Integer]
      # @return [void]
      # @raise [ArgumentError] when neither +max_pages:+ nor
      #   +force_all_without_limit: true+ is given
      def each_page(max_pages: nil, force_all_without_limit: false, limit: Showroom.per_page, **params, &blk)
        validate_pagination_args!(max_pages, force_all_without_limit)
        effective_depth = max_pages || Showroom.client.pagination_depth
        Showroom.client.paginate('/products.json', 'products', params.merge(limit: limit),
                                 max_pages: effective_depth) do |items, page|
          blk.call(items.map { |h| new(h) }, page)
        end
      end

      private

      def validate_pagination_args!(max_pages, force_all_without_limit)
        if max_pages.nil? && !force_all_without_limit
          raise ArgumentError,
                'Product.each_page requires max_pages: N or force_all_without_limit: true. ' \
                'Unbounded pagination can issue many HTTP requests. ' \
                'Pass max_pages: to set an explicit ceiling.'
        end
        return unless force_all_without_limit && max_pages.nil?

        warn '[Showroom] force_all_without_limit: true — pagination is unbounded and may issue ' \
             "up to #{Showroom.client.pagination_depth} HTTP requests."
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

      prices.length == 1 ? prices.first : "#{prices.min} - #{prices.max}"
    end

    # Returns true when the product is available for purchase, false when it
    # is not, or nil when availability cannot be determined from the payload.
    #
    # If the response carries a top-level +available+ key, that value wins.
    # Otherwise the result is aggregated from variants:
    # any variant +true+ → +true+; all variants +false+ → +false+;
    # otherwise (mix of +false+ and unknowns, or all unknown) → +nil+.
    #
    # @return [Boolean, nil]
    def available?
      return @attrs['available'] == true if @attrs.key?('available')

      states = variants.map(&:available?)
      return true  if states.include?(true)
      return false if states.all? { |s| s == false }

      nil # rubocop:disable Style/ReturnNilInPredicateMethodDefinition
    end

    # Returns true when product-level availability can be determined,
    # either from a top-level +available+ key or from at least one variant
    # whose own availability is known.
    #
    # @return [Boolean]
    def availability_known?
      @attrs.key?('available') || variants.any?(&:availability_known?)
    end

    # Returns the first image, or nil if there are no images.
    #
    # @return [ProductImage, nil]
    def featured_image
      images.first
    end

    # Returns the canonical storefront URL for this product.
    #
    # @return [String]
    def url
      conn = client || Showroom.client
      "#{conn.base_url}/products/#{handle}"
    end

    # Returns unique prices across all variants as an Array of Strings.
    #
    # Unlike {#price} (lowest single price) or {#price_range} (formatted string),
    # this returns the raw deduplicated list useful for custom rendering.
    #
    # @return [Array<String>]
    def prices
      variants.map do |variant|
        variant['price']
      end.uniq
    end

    # Returns the image whose +position+ field equals 1, or nil if none match.
    #
    # Unlike {#featured_image} (which returns +images.first+ regardless of
    # position), this explicitly matches on the +position+ attribute.
    #
    # @return [ProductImage, nil]
    def main_image
      images.find do |img|
        img['position'] == 1
      end
    end

    # Searches for products similar to this one using the product handle as
    # the query, with any variant SKU fragments stripped out first.
    #
    # SKU fragments are matched case-insensitively as hyphen-delimited segments
    # within the handle. For example, a handle of +"o2feel-equo-42-rr2px5"+ on
    # a product whose variant carries SKU +"RR2PX5"+ yields the query
    # +"o2feel-equo-42"+.
    #
    # @param kwargs [Hash] additional options forwarded to +Client#search+
    # @return [Array<Search::ProductSuggestion>]
    def similar(**kwargs)
      search_args = kwargs.merge(types: %i[product])

      handle_similars = similar_by_stripped_handle(**search_args)
      return handle_similars unless handle_similars.empty?

      similar_by_title(**search_args)
    end

    private

    # @api private
    def similar_by_stripped_handle(**)
      (client || Showroom.client).search(stripped_handle_search_query, **).products(order: 'price')
    end

    # @api private
    def similar_by_title(**)
      (client || Showroom.client).search(title, **).products(order: 'price')
    end

    # Strips variant SKU fragments from the handle to build the search query.
    #
    # @return [String]
    def stripped_handle_search_query
      skus = variants.filter_map { |v| v.sku.to_s.strip.downcase }.reject(&:empty?).uniq
      skus.inject(handle.to_s) do |h, sku|
        h.sub(/(^|-)#{Regexp.escape(sku)}((?=-)|$)/i, '')
         .gsub(/^-|-$/, '')
      end
    end
  end
end
