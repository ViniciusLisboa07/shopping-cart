require 'rails_helper'

RSpec.describe SessionManager, type: :service do
  let(:session_manager) { described_class.new }
  let(:session) { {} }
  let(:cart_id) { 123 }

  describe '#get_cart_id' do
    context 'when cart_id exists in session' do
      it 'returns the cart_id' do
        session[:cart_id] = cart_id
        
        result = session_manager.get_cart_id(session)
        
        expect(result).to eq(cart_id)
      end
    end

    context 'when cart_id does not exist in session' do
      it 'returns nil' do
        result = session_manager.get_cart_id(session)
        
        expect(result).to be_nil
      end
    end

    context 'when session is empty' do
      it 'returns nil' do
        result = session_manager.get_cart_id({})
        
        expect(result).to be_nil
      end
    end
  end

  describe '#set_cart_id' do
    it 'sets cart_id in session' do
      session_manager.set_cart_id(session, cart_id)
      
      expect(session[:cart_id]).to eq(cart_id)
    end

    it 'overwrites existing cart_id' do
      session[:cart_id] = 456
      
      session_manager.set_cart_id(session, cart_id)
      
      expect(session[:cart_id]).to eq(cart_id)
    end

    it 'accepts string cart_id' do
      string_cart_id = "789"
      
      session_manager.set_cart_id(session, string_cart_id)
      
      expect(session[:cart_id]).to eq(string_cart_id)
    end

    it 'accepts nil cart_id' do
      session[:cart_id] = cart_id
      
      session_manager.set_cart_id(session, nil)
      
      expect(session[:cart_id]).to be_nil
    end
  end

  describe '#clear_cart_id' do
    context 'when cart_id exists in session' do
      it 'removes cart_id from session' do
        session[:cart_id] = cart_id
        
        session_manager.clear_cart_id(session)
        
        expect(session[:cart_id]).to be_nil
        expect(session.key?(:cart_id)).to be false
      end
    end

    context 'when cart_id does not exist in session' do
      it 'does not raise error' do
        expect {
          session_manager.clear_cart_id(session)
        }.not_to raise_error
      end

      it 'leaves session unchanged' do
        session[:other_key] = "value"
        
        session_manager.clear_cart_id(session)
        
        expect(session[:other_key]).to eq("value")
        expect(session.key?(:cart_id)).to be false
      end
    end
  end

  describe 'CART_ID_KEY constant' do
    it 'is defined as :cart_id' do
      expect(SessionManager::CART_ID_KEY).to eq(:cart_id)
    end
  end

  describe 'integration scenarios' do
    it 'handles complete session lifecycle' do
      # Initially no cart_id
      expect(session_manager.get_cart_id(session)).to be_nil
      
      # Set cart_id
      session_manager.set_cart_id(session, cart_id)
      expect(session_manager.get_cart_id(session)).to eq(cart_id)
      
      # Update cart_id
      new_cart_id = 999
      session_manager.set_cart_id(session, new_cart_id)
      expect(session_manager.get_cart_id(session)).to eq(new_cart_id)
      
      # Clear cart_id
      session_manager.clear_cart_id(session)
      expect(session_manager.get_cart_id(session)).to be_nil
    end

    it 'maintains session isolation between different sessions' do
      session1 = {}
      session2 = {}
      
      session_manager.set_cart_id(session1, 111)
      session_manager.set_cart_id(session2, 222)
      
      expect(session_manager.get_cart_id(session1)).to eq(111)
      expect(session_manager.get_cart_id(session2)).to eq(222)
      
      session_manager.clear_cart_id(session1)
      
      expect(session_manager.get_cart_id(session1)).to be_nil
      expect(session_manager.get_cart_id(session2)).to eq(222)
    end
  end
end
