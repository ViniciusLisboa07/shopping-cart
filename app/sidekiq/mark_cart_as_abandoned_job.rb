class MarkCartAsAbandonedJob
  include Sidekiq::Job

  def perform
    mark_inactive_carts_as_abandoned
    remove_old_abandoned_carts
  end

  private

  def mark_inactive_carts_as_abandoned
    inactive_carts = Cart.inactive

    marked_count = 0
    inactive_carts.find_each do |cart|
      cart.mark_as_abandoned
      marked_count += 1
      Rails.logger.info "Cart #{cart.id} marked as abandoned"
    end

    Rails.logger.info "Marked #{marked_count} carts as abandoned"
    marked_count
  end

  def remove_old_abandoned_carts
    old_abandoned_carts = Cart.old_abandoned

    removed_count = 0
    old_abandoned_carts.find_each do |cart|
      Rails.logger.info "Removing abandoned cart #{cart.id}"
      cart.destroy!
      removed_count += 1
    end

    Rails.logger.info "Removed #{removed_count} old abandoned carts"
    removed_count
  end
end
