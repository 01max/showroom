# frozen_string_literal: true

module Showroom
  module Search
    # A lean article shape returned by the Shopify search suggest endpoint.
    #
    # @example
    #   suggestion = Showroom::Search::ArticleSuggestion.new('title' => 'How to Choose a Road Bike')
    #   suggestion.title  # => "How to Choose a Road Bike"
    class ArticleSuggestion < Suggestion
      main_attrs :id, :title, :handle
    end
  end
end
