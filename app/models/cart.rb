class Cart < ApplicationRecord
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  ABANDONMENT_THRESHOLD = 3.hours
  REMOVAL_THRESHOLD = 7.days
  MINIMUM_TOTAL_PRICE = 0.0

  validates_numericality_of :total_price, greater_than_or_equal_to: 0

  before_save :update_interaction_time
  after_save :recalculate_total_price

  scope :inactive, -> { where('last_interaction_at <= ? AND abandoned_at IS NULL', ABANDONMENT_THRESHOLD.ago) }
  scope :old_abandoned, -> { where('abandoned_at IS NOT NULL AND abandoned_at <= ?', REMOVAL_THRESHOLD.ago) }

  def abandoned?
    abandoned_at.present?
  end

  def mark_as_abandoned
    update(abandoned_at: Time.current)
  end

  def remove_if_abandoned
    if should_be_removed?
      destroy
    end
  end

  def inactive?
    last_interaction_at.present? && last_interaction_at <= ABANDONMENT_THRESHOLD.ago
  end

  def should_be_removed?
    abandoned? && abandoned_at <= REMOVAL_THRESHOLD.ago
  end

  def recalculate_total!
    update_column(:total_price, calculate_total_price)
  end

  def empty?
    cart_items.empty?
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
    if new_record? || last_interaction_at.nil?
      self.last_interaction_at = Time.current
    end
  end
end
