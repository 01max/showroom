# frozen_string_literal: true

module Showroom
  # Base error class for all Showroom errors.
  class Error < StandardError; end

  # Raised when the gem is misconfigured (e.g. missing or invalid store URL).
  class ConfigurationError < Error; end

  # Raised when a network-level failure occurs (connection refused, timeout, etc.).
  class ConnectionError < Error; end

  # Raised when the response body is not JSON (e.g. store is password-protected).
  class InvalidResponse < Error; end

  # Raised for HTTP responses with status >= 400.
  #
  # @attr_reader status [Integer] HTTP status code
  # @attr_reader body [String, nil] raw response body
  # @attr_reader headers [Hash] response headers
  class ResponseError < Error
    attr_reader :status, :body, :headers

    # @param message [String] error message
    # @param status [Integer] HTTP status code
    # @param body [String, nil] raw response body
    # @param headers [Hash] response headers
    def initialize(message = nil, status: nil, body: nil, headers: {})
      super(message || "HTTP #{status}")
      @status  = status
      @body    = body
      @headers = headers
    end
  end

  # Raised for HTTP 4xx responses.
  class ClientError < ResponseError; end

  # Raised for HTTP 400 Bad Request.
  class BadRequest < ClientError; end

  # Raised for HTTP 404 Not Found.
  class NotFound < ClientError; end

  # Raised for HTTP 422 Unprocessable Entity.
  class UnprocessableEntity < ClientError; end

  # Raised for HTTP 429 Too Many Requests.
  class TooManyRequests < ClientError; end

  # Raised for HTTP 5xx responses.
  class ServerError < ResponseError; end
end
