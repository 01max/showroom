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
      # @param client [Showroom::Client, nil] the client to propagate onto suggestions
      def initialize(results_hash, client: nil)
        @data = results_hash
        @client = client
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
        suggestions = build_suggestions('products', ProductSuggestion)
        return suggestions unless order

        sort_product_suggestions(suggestions, order)
      end

      # Returns collection suggestions from the search result.
      #
      # @return [Array<CollectionSuggestion>]
      def collections
        build_suggestions('collections', CollectionSuggestion)
      end

      # Returns page suggestions from the search result.
      #
      # @return [Array<PageSuggestion>]
      def pages
        build_suggestions('pages', PageSuggestion)
      end

      # Returns article suggestions from the search result.
      #
      # @return [Array<ArticleSuggestion>]
      def articles
        build_suggestions('articles', ArticleSuggestion)
      end

      # Returns query suggestions from the search result.
      #
      # @return [Array<QuerySuggestion>]
      def queries
        build_suggestions('queries', QuerySuggestion)
      end

      private

      def build_suggestions(key, klass)
        @data.fetch(key, []).map { |h| klass.new(h).tap { |s| s.client = @client } }
      end

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
