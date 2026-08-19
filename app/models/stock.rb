class Stock < ApplicationRecord
  has_many :trades, dependent: :restrict_with_error

  EXCHANGES = %w[HOSE HNX UPCOM].freeze

  validates :symbol, presence: true, uniqueness: { case_sensitive: false }
  validates :exchange, inclusion: { in: EXCHANGES }, allow_blank: true

  before_validation :normalize_symbol

  scope :ordered, -> { order(:symbol) }

  def update_price!(new_price)
    update!(current_price: new_price, price_updated_at: Time.current)
  end

  def to_s
    symbol
  end

  private

  def normalize_symbol
    self.symbol = symbol.to_s.strip.upcase.presence
  end
end
