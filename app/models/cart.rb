class Cart < ApplicationRecord
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  validates_numericality_of :total_price, greater_than_or_equal_to: 0

  before_save :update_interaction_time
  after_save :recalculate_total_price

  def abandoned?
    abandoned_at.present?
  end

  def mark_as_abandoned
    update(abandoned_at: Time.current)
  end

  def remove_if_abandoned
    if abandoned? && abandoned_at <= 7.days.ago
      destroy
    end
  end

  def inactive?
    last_interaction_at.present? && last_interaction_at <= 3.hours.ago
  end

  def recalculate_total!
    update_column(:total_price, calculate_total_price)
  end

  private

  def calculate_total_price
    cart_items.reload.sum(&:total_price)
  end

  def recalculate_total_price
    new_total = calculate_total_price
    if total_price != new_total
      update_column(:total_price, new_total)
    end
  end

  def update_interaction_time
    self.last_interaction_at = Time.current
  end
end
