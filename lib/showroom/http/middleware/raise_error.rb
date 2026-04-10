# frozen_string_literal: true

require 'faraday'

module Showroom
  # Faraday HTTP layer (adapters, middleware).
  module Http
    # Faraday middleware classes.
    module Middleware
      # Faraday middleware that maps HTTP error statuses and parsing failures
      # to Showroom error classes.
      #
      # @example Registration
      #   conn.use Showroom::Http::Middleware::RaiseError
      class RaiseError < Faraday::Middleware
        # Maps specific HTTP status codes to Showroom error classes.
        STATUS_MAP = {
          400 => Showroom::BadRequest,
          404 => Showroom::NotFound,
          422 => Showroom::UnprocessableEntity,
          429 => Showroom::TooManyRequests
        }.freeze

        # Executes the middleware, rescuing network-level Faraday errors.
        #
        # @param env [Faraday::Env]
        # @raise [ConnectionError] on connection or timeout failure
        # @raise [InvalidResponse] on JSON parsing failure
        def call(env)
          @app.call(env).on_complete { |response_env| on_complete(response_env) }
        rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
          raise ConnectionError, e.message
        rescue Faraday::ParsingError
          raise InvalidResponse,
                'Response was not JSON — store may be password-protected or blocking requests'
        end

        private

        # Inspects the completed response and raises the appropriate error.
        #
        # @param env [Faraday::Env]
        # @raise [InvalidResponse] when a 200 response has a non-JSON content-type
        # @raise [ResponseError] (or subclass) for 4xx/5xx responses
        def on_complete(env)
          check_html_response!(env) if env.status == 200
          raise_for_status!(env) if env.status >= 400
        end

        # @param env [Faraday::Env]
        # @raise [InvalidResponse] if Content-Type indicates HTML
        def check_html_response!(env)
          content_type = env.response_headers['content-type'].to_s
          return unless content_type.include?('text/html')

          raise InvalidResponse,
                'Response was not JSON — store may be password-protected or blocking requests'
        end

        # @param env [Faraday::Env]
        # @raise [ResponseError] (or subclass) matching the status code
        def raise_for_status!(env)
          klass = error_class(env.status)
          raise klass.new(nil, status: env.status, body: env.body, headers: env.response_headers)
        end

        # @param status [Integer]
        # @return [Class] the most specific matching Showroom error class
        def error_class(status)
          STATUS_MAP.fetch(status) do
            if status >= 500
              ServerError
            else
              ClientError
            end
          end
        end
      end
    end
  end
end
