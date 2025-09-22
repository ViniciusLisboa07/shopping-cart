require 'rails_helper'

RSpec.describe MarkCartAsAbandonedJob, type: :job do
  include ActiveSupport::Testing::TimeHelpers

  let!(:product) { create(:product, name: "Test Product", price: 100.0) }

  describe '#perform' do
    it 'marks inactive carts as abandoned and removes old abandoned carts' do
      active_cart = create(:cart)
      inactive_cart = create(:cart, :inactive)
      old_abandoned_cart = create(:cart, :old_abandoned)

      expect {
        described_class.new.perform
      }.to change { inactive_cart.reload.abandoned_at }.from(nil)
       .and change { Cart.exists?(old_abandoned_cart.id) }.from(true).to(false)

      expect(active_cart.reload.abandoned_at).to be_nil
      
      expect(inactive_cart.reload.abandoned?).to be true
    end
  end

  describe '#mark_inactive_carts_as_abandoned' do
    let(:job) { described_class.new }

    context 'when there are inactive carts' do
      let!(:active_cart) { create(:cart) }
      let!(:inactive_cart1) { create(:cart, :inactive) }
      let!(:inactive_cart2) { create(:cart, :inactive) }
      let!(:already_abandoned_cart) { create(:cart, :abandoned) }

      it 'marks only non-abandoned inactive carts as abandoned' do
        result = job.send(:mark_inactive_carts_as_abandoned)

        expect(result).to eq(2) # Only 2 carts should be marked

        expect(active_cart.reload.abandoned?).to be false
        
        # Inactive carts should be marked
        expect(inactive_cart1.reload.abandoned?).to be true
        expect(inactive_cart2.reload.abandoned?).to be true
        
        # Already abandoned cart should remain unchanged
        expect(already_abandoned_cart.reload.abandoned_at).to be_within(1.second).of(1.day.ago)
      end

      it 'logs the marking process' do
        expect(Rails.logger).to receive(:info).with(/Cart \d+ marked as abandoned/).twice
        expect(Rails.logger).to receive(:info).with("Marked 2 carts as abandoned")

        job.send(:mark_inactive_carts_as_abandoned)
      end
    end

    context 'when there are no inactive carts' do
      let!(:active_cart) { create(:cart) }

      it 'marks no carts as abandoned' do
        result = job.send(:mark_inactive_carts_as_abandoned)

        expect(result).to eq(0)
        expect(active_cart.reload.abandoned?).to be false
      end

      it 'logs zero marked carts' do
        expect(Rails.logger).to receive(:info).with("Marked 0 carts as abandoned")

        job.send(:mark_inactive_carts_as_abandoned)
      end
    end

    context 'with time boundaries' do
      it 'marks cart abandoned exactly at 3 hours boundary' do
        travel_to Time.current do
          boundary_cart = create(:cart)
          boundary_cart.update_column(:last_interaction_at, 3.hours.ago)
          
          result = job.send(:mark_inactive_carts_as_abandoned)
          
          expect(result).to eq(1)
          expect(boundary_cart.reload.abandoned?).to be true
        end
      end

      it 'does not mark cart just under 3 hours' do
        travel_to Time.current do
          recent_cart = create(:cart)
          recent_cart.update_column(:last_interaction_at, (2.hours + 59.minutes).ago)
          
          result = job.send(:mark_inactive_carts_as_abandoned)
          
          expect(result).to eq(0)
          expect(recent_cart.reload.abandoned?).to be false
        end
      end
    end
  end

  describe '#remove_old_abandoned_carts' do
    let(:job) { described_class.new }

    context 'when there are old abandoned carts' do
      let!(:recent_abandoned_cart) { 
        create(:cart, abandoned_at: 5.days.ago, last_interaction_at: 10.days.ago) 
      }
      let!(:old_abandoned_cart1) { 
        create(:cart, abandoned_at: 8.days.ago, last_interaction_at: 15.days.ago) 
      }
      let!(:old_abandoned_cart2) { 
        create(:cart, abandoned_at: 10.days.ago, last_interaction_at: 20.days.ago) 
      }
      let!(:active_cart) { create(:cart, last_interaction_at: 1.hour.ago) }

      it 'removes only old abandoned carts' do
        initial_count = Cart.count
        result = job.send(:remove_old_abandoned_carts)

        expect(result).to eq(2)
        expect(Cart.count).to eq(initial_count - 2)

        expect(Cart.exists?(recent_abandoned_cart.id)).to be true
        
        expect(Cart.exists?(active_cart.id)).to be true
        
        expect(Cart.exists?(old_abandoned_cart1.id)).to be false
        expect(Cart.exists?(old_abandoned_cart2.id)).to be false
      end

      it 'logs the removal process' do
        expect(Rails.logger).to receive(:info).with(/Removing abandoned cart \d+/).twice
        expect(Rails.logger).to receive(:info).with("Removed 2 old abandoned carts")

        job.send(:remove_old_abandoned_carts)
      end
    end

    context 'when there are no old abandoned carts' do
      let!(:recent_abandoned_cart) { 
        create(:cart, abandoned_at: 3.days.ago, last_interaction_at: 5.days.ago) 
      }

      it 'removes no carts' do
        initial_count = Cart.count
        result = job.send(:remove_old_abandoned_carts)

        expect(result).to eq(0)
        expect(Cart.count).to eq(initial_count)
        expect(Cart.exists?(recent_abandoned_cart.id)).to be true
      end

      it 'logs zero removed carts' do
        expect(Rails.logger).to receive(:info).with("Removed 0 old abandoned carts")

        job.send(:remove_old_abandoned_carts)
      end
    end

    context 'with time boundaries' do
      it 'removes cart abandoned exactly at 7 days boundary' do
        travel_to Time.current do
          boundary_cart = create(:cart, 
            abandoned_at: 7.days.ago, 
            last_interaction_at: 10.days.ago
          )
          
          result = job.send(:remove_old_abandoned_carts)
          
          expect(result).to eq(1)
          expect(Cart.exists?(boundary_cart.id)).to be false
        end
      end

      it 'does not remove cart just under 7 days' do
        travel_to Time.current do
          recent_cart = create(:cart, 
            abandoned_at: (6.days + 23.hours).ago, 
            last_interaction_at: 10.days.ago
          )
          
          result = job.send(:remove_old_abandoned_carts)
          
          expect(result).to eq(0)
          expect(Cart.exists?(recent_cart.id)).to be true
        end
      end
    end
  end

  describe 'integration scenarios' do
    let(:job) { described_class.new }

    it 'handles complete lifecycle of cart abandonment' do
      travel_to Time.parse("2023-01-01 12:00:00") do
        cart = create(:cart, last_interaction_at: Time.current)
        
        travel 4.hours
        
        job.perform
        cart.reload
        
        expect(cart.abandoned?).to be true
        expect(cart.abandoned_at).to be_within(1.second).of(Time.current)
        
        travel 8.days
        
        expect {
          job.perform
        }.to change { Cart.exists?(cart.id) }.from(true).to(false)
      end
    end

    it 'handles multiple carts in different states simultaneously' do
      travel_to Time.parse("2023-01-01 12:00:00") do
        active_cart = create(:cart)
        
        inactive_cart = create(:cart)
        inactive_cart.update_column(:last_interaction_at, 5.hours.ago)
        
        recent_abandoned_cart = create(:cart)
        recent_abandoned_cart.update_columns(
          last_interaction_at: 10.hours.ago,
          abandoned_at: 2.days.ago
        )
        
        old_abandoned_cart = create(:cart)
        old_abandoned_cart.update_columns(
          last_interaction_at: 20.days.ago,
          abandoned_at: 10.days.ago
        )

        initial_count = Cart.count
        
        result = job.perform
        
        expect(active_cart.reload.abandoned?).to be false
        expect(inactive_cart.reload.abandoned?).to be true
        expect(Cart.exists?(recent_abandoned_cart.id)).to be true
        expect(Cart.exists?(old_abandoned_cart.id)).to be false
        
        expect(Cart.count).to eq(initial_count - 1)
      end
    end
  end

  describe 'error handling' do
    let(:job) { described_class.new }

    it 'handles database errors gracefully' do
      cart1 = create(:cart, last_interaction_at: 4.hours.ago)
      
      expect(Rails.logger).to receive(:info).with(/Marked \d+ carts as abandoned/)
      
      expect {
        job.send(:mark_inactive_carts_as_abandoned)
      }.not_to raise_error
    end
  end
end
