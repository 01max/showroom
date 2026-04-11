# frozen_string_literal: true

module Showroom
  module Core
    # Provides default configuration values for the gem, with optional
    # overrides via environment variables.
    module Default
      # Maximum allowed value for per_page.
      MAX_PER_PAGE = 250

      # @return [nil] store is required and has no default
      def self.store
        ENV.fetch('SHOWROOM_STORE', nil)
      end

      # @return [String] default User-Agent header value
      def self.user_agent
        ENV.fetch(
          'SHOWROOM_USER_AGENT',
          "Showroom/#{VERSION} (+https://github.com/01max/showroom; Ruby/#{RUBY_VERSION})"
        )
      end

      # @return [Integer] number of results per page, clamped to MAX_PER_PAGE
      def self.per_page
        raw = ENV.fetch('SHOWROOM_PER_PAGE', 50).to_i
        [raw, MAX_PER_PAGE].min
      end

      # @return [Integer] maximum number of pages to fetch during pagination
      def self.pagination_depth
        50
      end

      # @return [Integer] open (connect) timeout in seconds
      def self.open_timeout
        ENV.fetch('SHOWROOM_OPEN_TIMEOUT', 10).to_i
      end

      # @return [Integer] read timeout in seconds
      def self.timeout
        ENV.fetch('SHOWROOM_TIMEOUT', 30).to_i
      end

      # @return [nil] no custom middleware by default
      def self.middleware
        nil
      end

      # @return [Hash] extra options passed to Faraday connection
      def self.connection_options
        {}
      end

      # @return [Boolean] whether to print debug output for each request
      def self.debug # rubocop:disable Naming/PredicateMethod
        ENV.fetch('SHOWROOM_DEBUG', nil) == '1'
      end
    end
  end
end
