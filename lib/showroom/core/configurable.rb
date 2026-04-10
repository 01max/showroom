# frozen_string_literal: true

require_relative 'default'

module Showroom
  module Core
    # Mixin that provides configuration DSL for the Showroom module and Client.
    #
    # When extended into a module or class it adds `configure`, `reset!`,
    # `options`, and `same_options?`, plus individual key accessors.
    #
    # @example Module-level usage
    #   Showroom.configure do |c|
    #     c.store = 'example.myshopify.com'
    #   end
    module Configurable
      # Ordered list of all supported configuration keys.
      KEYS = %i[
        store
        user_agent
        per_page
        pagination_depth
        open_timeout
        timeout
        middleware
        connection_options
      ].freeze

      # @!method store
      #   @return [String, nil]
      # @!method store=(value)
      #   @param value [String, nil]
      # (Similar accessors exist for all KEYS.)
      KEYS.each { |key| attr_accessor key }

      # Yields self for block-style configuration.
      #
      # @yield [self]
      # @return [self]
      def configure
        yield self
        self
      end

      # Resets all keys to their defaults from {Default}.
      #
      # @return [void]
      def reset!
        KEYS.each { |key| send(:"#{key}=", Default.public_send(key)) }
      end

      # Returns a frozen hash snapshot of the current configuration.
      #
      # @return [Hash{Symbol => Object}]
      def options
        KEYS.to_h { |key| [key, send(key)] }.freeze
      end

      # Returns true when +other_options+ matches the current configuration.
      #
      # @param other_options [Hash]
      # @return [Boolean]
      def same_options?(other_options)
        options == other_options
      end

      # Clamps per_page so it never exceeds {Default::MAX_PER_PAGE}.
      #
      # @param value [Integer]
      # @return [void]
      def per_page=(value)
        @per_page = [value.to_i, Default::MAX_PER_PAGE].min
      end
    end
  end
end
