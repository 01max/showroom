# frozen_string_literal: true

module Showroom
  module Core
    # Mixin that adds {#calculate_count} to model classes exposing a paginated
    # index endpoint.
    #
    # Uses an exponential probe followed by binary search to locate the last
    # non-empty page, then derives the total count. Costs O(log n) HTTP
    # requests where n is the number of pages.
    #
    # The count is **approximate** — items may be added or removed between
    # requests.
    #
    # @example
    #   Product.calculate_count    # => 2847  (O(log n) requests)
    #   Collection.calculate_count # => 42
    module Countable
      MAX_PER_PAGE  = 250
      MAX_PAGE      = 100
      MAX_COUNT     = MAX_PER_PAGE * MAX_PAGE # 25_000

      # Estimates the total number of items via binary search over pages.
      #
      # Shopify's public endpoints reject page numbers above 100, so the
      # maximum reportable count is **25,000** (100 pages × 250 per page).
      # Stores with more items will return 25,000. Any +limit:+ key in
      # +params+ is ignored — the probe always uses +MAX_PER_PAGE+ (250).
      #
      # @param params [Hash] additional query parameters forwarded to the
      #   index endpoint (e.g. +product_type:+, +vendor:+). +limit:+ is ignored.
      # @return [Integer] approximate total item count, capped at 25,000
      def calculate_count(**params)
        fetch = ->(page) { page_size(page, **params.except(:limit)) }
        upper = probe_upper_bound(fetch)
        return 0 if upper == 1 && fetch.call(1).zero?

        tally(fetch, upper)
      end

      private

      def tally(fetch, upper)
        result = binary_search(fetch, upper / 2, upper)
        total  = (result[:lower] * MAX_PER_PAGE) + (result[:upper_size] || fetch.call(result[:upper]))
        if total >= MAX_COUNT
          warn "[Showroom] calculate_count hit the #{MAX_COUNT} item ceiling — the store likely has more."
        end
        total
      end

      def probe_upper_bound(fetch)
        upper = 1
        upper = [upper * 2, MAX_PAGE].min while fetch.call(upper) == MAX_PER_PAGE && upper < MAX_PAGE
        upper
      end

      def binary_search(fetch, lower, upper)
        upper_size = nil
        lower, upper, upper_size = binary_search_step(fetch, lower, upper) while lower < upper - 1
        { lower: lower, upper: upper, upper_size: upper_size }
      end

      def binary_search_step(fetch, lower, upper)
        mid  = (lower + upper) / 2
        size = fetch.call(mid)
        size == MAX_PER_PAGE ? [mid, upper, nil] : [lower, mid, size]
      end

      def page_size(page, **params)
        body  = Showroom.client.get(index_path, params.merge(limit: MAX_PER_PAGE, page: page))
        items = body.is_a?(Hash) ? body[index_key] : body
        items&.size || 0
      rescue Showroom::BadRequest
        0
      end
    end
  end
end
