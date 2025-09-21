class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product

  validates_presence_of :cart, :product, :quantity
  validates_numericality_of :quantity, greater_than: 0
  validates_numericality_of :total_price, greater_than_or_equal_to: 0

  before_save :calculate_total_price

  private

  def calculate_total_price
    self.total_price = product.price * quantity
  end
end