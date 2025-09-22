# frozen_string_literal: true

class CartService
  MINIMUM_QUANTITY = 1
  DEFAULT_CART_TOTAL = 0.0
  
  class CartNotFoundError < StandardError; end
  class ProductNotFoundError < StandardError; end
  class InvalidQuantityError < StandardError; end
  class EmptyCartError < StandardError; end

  def add_product_to_cart(session, product_id, quantity)
    execute_cart_operation(session, product_id, quantity) do |cart, product, qty|
      add_or_update_cart_item(cart, product, qty)
    end
  end

  def update_product_quantity(session, product_id, quantity)
    execute_cart_operation(session, product_id, quantity) do |cart, product, qty|
      set_cart_item_quantity(cart, product, qty)
    end
  end

  def get_current_cart(session)
    cart = find_current_cart(session)
    Result.success(cart)
  rescue => error
    Result.failure(error)
  end

  def remove_product_from_cart(session, product_id)
    product = find_product!(product_id)
    cart = find_current_cart(session)

    raise CartNotFoundError, 'Cart not found' unless cart

    raise EmptyCartError, 'Cart is empty' if cart.empty?

    cart_item = cart.cart_items.find_by(product: product)
    raise ProductNotFoundError, 'Product not found in cart' unless cart_item

    cart_item.destroy!
    cart.touch(:last_interaction_at)
    cart.reload

    Result.success(cart)
  rescue => error
    Result.failure(error)
  end

  private

  def execute_cart_operation(session, product_id, quantity)
    validate_quantity!(quantity)
    
    product = find_product!(product_id)
    cart = find_or_create_cart(session)
    
    yield(cart, product, quantity)
    
    cart.reload
    Result.success(cart)
  rescue => error
    Result.failure(error)
  end

  def find_product!(product_id)
    Product.find(product_id)
  rescue ActiveRecord::RecordNotFound
    raise ProductNotFoundError, 'Product not found'
  end

  def find_or_create_cart(session)
    cart = find_current_cart(session)
    return cart if cart

    cart = Cart.create!(
      total_price: DEFAULT_CART_TOTAL,
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

  def validate_quantity!(quantity)
    if quantity < MINIMUM_QUANTITY
      raise InvalidQuantityError, "Quantity must be greater than 0"
    end
  end

  def set_cart_item_quantity(cart, product, quantity)
    existing_item = cart.cart_items.find_or_create_by(product: product)
    new_quantity = existing_item.quantity + quantity

    if should_remove_item?(new_quantity)
      remove_cart_item_if_persisted(existing_item)
    else
      update_cart_item_quantity(existing_item, new_quantity)
    end
  end

  def should_remove_item?(quantity)
    quantity <= 0
  end

  def remove_cart_item_if_persisted(item)
    item.destroy! if item.persisted?
  end

  def update_cart_item_quantity(item, quantity)
    item.update!(quantity: quantity)
  end

  def session_manager
    @session_manager ||= SessionManager.new
  end 
end
