class RiskTarget < ApplicationRecord
  belongs_to :account
  belongs_to :stock

  validates :stock_id, uniqueness: { scope: :account_id }

  def stop_hit?(price)
    stop_loss.present? && price.present? && price.to_d <= stop_loss
  end

  def target_hit?(price)
    take_profit.present? && price.present? && price.to_d >= take_profit
  end

  def blank_targets?
    stop_loss.blank? && take_profit.blank?
  end
end
