require 'rails_helper'

RSpec.describe CartItem, type: :model do
  context 'when validating' do
    it 'validates numericality of total_price' do
      cart_item = described_class.new(total_price: -1)
      expect(cart_item.valid?).to be_falsey
      expect(cart_item.errors[:total_price]).to include("must be greater than or equal to 0")
    end
  end

  describe 'calculate_total_price' do
    it 'calculates the total price of the cart item' do
      cart_item = described_class.new(product: create(:product, price: 10), quantity: 2, cart: create(:cart))
      cart_item.save!
      expect(cart_item.total_price).to eq(20)
    end
  end
end
