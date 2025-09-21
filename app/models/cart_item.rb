class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product

  validates_presence_of :cart, :product, :quantity
  validates_numericality_of :quantity, greater_than: 0
  validates_numericality_of :total_price, greater_than_or_equal_to: 0

  before_save :calculate_total_price
  after_save :update_cart_total
  after_destroy :update_cart_total

  private

  def calculate_total_price
    self.total_price = product.price * quantity if product
  end

  def update_cart_total
    cart&.recalculate_total!
  end
end