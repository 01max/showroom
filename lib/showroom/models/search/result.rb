# frozen_string_literal: true

module Showroom
  module Search
    # Wraps the +resources.results+ hash from a Shopify search suggest response,
    # exposing typed arrays for each resource kind.
    #
    # @example
    #   result = Showroom::Search::Result.new(raw['resources']['results'])
    #   result.products     # => [Array<ProductSuggestion>]
    #   result.collections  # => [Array<CollectionSuggestion>]
    #   result.queries      # => [Array<QuerySuggestion>]
    class Result
      # @param results_hash [Hash] the +resources.results+ hash from the API response
      def initialize(results_hash)
        @data = results_hash
      end

      PRODUCT_ORDER_ATTRS = %w[id title handle price].freeze
      private_constant :PRODUCT_ORDER_ATTRS

      # Returns product suggestions from the search result, optionally sorted.
      #
      # @param order [Symbol, nil] attribute to sort by: +:id+, +:title+, +:handle+, or +:price+.
      #   When +nil+ (default) the API response order is preserved.
      #   +price+ is sorted numerically; all others alphabetically/numerically by natural value.
      # @return [Array<ProductSuggestion>]
      # @raise [ArgumentError] when an unsupported order attribute is given
      def products(order: nil)
        validate_order!(order)
        suggestions = @data.fetch('products', []).map { |h| ProductSuggestion.new(h) }
        return suggestions unless order

        sort_product_suggestions(suggestions, order)
      end

      # Returns collection suggestions from the search result.
      #
      # @return [Array<CollectionSuggestion>]
      def collections
        @data.fetch('collections', []).map { |h| CollectionSuggestion.new(h) }
      end

      # Returns page suggestions from the search result.
      #
      # @return [Array<PageSuggestion>]
      def pages
        @data.fetch('pages', []).map { |h| PageSuggestion.new(h) }
      end

      # Returns article suggestions from the search result.
      #
      # @return [Array<ArticleSuggestion>]
      def articles
        @data.fetch('articles', []).map { |h| ArticleSuggestion.new(h) }
      end

      # Returns query suggestions from the search result.
      #
      # @return [Array<QuerySuggestion>]
      def queries
        @data.fetch('queries', []).map { |h| QuerySuggestion.new(h) }
      end

      private

      def validate_order!(order)
        return unless order
        return if PRODUCT_ORDER_ATTRS.include?(order.to_s)

        raise ArgumentError, "order must be one of #{PRODUCT_ORDER_ATTRS.join(', ')}"
      end

      def sort_product_suggestions(suggestions, order)
        if order.to_s == 'price'
          suggestions.sort_by { |p| p.price.to_f }
        else
          suggestions.sort_by(&order.to_sym)
        end
      end
    end
  end
end
