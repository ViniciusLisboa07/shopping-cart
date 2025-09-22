require 'rails_helper'

RSpec.describe Result, type: :service do
  let(:success_data) { { message: "Success" } }
  let(:error_data) { StandardError.new("Something went wrong") }

  describe '.success' do
    context 'with data' do
      let(:result) { Result.success(success_data) }

      it 'creates a successful result' do
        expect(result.success?).to be true
        expect(result.failure?).to be false
      end

      it 'stores the data' do
        expect(result.data).to eq(success_data)
      end

      it 'raises error when accessing error' do
        expect { result.error }.to raise_error(RuntimeError, "Cannot access error on success result")
      end
    end

    context 'with nil data' do
      let(:result) { Result.success(nil) }

      it 'creates a successful result' do
        expect(result.success?).to be true
        expect(result.failure?).to be false
      end

      it 'stores nil as data' do
        expect(result.data).to be_nil
      end
    end

    context 'without parameters' do
      let(:result) { Result.success }

      it 'creates a successful result' do
        expect(result.success?).to be true
        expect(result.failure?).to be false
      end

      it 'has nil data' do
        expect(result.data).to be_nil
      end
    end
  end

  describe '.failure' do
    context 'with error object' do
      let(:result) { Result.failure(error_data) }

      it 'creates a failed result' do
        expect(result.success?).to be false
        expect(result.failure?).to be true
      end

      it 'stores the error' do
        expect(result.error).to eq(error_data)
      end

      it 'raises error when accessing data' do
        expect { result.data }.to raise_error(RuntimeError, "Cannot access data on failure result")
      end
    end

    context 'with string error' do
      let(:error_string) { "Error message" }
      let(:result) { Result.failure(error_string) }

      it 'creates a failed result' do
        expect(result.success?).to be false
        expect(result.failure?).to be true
      end

      it 'stores the error' do
        expect(result.error).to eq(error_string)
      end
    end

    context 'with custom exception' do
      let(:custom_error) { CartService::ProductNotFoundError.new("Product not found") }
      let(:result) { Result.failure(custom_error) }

      it 'creates a failed result' do
        expect(result.success?).to be false
        expect(result.failure?).to be true
      end

      it 'stores the custom error' do
        expect(result.error).to eq(custom_error)
        expect(result.error.message).to eq("Product not found")
      end
    end
  end

  describe 'instance methods' do
    describe '#success?' do
      it 'returns true for successful result' do
        result = Result.success(success_data)
        expect(result.success?).to be true
      end

      it 'returns false for failed result' do
        result = Result.failure(error_data)
        expect(result.success?).to be false
      end
    end

    describe '#failure?' do
      it 'returns false for successful result' do
        result = Result.success(success_data)
        expect(result.failure?).to be false
      end

      it 'returns true for failed result' do
        result = Result.failure(error_data)
        expect(result.failure?).to be true
      end
    end

    describe '#data' do
      it 'returns data for successful result' do
        result = Result.success(success_data)
        expect(result.data).to eq(success_data)
      end

      it 'raises error for failed result' do
        result = Result.failure(error_data)
        expect { result.data }.to raise_error(RuntimeError, "Cannot access data on failure result")
      end
    end

    describe '#error' do
      it 'raises error for successful result' do
        result = Result.success(success_data)
        expect { result.error }.to raise_error(RuntimeError, "Cannot access error on success result")
      end

      it 'returns error for failed result' do
        result = Result.failure(error_data)
        expect(result.error).to eq(error_data)
      end
    end
  end

  describe 'encapsulation' do
    it 'does not expose internal state setters' do
      result = Result.success(success_data)
      
      expect(result).not_to respond_to(:success=)
      expect(result).not_to respond_to(:data=)
      expect(result).not_to respond_to(:error=)
    end
  end

  describe 'edge cases' do
    it 'handles complex data structures' do
      complex_data = {
        cart: { id: 1, items: [{ product_id: 1, quantity: 2 }] },
        metadata: { created_at: Time.current }
      }
      
      result = Result.success(complex_data)
      
      expect(result.success?).to be true
      expect(result.data).to eq(complex_data)
      expect(result.data[:cart][:items].first[:quantity]).to eq(2)
    end

    it 'handles ActiveRecord objects' do
      product = create(:product)
      result = Result.success(product)
      
      expect(result.success?).to be true
      expect(result.data).to eq(product)
      expect(result.data.id).to eq(product.id)
    end

    it 'handles different error types' do
      standard_error = StandardError.new("Standard error")
      argument_error = ArgumentError.new("Argument error")
      custom_error = CartService::InvalidQuantityError.new("Quantity error")
      
      result1 = Result.failure(standard_error)
      result2 = Result.failure(argument_error)
      result3 = Result.failure(custom_error)
      
      expect(result1.error).to be_a(StandardError)
      expect(result2.error).to be_a(ArgumentError)
      expect(result3.error).to be_a(CartService::InvalidQuantityError)
    end
  end

  describe 'usage patterns' do
    it 'works with conditional logic' do
      success_result = Result.success("OK")
      failure_result = Result.failure("Error")
      
      success_message = if success_result.success?
                         success_result.data
                       else
                         "Failed"
                       end
                       
      failure_message = if failure_result.success?
                         failure_result.data
                       else
                         "Failed"
                       end
      
      expect(success_message).to eq("OK")
      expect(failure_message).to eq("Failed")
    end

    it 'works with case statements' do
      result = Result.failure(CartService::ProductNotFoundError.new("Not found"))
      
      message = case result.error
               when CartService::ProductNotFoundError
                 "Product not found"
               when CartService::InvalidQuantityError
                 "Invalid quantity"
               else
                 "Unknown error"
               end
      
      expect(message).to eq("Product not found")
    end

    it 'chains well with service operations' do
      step1 = Result.success({ step: 1 })
      
      step2 = if step1.success?
               Result.success({ step: 2, previous: step1.data })
             else
               Result.failure("Step 1 failed")
             end
      
      step3 = if step2.success?
               Result.success({ step: 3, previous: step2.data })
             else
               Result.failure("Step 2 failed")
             end
      
      expect(step3.success?).to be true
      expect(step3.data[:step]).to eq(3)
      expect(step3.data[:previous][:step]).to eq(2)
    end
  end
end
