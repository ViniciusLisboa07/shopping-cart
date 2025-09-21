class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product

  validates_presence_of :cart, :product, :quantity
  validates_numericality_of :quantity, greater_than: 0
end