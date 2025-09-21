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
    # 
  end

  # DELETE /cart/:product_id
  def remove_product
    # todo
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
    when CartService::ProductNotInCartError
      render json: { error: error.message }, status: :not_found
    when CartService::InvalidQuantityError
      render json: { error: error.message }, status: :unprocessable_entity
    else
      render json: { error: error.message }, status: :unprocessable_entity
    end
  end

  def cart_service
    @cart_service ||= CartService.new
  end
end
