# frozen_string_literal: true

module Showroom
  # Represents a Shopify product image.
  #
  # @example
  #   image = ProductImage.new('id' => 1, 'src' => 'https://example.com/img.jpg')
  #   image.src # => "https://example.com/img.jpg"
  class ProductImage < Resource
    main_attrs :id, :src, :position
  end
end
