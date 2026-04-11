#!/usr/bin/env ruby
# frozen_string_literal: true

# basic_usage.rb — runnable Showroom usage examples
#
# Replace 'acme.myshopify.com' with your actual Shopify store domain before running.
#
# Usage:
#   bundle exec ruby examples/basic_usage.rb

require 'showroom'

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
Showroom.configure do |c|
  c.store    = 'acme.myshopify.com' # <-- replace with your store
  c.per_page = 10
  c.timeout  = 15
end

# ---------------------------------------------------------------------------
# List products (single page)
# ---------------------------------------------------------------------------
puts '=== Products (first page) ==='
products = Showroom::Product.where(limit: 5)
products.each { |p| puts "  #{p.title}  #{p.price}" }

# ---------------------------------------------------------------------------
# Find a single product by handle
# ---------------------------------------------------------------------------
puts "\n=== Single product ==="
product = Showroom::Product.find('some-product-handle')
puts "  Title:     #{product.title}"
puts "  Vendor:    #{product.vendor}"
puts "  Available: #{product.available?}"
puts "  Price:     #{product.price}"
puts '  Variants:'
product.variants.each { |v| puts "    - #{v.title}  #{v.price}  on_sale=#{v.on_sale?}" }

# ---------------------------------------------------------------------------
# Iterate all products (lazy pagination)
# ---------------------------------------------------------------------------
puts "\n=== First 5 products via .all ==="
Showroom::Product.all.first(5).each { |p| puts "  #{p.handle}" }

# ---------------------------------------------------------------------------
# Search (suggest endpoint)
# ---------------------------------------------------------------------------
puts "\n=== Search: 'bike' ==="
result = Showroom.search('bike', types: %i[product collection query], limit: 3)

puts '  Products:'
result.products.each { |s| puts "    #{s.title}  (#{s.handle})" }

puts '  Collections:'
result.collections.each { |s| puts "    #{s.title}" }

puts '  Queries:'
result.queries.each { |s| puts "    #{s.text}" }

# Load the first product suggestion into a full Product record (one HTTP request)
first = result.products.first
if first
  puts "\n  Loading full record for '#{first.handle}'…"
  full_product = first.load
  puts "  Loaded: #{full_product.title}  available=#{full_product.available?}"
end

# ---------------------------------------------------------------------------
# Error handling
# ---------------------------------------------------------------------------
puts "\n=== Error handling ==="
begin
  Showroom::Product.find('this-handle-does-not-exist')
rescue Showroom::NotFound => e
  puts "  NotFound: #{e.message}"
rescue Showroom::TooManyRequests
  puts '  Rate limited — add back-off logic here'
rescue Showroom::InvalidResponse
  puts '  Store may be password-protected or blocking requests'
rescue Showroom::ConnectionError => e
  puts "  Network error: #{e.message}"
rescue Showroom::Error => e
  puts "  Showroom error: #{e}"
end
