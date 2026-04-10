# frozen_string_literal: true

require_relative 'showroom/core/version'
require_relative 'showroom/core/error'
require_relative 'showroom/core/default'
require_relative 'showroom/core/configurable'
require_relative 'showroom/core/store_url'
require_relative 'showroom/http/middleware/raise_error'
require_relative 'showroom/core/connection'
require_relative 'showroom/client'

# Top-level namespace for the Showroom gem.
#
# Acts as a module-level client with {Core::Configurable} mixed in, so you can
# configure and use Showroom directly without instantiating a {Client}.
#
# @example Global configuration
#   Showroom.configure do |c|
#     c.store = 'example.myshopify.com'
#   end
#
# @example Module-level request
#   Showroom.client.get('/products.json')
module Showroom
  extend Core::Configurable

  reset!

  # Returns the memoized module-level {Client}.
  #
  # @return [Client]
  def self.client
    @client ||= Client.new(**options)
  end

  # Configures the module and resets the memoized client so the next call to
  # {.client} picks up the new settings.
  #
  # @yield [self]
  # @return [self]
  def self.configure
    super.tap { @client = nil }
  end

  # Resets all configuration to defaults and clears the memoized client.
  #
  # @return [void]
  def self.reset!
    super
    @client = nil
  end

  # Alias for {.configure} — yields self for block-style setup.
  #
  # @yield [self]
  # @return [self]
  def self.setup(&)
    configure(&)
  end
end
