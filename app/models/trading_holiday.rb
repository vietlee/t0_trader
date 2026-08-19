class TradingHoliday < ApplicationRecord
  validates :holiday_on, presence: true, uniqueness: true

  scope :ordered, -> { order(:holiday_on) }

  def self.dates_set
    Rails.cache.fetch("trading_holiday_dates/#{maximum(:updated_at)&.to_i}", expires_in: 1.hour) do
      pluck(:holiday_on).to_set
    end
  end
end
