# frozen_string_literal: true

module Showroom
  module Search
    # A query suggestion returned by the Shopify search suggest endpoint.
    #
    # @example
    #   suggestion = Showroom::Search::QuerySuggestion.new('text' => 'lorem road bike')
    #   suggestion.text  # => "lorem road bike"
    class QuerySuggestion < Suggestion
      main_attrs :text
    end
  end
end
