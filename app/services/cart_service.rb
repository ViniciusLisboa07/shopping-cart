# frozen_string_literal: true

class CartService
  class CartNotFoundError < StandardError; end
  class ProductNotFoundError < StandardError; end
  class ProductNotInCartError < StandardError; end

  def add_product_to_cart(session, product_id, quantity)
    product = find_product!(product_id)
    cart = find_or_create_cart(session)
    
    add_or_update_cart_item(cart, product, quantity)
    
    cart.reload
    Result.success(cart)
  rescue => error
    Result.failure(error)
  end


  def get_current_cart(session)
    cart = find_current_cart(session)
    Result.success(cart)
  rescue => error
    Result.failure(error)
  end

  private

  def find_product!(product_id)
    Product.find(product_id)
  rescue ActiveRecord::RecordNotFound
    raise ProductNotFoundError, 'Product not found'
  end

  def find_or_create_cart(session)
    cart = find_current_cart(session)
    return cart if cart

    cart = Cart.create!(
      total_price: 0.0,
      last_interaction_at: Time.current
    )
    
    session_manager.set_cart_id(session, cart.id)
    cart
  end

  def find_current_cart(session)
    cart_id = session_manager.get_cart_id(session)
    return nil unless cart_id

    Cart.find_by(id: cart_id)
  end

  def add_or_update_cart_item(cart, product, quantity)
    existing_item = cart.cart_items.find_by(product: product)
    
    if existing_item
      existing_item.update!(quantity: existing_item.quantity + quantity)
    else
      cart.cart_items.create!(product: product, quantity: quantity)
    end
  end

  def session_manager
    @session_manager ||= SessionManager.new
  end 
end
