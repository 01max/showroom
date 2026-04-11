# frozen_string_literal: true

module Showroom
  module Search
    # Base class for all search suggestion types.
    #
    # Subclasses that correspond to a fully-loadable model override {.complete_model_class}
    # to declare which model to fetch. Calling {#load} on a suggestion that has no
    # model raises +NoMethodError+.
    #
    # @example Loadable suggestion
    #   suggestion = result.products.first
    #   suggestion.load  # => Showroom::Product
    #
    # @example Non-loadable suggestion
    #   suggestion = result.queries.first
    #   suggestion.load  # => NoMethodError
    class Suggestion < Resource

      class << self
        # Override in subclasses to declare the corresponding full model class.
        #
        # @return [Class]
        # @raise [NoMethodError] when the suggestion type has no associated model
        def complete_model_class
          raise NoMethodError, "#{name} has no associated model — #load is not available"
        end
      end

      # Returns the identifier used to fetch the full record (defaults to the
      # +handle+ attribute). Override in subclasses when the identifier differs.
      #
      # @return [String]
      def loadable_identifier
        @attrs['handle']
      end

      # Fetches the full model record for this suggestion.
      #
      # Delegates to the model class declared by {.complete_model_class}, finding
      # by {#loadable_identifier}.
      #
      # @return [Resource]
      # @raise [NoMethodError] when the suggestion type has no associated model
      # @raise [Showroom::NotFound] when the record is not found
      def load
        self.class.complete_model_class.find(loadable_identifier)
      end
    end
  end
end
