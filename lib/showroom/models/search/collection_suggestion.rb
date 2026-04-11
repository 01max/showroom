# frozen_string_literal: true

module Showroom
  module Search
    # A lean collection shape returned by the Shopify search suggest endpoint.
    #
    # @example
    #   suggestion = Showroom::Search::CollectionSuggestion.new('title' => 'Lorem Helmets', 'handle' => 'lorem-helmets')
    #   suggestion.title  # => "Lorem Helmets"
    class CollectionSuggestion < Suggestion
      main_attrs :id, :title, :handle

      # @return [Class] the full model class for this suggestion type
      def self.complete_model_class
        Collection
      end
    end
  end
end
