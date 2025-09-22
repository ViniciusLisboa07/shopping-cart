# frozen_string_literal: true

class CartSerializer
  DEFAULT_TOTAL_PRICE = 0.0

  def initialize(cart)
    @cart = cart
  end

  def as_api_json
    return empty_cart_json unless cart_present?

    build_cart_json
  end

  private

  attr_reader :cart

  def cart_present?
    @cart.present?
  end

  def build_cart_json
    {
      id: cart.id,
      products: serialize_cart_items,
      total_price: cart_total_price
    }
  end

  def cart_total_price
    cart.total_price || DEFAULT_TOTAL_PRICE
  end

  def serialize_cart_items
    cart.cart_items.includes(:product).map do |item|
      build_item_json(item)
    end
  end

  def build_item_json(item)
    {
      id: item.product.id,
      name: item.product.name,
      quantity: item.quantity,
      unit_price: item.product.price,
      total_price: item.total_price
    }
  end

  def empty_cart_json
    {
      id: nil,
      products: [],
      total_price: DEFAULT_TOTAL_PRICE
    }
  end
end
