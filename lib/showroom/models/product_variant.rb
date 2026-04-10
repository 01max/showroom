# frozen_string_literal: true

module Showroom
  # Represents a Shopify product variant.
  #
  # @example
  #   variant = ProductVariant.new('title' => 'S / Red', 'price' => '899.00', 'available' => true)
  #   variant.available? # => true
  #   variant.on_sale?   # => false
  class ProductVariant < Resource
    main_attrs :id, :title, :price, :sku

    # Returns true when the variant is available for purchase.
    #
    # @return [Boolean]
    def available?
      @attrs['available'] == true
    end

    # Returns true when +compare_at_price+ is present and greater than +price+.
    #
    # @return [Boolean]
    def on_sale?
      cap = @attrs['compare_at_price']
      return false if cap.nil? || cap.to_s.empty?

      cap.to_f > @attrs['price'].to_f
    end

    # Returns the selected options for this variant as an Array of values.
    #
    # Collects option1, option2, option3 in order, omitting nil values.
    #
    # @return [Array<String>]
    def options
      [@attrs['option1'], @attrs['option2'], @attrs['option3']].compact
    end
  end
end
