require 'rails_helper'

RSpec.describe CartSerializer, type: :serializer do
  let!(:product1) { create(:product, name: "iPhone 15", price: 999.99) }
  let!(:product2) { create(:product, name: "Samsung Galaxy", price: 799.99) }

  describe '#as_api_json' do
    context 'when cart is nil' do
      let(:serializer) { CartSerializer.new(nil) }

      it 'returns empty cart JSON' do
        result = serializer.as_api_json

        expect(result).to eq({
          id: nil,
          products: [],
          total_price: 0.0
        })
      end
    end

    context 'when cart exists but is empty' do
      let(:cart) { create(:cart) }
      let(:serializer) { CartSerializer.new(cart) }

      it 'returns cart with empty products' do
        result = serializer.as_api_json

        expect(result).to eq({
          id: cart.id,
          products: [],
          total_price: 0.0
        })
      end
    end

    context 'when cart has one product' do
      let(:cart) { create(:cart) }
      let!(:cart_item) { create(:cart_item, cart: cart, product: product1, quantity: 2) }
      let(:serializer) { CartSerializer.new(cart) }

      before do
        cart.reload 
      end

      it 'returns cart with single product' do
        result = serializer.as_api_json

        expect(result[:id]).to eq(cart.id)
        expect(result[:products].size).to eq(1)
        expect(result[:products].first).to eq({
          id: product1.id,
          name: "iPhone 15",
          quantity: 2,
          unit_price: 999.99,
          total_price: 1999.98
        })
        expect(result[:total_price]).to eq(1999.98)
      end
    end

    context 'when cart has multiple products' do
      let(:cart) { create(:cart) }
      let!(:cart_item1) { create(:cart_item, cart: cart, product: product1, quantity: 1) }
      let!(:cart_item2) { create(:cart_item, cart: cart, product: product2, quantity: 3) }
      let(:serializer) { CartSerializer.new(cart) }

      before do
        cart.reload
      end

      it 'returns cart with multiple products' do
        result = serializer.as_api_json

        expect(result[:id]).to eq(cart.id)
        expect(result[:products].size).to eq(2)
        expect(result[:total_price]).to eq(3399.96) # 999.99 + (799.99 * 3)

        product1_item = result[:products].find { |p| p[:id] == product1.id }
        expect(product1_item).to eq({
          id: product1.id,
          name: "iPhone 15",
          quantity: 1,
          unit_price: 999.99,
          total_price: 999.99
        })

        product2_item = result[:products].find { |p| p[:id] == product2.id }
        expect(product2_item).to eq({
          id: product2.id,
          name: "Samsung Galaxy",
          quantity: 3,
          unit_price: 799.99,
          total_price: 2399.97
        })
      end

      it 'orders products consistently' do
        result1 = serializer.as_api_json
        result2 = serializer.as_api_json

        expect(result1[:products].map { |p| p[:id] }).to eq(result2[:products].map { |p| p[:id] })
      end
    end

    context 'when cart has zero total_price' do
      let(:cart) { create(:cart, total_price: 0.0) }
      let(:serializer) { CartSerializer.new(cart) }

      it 'returns 0.0 total_price' do
        result = serializer.as_api_json

        expect(result[:total_price]).to eq(0.0)
      end
    end

    context 'with decimal precision' do
      let(:product) { create(:product, name: "Expensive Item", price: 33.33) }
      let(:cart) { create(:cart) }
      let!(:cart_item) { create(:cart_item, cart: cart, product: product, quantity: 3) }
      let(:serializer) { CartSerializer.new(cart) }

      before do
        cart.reload
      end

      it 'handles decimal calculations correctly' do
        result = serializer.as_api_json

        expect(result[:products].first[:unit_price]).to eq(33.33)
        expect(result[:products].first[:total_price]).to eq(99.99)
        expect(result[:total_price]).to eq(99.99)
      end
    end
  end

  describe 'private methods' do
    let(:cart) { create(:cart) }
    let!(:cart_item) { create(:cart_item, cart: cart, product: product1, quantity: 1) }
    let(:serializer) { CartSerializer.new(cart) }

    describe '#serialize_cart_items' do
      it 'includes product associations efficiently' do
        expect(cart.cart_items).to receive(:includes).with(:product).and_call_original

        serializer.send(:serialize_cart_items)
      end

      it 'serializes each cart item correctly' do
        items = serializer.send(:serialize_cart_items)

        expect(items.size).to eq(1)
        expect(items.first).to include(
          id: product1.id,
          name: product1.name,
          quantity: cart_item.quantity,
          unit_price: product1.price,
          total_price: cart_item.total_price
        )
      end
    end

    describe '#empty_cart_json' do
      it 'returns empty cart structure' do
        result = serializer.send(:empty_cart_json)

        expect(result).to eq({
          id: nil,
          products: [],
          total_price: 0.0
        })
      end
    end
  end

  describe 'integration scenarios' do
    it 'handles cart lifecycle serialization' do
      cart = create(:cart)
      serializer = CartSerializer.new(cart)

      # Empty cart
      result = serializer.as_api_json
      expect(result[:products]).to be_empty
      expect(result[:total_price]).to eq(0.0)

      # Add first product
      create(:cart_item, cart: cart, product: product1, quantity: 1)
      cart.reload
      result = serializer.as_api_json
      expect(result[:products].size).to eq(1)
      expect(result[:total_price]).to eq(999.99)

      # Add second product
      create(:cart_item, cart: cart, product: product2, quantity: 2)
      cart.reload
      result = serializer.as_api_json
      expect(result[:products].size).to eq(2)
      expect(result[:total_price]).to eq(2599.97)
    end

    it 'maintains JSON structure consistency' do
      carts = [
        nil,
        create(:cart),
        create(:cart).tap { |c| create(:cart_item, cart: c, product: product1, quantity: 1) }
      ]

      carts.each do |cart|
        serializer = CartSerializer.new(cart)
        result = serializer.as_api_json

        # Check required keys exist
        expect(result).to have_key(:id)
        expect(result).to have_key(:products)
        expect(result).to have_key(:total_price)

        # Check types
        expect(result[:products]).to be_an(Array)
        expect(result[:total_price]).to be_a(Numeric)

        # Check product structure if products exist
        result[:products].each do |product|
          expect(product).to have_key(:id)
          expect(product).to have_key(:name)
          expect(product).to have_key(:quantity)
          expect(product).to have_key(:unit_price)
          expect(product).to have_key(:total_price)
        end
      end
    end
  end

  describe 'performance considerations' do
    let(:cart) { create(:cart) }

    context 'with many cart items' do
      before do
        # Create multiple products and cart items
        products = create_list(:product, 10)
        products.each_with_index do |product, index|
          create(:cart_item, cart: cart, product: product, quantity: index + 1)
        end
      end

      it 'efficiently loads associations' do
        serializer = CartSerializer.new(cart)

        # Test that it doesn't raise any errors with many items
        result = serializer.as_api_json
        expect(result[:products].size).to eq(10)
      end
    end
  end

  describe 'error handling' do
    context 'when cart_item has valid product' do
      let(:cart) { create(:cart) }
      let!(:cart_item) { create(:cart_item, cart: cart, product: product1, quantity: 1) }

      it 'handles normal cart items correctly' do
        serializer = CartSerializer.new(cart)

        result = serializer.as_api_json
        expect(result[:products].size).to eq(1)
        expect(result[:products].first[:id]).to eq(product1.id)
      end
    end
  end
end
