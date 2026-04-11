# frozen_string_literal: true

require 'faraday'

module Showroom
  module Core
    # Mixin that provides HTTP connectivity via Faraday.
    #
    # Expects the including class to expose configuration keys from
    # {Configurable}: +store+, +user_agent+, +open_timeout+, +timeout+,
    # +middleware+, and +connection_options+.
    module Connection
      # @return [Faraday::Response, nil] the last HTTP response object
      attr_reader :last_response

      # Memoized Faraday connection built from the current configuration.
      #
      # @return [Faraday::Connection]
      def agent
        @agent ||= build_agent
      end

      # Performs a GET request and returns the parsed response body.
      #
      # @param path [String] path relative to the store base URL
      # @param params [Hash] query parameters
      # @return [Object] parsed JSON body (Hash or Array)
      def get(path, params = {})
        @last_response = agent.get(path, params)
        @last_response.body
      end

      # Iterates through paginated responses, yielding each page of items.
      #
      # Stops when a page returns an empty array or +pagination_depth+ is
      # reached.
      #
      # @param path [String] path relative to the store base URL
      # @param key [String] top-level JSON key containing the items array
      # @param params [Hash] base query parameters (page/limit are added automatically)
      # @yield [items, page] items on the current page and the page number
      # @yieldparam items [Array] the deserialized items for this page
      # @yieldparam page [Integer] 1-based page number
      # @return [void]
      def paginate(path, key, params = {}, max_pages: pagination_depth, &blk)
        page_limit = per_page

        (1..max_pages).each do |page|
          paged_params = params.merge(limit: page_limit, page: page)
          body         = get(path, paged_params)
          items        = body.is_a?(Hash) ? body[key] || body[key.to_s] : body

          break if items.nil? || items.empty?

          blk.call(items, page)
        end
      end

      private

      # Builds and returns a new Faraday connection.
      #
      # @return [Faraday::Connection]
      def build_agent
        base = StoreUrl.resolve(store)
        opts = (connection_options || {}).merge(url: base)
        Faraday.new(opts) do |conn|
          configure_conn(conn)
          middleware&.call(conn)
        end
      end

      # Applies default headers, timeouts, and middleware to +conn+.
      #
      # @param conn [Faraday::Connection]
      # @return [void]
      def configure_conn(conn)
        conn.headers['User-Agent'] = user_agent
        conn.options.open_timeout  = open_timeout
        conn.options.timeout       = timeout
        conn.use Http::Middleware::RaiseError
        conn.response :json, content_type: /\bjson\b/, parser_options: { symbolize_names: false }
        conn.adapter Faraday.default_adapter
      end
    end
  end
end
