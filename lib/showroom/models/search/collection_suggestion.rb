# frozen_string_literal: true

module Showroom
  module Search
    # A lean collection shape returned by the Shopify search suggest endpoint.
    #
    # @example
    #   suggestion = Showroom::Search::CollectionSuggestion.new('title' => 'Lorem Helmets', 'handle' => 'lorem-helmets')
    #   suggestion.title  # => "Lorem Helmets"
    class CollectionSuggestion < Resource
      main_attrs :id, :title, :handle
    end
  end
end
