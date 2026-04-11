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
      MAX_PER_PAGE = 250

      # Estimates the total number of items via binary search over pages.
      #
      # @param params [Hash] additional query parameters forwarded to the
      #   index endpoint (e.g. +product_type:+, +vendor:+)
      # @return [Integer] approximate total item count
      def calculate_count(**params)
        fetch = ->(page) { page_size(page, **params) }
        upper = probe_upper_bound(fetch)
        return 0 if upper == 1 && fetch.call(1).zero?

        upper = binary_search(fetch, upper / 2, upper)
        last_size = upper[:upper_size] || fetch.call(upper[:upper])
        (upper[:lower] * MAX_PER_PAGE) + last_size
      end

      private

      def probe_upper_bound(fetch)
        upper = 1
        upper *= 2 while fetch.call(upper) == MAX_PER_PAGE
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
