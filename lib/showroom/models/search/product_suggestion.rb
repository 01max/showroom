# frozen_string_literal: true

module Showroom
  module Search
    # A lean product shape returned by the Shopify search suggest endpoint.
    #
    # @example
    #   suggestion = Showroom::Search::ProductSuggestion.new('title' => 'Lorem Road Bike', 'price' => '899.00')
    #   suggestion.title  # => "Lorem Road Bike"
    #   suggestion.price  # => "899.00"
    class ProductSuggestion < Suggestion
      main_attrs :id, :title, :handle, :price

      # @return [Class] the full model class for this suggestion type
      def self.complete_model_class
        Product
      end

      # Returns the canonical storefront URL for this product suggestion.
      #
      # @return [String]
      def url
        conn = client || Showroom.client
        "#{conn.base_url}/products/#{handle}"
      end
    end
  end
end
