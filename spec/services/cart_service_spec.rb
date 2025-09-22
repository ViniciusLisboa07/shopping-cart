require 'rails_helper'

RSpec.describe CartService, type: :service do
  include ActiveSupport::Testing::TimeHelpers
  let(:service) { described_class.new }
  let(:session) { {} }
  let!(:product) { create(:product, name: "iPhone 15", price: 999.99) }
  let!(:product2) { create(:product, name: "Samsung Galaxy", price: 799.99) }

  describe '#add_product_to_cart' do
    context 'with valid parameters' do
      it 'creates a new cart when no cart exists' do
        result = service.add_product_to_cart(session, product.id, 2)
        
        expect(result.success?).to be true
        expect(result.data).to be_a(Cart)
        expect(result.data.cart_items.count).to eq(1)
        expect(result.data.cart_items.first.product).to eq(product)
        expect(result.data.cart_items.first.quantity).to eq(2)
        expect(result.data.total_price).to eq(1999.98)
      end

      it 'adds product to existing cart' do
        service.add_product_to_cart(session, product.id, 1)
        
        result = service.add_product_to_cart(session, product2.id, 2)
        
        expect(result.success?).to be true
        expect(result.data.cart_items.count).to eq(2)
        expect(result.data.total_price).to eq(2599.97)
      end

      it 'increases quantity when adding same product' do
        service.add_product_to_cart(session, product.id, 1)
        
        result = service.add_product_to_cart(session, product.id, 2)
        
        expect(result.success?).to be true
        expect(result.data.cart_items.count).to eq(1)
        expect(result.data.cart_items.first.quantity).to eq(3)
        expect(result.data.total_price).to eq(2999.97)
      end

      it 'updates last_interaction_at' do
        travel_to Time.parse("2023-01-01 12:00:00") do
          result = service.add_product_to_cart(session, product.id, 1)
          expect(result.data.last_interaction_at).to be_within(1.second).of(Time.current)
        end
      end
    end

    context 'with invalid parameters' do
      it 'returns failure when product does not exist' do
        result = service.add_product_to_cart(session, 99999, 1)
        
        expect(result.failure?).to be true
        expect(result.error).to be_a(CartService::ProductNotFoundError)
        expect(result.error.message).to eq('Product not found')
      end

      it 'returns failure when quantity is zero' do
        result = service.add_product_to_cart(session, product.id, 0)
        
        expect(result.failure?).to be true
        expect(result.error).to be_a(CartService::InvalidQuantityError)
        expect(result.error.message).to eq('Quantity must be greater than 0')
      end

      it 'returns failure when quantity is negative' do
        result = service.add_product_to_cart(session, product.id, -1)
        
        expect(result.failure?).to be true
        expect(result.error).to be_a(CartService::InvalidQuantityError)
        expect(result.error.message).to eq('Quantity must be greater than 0')
      end
    end
  end

  describe '#update_product_quantity' do
    let!(:cart) { create(:cart) }

    before do
      service.add_product_to_cart(session, product.id, 1)
    end

    context 'with valid parameters' do
      it 'updates quantity of existing product' do
        result = service.update_product_quantity(session, product.id, 3)
        
        expect(result.success?).to be true
        expect(result.data.cart_items.first.quantity).to eq(4) # 1 + 3
        expect(result.data.total_price).to eq(3999.96)
      end

      it 'adds new product when it does not exist in cart' do
        result = service.update_product_quantity(session, product2.id, 2)
        
        expect(result.success?).to be true
        expect(result.data.cart_items.count).to eq(2)
        
        product2_item = result.data.cart_items.find_by(product: product2)
        expect(product2_item.quantity).to eq(2)
      end
    end

    context 'with invalid parameters' do
      it 'returns failure when product does not exist' do
        result = service.update_product_quantity(session, 99999, 1)
        
        expect(result.failure?).to be true
        expect(result.error).to be_a(CartService::ProductNotFoundError)
      end

      it 'returns failure when quantity is zero' do
        result = service.update_product_quantity(session, product.id, 0)
        
        expect(result.failure?).to be true
        expect(result.error).to be_a(CartService::InvalidQuantityError)
      end
    end
  end

  describe '#get_current_cart' do
    context 'when cart exists' do
      it 'returns the current cart' do
        service.add_product_to_cart(session, product.id, 1)
        
        result = service.get_current_cart(session)
        
        expect(result.success?).to be true
        expect(result.data).to be_a(Cart)
        expect(result.data.cart_items.count).to eq(1)
      end
    end

    context 'when cart does not exist' do
      it 'returns nil' do
        result = service.get_current_cart(session)
        
        expect(result.success?).to be true
        expect(result.data).to be_nil
      end
    end

    context 'when cart_id exists but cart was deleted' do
      it 'returns nil' do
        service.add_product_to_cart(session, product.id, 1)
        Cart.destroy_all
        
        result = service.get_current_cart(session)
        
        expect(result.success?).to be true
        expect(result.data).to be_nil
      end
    end
  end

  describe '#remove_product_from_cart' do
    before do
      service.add_product_to_cart(session, product.id, 2)
      service.add_product_to_cart(session, product2.id, 1)
    end

    context 'with valid parameters' do
      it 'removes product from cart' do
        result = service.remove_product_from_cart(session, product.id)
        
        expect(result.success?).to be true
        expect(result.data.cart_items.count).to eq(1)
        expect(result.data.cart_items.first.product).to eq(product2)
        expect(result.data.total_price).to eq(799.99)
      end

      it 'updates last_interaction_at when removing product' do
        travel_to Time.parse("2023-01-01 12:00:00") do
          result = service.remove_product_from_cart(session, product.id)
          expect(result.data.last_interaction_at).to be_within(1.second).of(Time.current)
        end
      end
    end

    context 'with invalid parameters' do
      it 'returns failure when cart does not exist' do
        empty_session = {}
        result = service.remove_product_from_cart(empty_session, product.id)
        
        expect(result.failure?).to be true
        expect(result.error).to be_a(CartService::CartNotFoundError)
        expect(result.error.message).to eq('Cart not found')
      end

      it 'returns failure when cart is empty' do
        service.remove_product_from_cart(session, product.id)
        service.remove_product_from_cart(session, product2.id)
        
        result = service.remove_product_from_cart(session, product.id)
        
        expect(result.failure?).to be true
        expect(result.error).to be_a(CartService::EmptyCartError)
        expect(result.error.message).to eq('Cart is empty')
      end

      it 'returns failure when product does not exist' do
        result = service.remove_product_from_cart(session, 99999)
        
        expect(result.failure?).to be true
        expect(result.error).to be_a(CartService::ProductNotFoundError)
        expect(result.error.message).to eq('Product not found')
      end

      it 'returns failure when product is not in cart' do
        product3 = create(:product, name: "MacBook", price: 1299.99)
        
        result = service.remove_product_from_cart(session, product3.id)
        
        expect(result.failure?).to be true
        expect(result.error).to be_a(CartService::ProductNotFoundError)
        expect(result.error.message).to eq('Product not found in cart')
      end
    end
  end

  describe 'private methods' do
    describe '#find_product!' do
      it 'finds existing product' do
        found_product = service.send(:find_product!, product.id)
        expect(found_product).to eq(product)
      end

      it 'raises ProductNotFoundError for non-existent product' do
        expect {
          service.send(:find_product!, 99999)
        }.to raise_error(CartService::ProductNotFoundError, 'Product not found')
      end
    end

    describe '#validate_quantity!' do
      it 'does not raise error for valid quantity' do
        expect {
          service.send(:validate_quantity!, 1)
        }.not_to raise_error
      end

      it 'raises InvalidQuantityError for zero quantity' do
        expect {
          service.send(:validate_quantity!, 0)
        }.to raise_error(CartService::InvalidQuantityError, 'Quantity must be greater than 0')
      end

      it 'raises InvalidQuantityError for negative quantity' do
        expect {
          service.send(:validate_quantity!, -1)
        }.to raise_error(CartService::InvalidQuantityError, 'Quantity must be greater than 0')
      end
    end

    describe '#find_or_create_cart' do
      context 'when cart exists' do
        it 'returns existing cart' do
          service.add_product_to_cart(session, product.id, 1)
          
          cart1 = service.send(:find_or_create_cart, session)
          cart2 = service.send(:find_or_create_cart, session)
          
          expect(cart1).to eq(cart2)
        end
      end

      context 'when cart does not exist' do
        it 'creates new cart' do
          cart = service.send(:find_or_create_cart, session)
          
          expect(cart).to be_a(Cart)
          expect(cart.persisted?).to be true
          expect(cart.total_price).to eq(0.0)
          expect(cart.last_interaction_at).to be_present
        end

        it 'sets cart_id in session' do
          cart = service.send(:find_or_create_cart, session)
          expect(session[:cart_id]).to eq(cart.id)
        end
      end
    end

    describe '#find_current_cart' do
      it 'returns nil when no cart_id in session' do
        cart = service.send(:find_current_cart, {})
        expect(cart).to be_nil
      end

      it 'returns nil when cart_id exists but cart does not exist' do
        session[:cart_id] = 99999
        cart = service.send(:find_current_cart, session)
        expect(cart).to be_nil
      end

      it 'returns cart when cart_id exists and cart exists' do
        service.add_product_to_cart(session, product.id, 1)
        cart = service.send(:find_current_cart, session)
        
        expect(cart).to be_a(Cart)
        expect(cart.id).to eq(session[:cart_id])
      end
    end
  end

  describe 'integration scenarios' do
    it 'handles complete shopping flow' do
      result1 = service.add_product_to_cart(session, product.id, 2)
      expect(result1.success?).to be true
      expect(result1.data.total_price).to eq(1999.98)

      result2 = service.add_product_to_cart(session, product2.id, 1)
      expect(result2.success?).to be true
      expect(result2.data.total_price).to eq(2799.97)

      result3 = service.update_product_quantity(session, product.id, 1)
      expect(result3.success?).to be true
      expect(result3.data.cart_items.find_by(product: product).quantity).to eq(3)
      expect(result3.data.total_price).to eq(3799.96)

      result4 = service.remove_product_from_cart(session, product2.id)
      expect(result4.success?).to be true
      expect(result4.data.cart_items.count).to eq(1)
      expect(result4.data.total_price).to eq(2999.97)

      result5 = service.get_current_cart(session)
      expect(result5.success?).to be true
      expect(result5.data.cart_items.count).to eq(1)
      expect(result5.data.total_price).to eq(2999.97)
    end
  end
end
