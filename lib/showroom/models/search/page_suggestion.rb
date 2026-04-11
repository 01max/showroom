# frozen_string_literal: true

module Showroom
  module Search
    # A lean page shape returned by the Shopify search suggest endpoint.
    #
    # @example
    #   suggestion = Showroom::Search::PageSuggestion.new(
    #     'title' => 'About Lorem Bikes', 'handle' => 'about-lorem-bikes'
    #   )
    #   suggestion.title  # => "About Lorem Bikes"
    class PageSuggestion < Suggestion
      main_attrs :id, :title, :handle
    end
  end
end
