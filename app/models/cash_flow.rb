class CashFlow < ApplicationRecord
  belongs_to :account

  # deposit  = nạp tiền (vốn vào)
  # withdraw = rút tiền
  # dividend = cổ tức tiền mặt
  # interest = lãi tiền gửi
  # adjust   = điều chỉnh thủ công
  enum :kind, { deposit: 0, withdraw: 1, dividend: 2, interest: 3, adjust: 4 }, prefix: true

  validates :amount, numericality: { other_than: 0 }
  validates :occurred_on, presence: true

  scope :chronological, -> { order(:occurred_on, :id) }
  scope :recent, -> { order(occurred_on: :desc, id: :desc) }

  # Vốn ròng người dùng bơm vào (deposit - withdraw)
  CAPITAL_KINDS = %w[deposit withdraw].freeze

  # Ảnh hưởng lên số dư tiền mặt: nạp/cổ tức/lãi (+), rút (-), adjust theo dấu amount.
  def cash_delta
    case kind
    when "withdraw" then -amount.to_d.abs
    when "adjust"   then amount.to_d
    else amount.to_d.abs
    end
  end

  # Ảnh hưởng lên "vốn đã bơm": chỉ deposit/withdraw.
  def capital_delta
    case kind
    when "deposit"  then amount.to_d.abs
    when "withdraw" then -amount.to_d.abs
    else 0.to_d
    end
  end
end
