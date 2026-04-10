# frozen_string_literal: true

module Showroom
  # Represents a Shopify product option (e.g. Size, Color).
  #
  # @example
  #   opt = ProductOption.new('name' => 'Size', 'position' => 1, 'values' => ['S', 'M'])
  #   opt.name   # => "Size"
  #   opt.values # => ["S", "M"]
  class ProductOption < Resource
    main_attrs :name, :position
  end
end
