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

      # Returns product suggestions from the search result.
      #
      # @return [Array<ProductSuggestion>]
      def products
        @data.fetch('products', []).map { |h| ProductSuggestion.new(h) }
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
    end
  end
end
