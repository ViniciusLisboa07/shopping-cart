class CartsController < ApplicationController
  # POST /cart
  def add_product
    result = cart_service.add_product_to_cart(
      session, 
      params[:product_id], 
      params[:quantity].to_i
    )

    handle_result(result)
  end

  # GET /cart
  def show
    result = cart_service.get_current_cart(session)
    handle_result(result)
  end

  # POST /cart/add_item
  def add_item
    result = cart_service.update_product_quantity(
      session,
      params[:product_id],
      params[:quantity].to_i
    )

    handle_result(result)
  end

  def remove_product
    result = cart_service.remove_product_from_cart(
      session,
      params[:product_id]
    )

    handle_result(result)
  end
  private

  def handle_result(result)
    if result.success?
      cart = result.data
      serialized_cart = CartSerializer.new(cart).as_api_json
      render json: serialized_cart, status: :ok
    else
      handle_error(result.error)
    end
  end

  def handle_error(error)
    case error
    when CartService::ProductNotFoundError
      render json: { error: error.message }, status: :not_found
    when CartService::CartNotFoundError
      render json: { error: error.message }, status: :not_found
    when CartService::EmptyCartError
      render json: { error: error.message }, status: :not_found
    else
      render json: { error: error.message }, status: :unprocessable_entity
    end
  end

  def cart_service
    @cart_service ||= CartService.new
  end
end
