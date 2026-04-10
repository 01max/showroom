# frozen_string_literal: true

require 'uri'

module Showroom
  module Core
    # Resolves a raw store identifier into a canonical HTTPS base URL.
    module StoreUrl
      # Resolves +store+ to a base URL string.
      #
      # @param store [String, nil] raw store value (domain, URL, etc.)
      # @return [String] canonical HTTPS base URL with no trailing slash
      # @raise [ConfigurationError] if store is blank or contains a non-root path
      #
      # @example
      #   StoreUrl.resolve('example.myshopify.com')           # => "https://example.myshopify.com"
      #   StoreUrl.resolve('https://example.myshopify.com/')  # => "https://example.myshopify.com"
      #   StoreUrl.resolve('http://example.myshopify.com')    # => "https://example.myshopify.com"
      def self.resolve(store)
        raise ConfigurationError, 'store must not be blank' if store.nil? || store.strip.empty?

        uri = parse_uri(store.strip)
        validate_path!(uri, store.strip)
        normalise(uri)
      rescue URI::InvalidURIError => e
        raise ConfigurationError, "invalid store URL: #{e.message}"
      end

      # @param raw [String] stripped store string
      # @return [URI::Generic]
      def self.parse_uri(raw)
        raw = "https://#{raw}" unless raw.match?(%r{\Ahttps?://}i)
        URI.parse(raw)
      end
      private_class_method :parse_uri

      # @param uri [URI::Generic]
      # @param original [String] original stripped store input (for error messages)
      # @raise [ConfigurationError] if the URI contains a non-root path
      def self.validate_path!(uri, original)
        path = uri.path.to_s.delete_suffix('/')
        return if path.empty?

        raise ConfigurationError, "store must be a bare domain, got path: #{original}"
      end
      private_class_method :validate_path!

      # @param uri [URI::Generic]
      # @return [String] canonical HTTPS base URL
      def self.normalise(uri)
        uri.scheme   = 'https'
        uri.path     = ''
        uri.query    = nil
        uri.fragment = nil
        uri.to_s
      end
      private_class_method :normalise
    end
  end
end
