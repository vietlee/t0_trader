class WatchlistItem < ApplicationRecord
  belongs_to :account
  belongs_to :stock

  validates :stock_id, uniqueness: { scope: :account_id }

  scope :ordered, -> { joins(:stock).order("stocks.symbol") }

  # Giá đã về vùng mua mong muốn chưa?
  def target_hit?(price)
    target_buy_price.present? && price.present? && price.to_d <= target_buy_price
  end
end
