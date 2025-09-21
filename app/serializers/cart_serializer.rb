# frozen_string_literal: true

class CartSerializer
  def initialize(cart)
    @cart = cart
  end

  def as_api_json
    return empty_cart_json unless @cart

    {
      id: @cart.id,
      products: serialize_cart_items,
      total_price: @cart.total_price || 0.0
    }
  end

  private

  attr_reader :cart

  def serialize_cart_items
    @cart.cart_items.includes(:product).map do |item|
      {
        id: item.product.id,
        name: item.product.name,
        quantity: item.quantity,
        unit_price: item.product.price,
        total_price: item.total_price
      }
    end
  end

  def empty_cart_json
    {
      id: nil,
      products: [],
      total_price: 0.0
    }
  end
end
