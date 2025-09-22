require 'rails_helper'

RSpec.describe "/carts", type: :request do
  let!(:product1) { create(:product, name: "iPhone 15", price: 999.99) }
  let!(:product2) { create(:product, name: "Samsung Galaxy", price: 799.99) }


  describe "POST /cart" do
    context "when adding a product to cart" do
      it "creates a new cart and adds the product" do
        post '/cart', params: { product_id: product1.id, quantity: 2 }, as: :json
        
        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response["id"]).to be_present
        expect(json_response["products"].size).to eq(1)
        expect(json_response["products"].first).to include(
          "id" => product1.id,
          "name" => "iPhone 15",
          "quantity" => 2,
          "unit_price" => "999.99",
          "total_price" => "1999.98"
        )
        expect(json_response["total_price"]).to eq("1999.98")
      end

      it "adds product to existing cart when session exists" do
        post '/cart', params: { product_id: product1.id, quantity: 1 }, as: :json
        cart_id = JSON.parse(response.body)["id"]

        post '/cart', params: { product_id: product2.id, quantity: 1 }, as: :json
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["id"]).to eq(cart_id)
        expect(json_response["products"].size).to eq(2)
        expect(json_response["total_price"]).to eq("1799.98")
      end

      it "increases quantity when adding same product" do
        post '/cart', params: { product_id: product1.id, quantity: 1 }, as: :json
        
        post '/cart', params: { product_id: product1.id, quantity: 2 }, as: :json
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["products"].size).to eq(1)
        expect(json_response["products"].first["quantity"]).to eq(3)
        expect(json_response["total_price"]).to eq("2999.97")
      end
    end
  end

  describe "GET /cart" do
    context "when cart exists" do
      it "returns current cart with products" do
        post '/cart', params: { product_id: product1.id, quantity: 2 }, as: :json
        post '/cart', params: { product_id: product2.id, quantity: 1 }, as: :json
        
        get '/cart', as: :json
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["products"].size).to eq(2)
        expect(json_response["total_price"]).to eq("2799.97")
      end
    end

    context "when cart doesn't exist" do
      it "returns empty cart" do
        get '/cart', as: :json
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response).to eq({
          "id" => nil,
          "products" => [],
          "total_price" => 0.0
        })
      end
    end
  end

  describe "POST /cart/add_item" do
    before do
      post '/cart', params: { product_id: product1.id, quantity: 1 }, as: :json
    end

    context "when updating existing product quantity" do
      it "adds the quantity to the existing product" do
        post '/cart/add_item', params: { product_id: product1.id, quantity: 5 }, as: :json
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["products"].first["quantity"]).to eq(6)
        expect(json_response["total_price"]).to eq("5999.94")
      end
    end

    context "when adding new product" do
      it "adds product to cart with specified quantity" do
        post '/cart/add_item', params: { product_id: product2.id, quantity: 2 }, as: :json
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["products"].size).to eq(2)
        
        product2_item = json_response["products"].find { |p| p["id"] == product2.id }
        expect(product2_item["quantity"]).to eq(2)
      end
    end

    context "with invalid parameters" do
      it "returns error when product doesn't exist" do
        post '/cart/add_item', params: { product_id: 99999, quantity: 1 }, as: :json
        
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)["error"]).to eq("Product not found")
      end

      it "returns error when quantity is zero" do
        post '/cart/add_item', params: { product_id: product1.id, quantity: 0 }, as: :json
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to eq("Quantity must be greater than 0")
      end
    end
  end

  describe "DELETE /cart/:product_id" do
    before do
      post '/cart', params: { product_id: product1.id, quantity: 2 }, as: :json
      post '/cart', params: { product_id: product2.id, quantity: 1 }, as: :json
    end

    context "when removing existing product" do
      it "removes the product from cart" do
        delete "/cart/#{product1.id}", as: :json
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["products"].size).to eq(1)
        expect(json_response["products"].first["id"]).to eq(product2.id)
        expect(json_response["total_price"]).to eq("799.99")
      end

      it "returns empty cart when removing last product" do
        delete "/cart/#{product1.id}", as: :json
        delete "/cart/#{product2.id}", as: :json
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["products"]).to be_empty
        expect(json_response["total_price"]).to eq("0.0")
      end
    end

    context "when product is not in cart" do
      it "returns product not found in cart error" do
        other_product = create(:product, name: "Other Product", price: 100.0)
        
        delete "/cart/#{other_product.id}", as: :json
        
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)["error"]).to eq("Product not found in cart")
      end
    end

    context "when product doesn't exist" do
      it "returns product not found error" do
        delete "/cart/99999", as: :json
        
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)["error"]).to eq("Product not found")
      end
    end

    context "when cart is empty" do
      it "returns cart empty error" do
        delete "/cart/#{product1.id}", as: :json
        delete "/cart/#{product2.id}", as: :json

        delete "/cart/#{product1.id}", as: :json
        
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)["error"]).to eq("Cart is empty")
      end
    end

  end

  describe "DELETE /cart/:product_id - No Cart Scenario" do
    context "when cart doesn't exist" do
      it "returns cart not found error" do
        delete "/cart/#{product1.id}", as: :json
        
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)["error"]).to eq("Cart not found")
      end
    end
  end
end
