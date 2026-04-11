# frozen_string_literal: true

module Showroom
  # Provides search/suggest functionality against the Shopify search API.
  #
  # @example
  #   result = Showroom::Search.suggest('lorem', types: [:product, :collection], limit: 5)
  #   result.products.first.title  # => "Lorem Road Bike"
  module Search
    # Calls GET /search/suggest.json and returns a {Result} wrapping the response.
    #
    # Builds query parameters of the form:
    #   ?q=...&resources[type]=product,collection&resources[limit]=10
    #
    # @param query_str [String] the search query
    # @param types [Array<Symbol>] resource types to search (e.g. +:product+, +:collection+, +:query+)
    # @param limit [Integer] maximum number of results per type
    # @param params [Hash] additional query parameters forwarded to the API
    # @return [Result]
    def self.suggest(query_str, types: %i[product collection], limit: Showroom.per_page, **params)
      query = { q: query_str, 'resources[limit]' => limit }
      query['resources[type]'] = types.join(',') unless types.empty?
      query.merge!(params)
      raw = Showroom.client.get('/search/suggest.json', query)
      Result.new(raw.dig('resources', 'results') || {})
    end
  end
end
