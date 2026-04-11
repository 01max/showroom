#!/usr/bin/env ruby
# frozen_string_literal: true

# multi_store.rb — shows how to use Showroom::Client for multiple stores
# simultaneously, without touching the module-level global configuration.
#
# Replace the store domains and handles below with real values before running.
#
# Usage:
#   bundle exec ruby examples/multi_store.rb

require 'showroom'

# ---------------------------------------------------------------------------
# Create one client per store
# ---------------------------------------------------------------------------
acme  = Showroom::Client.new(store: 'acme.myshopify.com',  per_page: 5)
globo = Showroom::Client.new(store: 'globo.myshopify.com', per_page: 5)

# ---------------------------------------------------------------------------
# Fetch products from each store independently
# ---------------------------------------------------------------------------
puts '=== ACME products ==='
acme_products = acme.products(limit: 5)
acme_products.each { |p| puts "  #{p.title}  #{p.price}" }

puts "\n=== Globo products ==="
globo_products = globo.products(limit: 5)
globo_products.each { |p| puts "  #{p.title}  #{p.price}" }

# ---------------------------------------------------------------------------
# Find a specific product on one store
# ---------------------------------------------------------------------------
puts "\n=== Single product from ACME ==="
product = acme.product('some-acme-handle')
puts "  #{product.title}  available=#{product.available?}"

# ---------------------------------------------------------------------------
# Fetch collections from each store
# ---------------------------------------------------------------------------
puts "\n=== ACME collections ==="
acme.collections(limit: 3).each { |c| puts "  #{c.title}  (#{c.handle})" }

puts "\n=== Globo collections ==="
globo.collections(limit: 3).each { |c| puts "  #{c.title}  (#{c.handle})" }
