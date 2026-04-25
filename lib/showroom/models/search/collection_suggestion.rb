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

      # Returns the canonical storefront URL for this collection suggestion.
      #
      # @return [String]
      def url
        conn = client || Showroom.client
        "#{conn.base_url}/collections/#{handle}"
      end
    end
  end
end
