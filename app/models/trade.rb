class Trade < ApplicationRecord
  belongs_to :account
  belongs_to :stock

  # buy  = mua vào, sell = bán ra
  enum :side, { buy: 0, sell: 1 }, prefix: true

  # draft     = nháp / dự kiến (không tính vào danh mục)
  # pending   = đã khớp, hàng đang về (chưa tới T+2)
  # settled   = hàng đã về (bán được)
  # closed    = vị thế đã đóng / đã bán
  # cancelled = huỷ (không tính vào danh mục)
  enum :status, { draft: 0, pending: 1, settled: 2, closed: 3, cancelled: 4 }, prefix: true

  EXECUTED_STATUSES = %w[pending settled closed].freeze

  validates :quantity, numericality: { greater_than: 0 }
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :traded_at, presence: true

  before_validation :set_defaults

  scope :executed,   -> { where(status: EXECUTED_STATUSES) }
  scope :chronological, -> { order(:traded_at, :id) }
  scope :recent,     -> { order(traded_at: :desc, id: :desc) }
  scope :in_period,  ->(from, to) { where(traded_at: from.beginning_of_day..to.end_of_day) }

  # Tổng giá trị khớp (chưa gồm phí/thuế)
  def gross_amount
    (quantity.to_i * price.to_d)
  end

  # Dòng tiền thực: mua ra tiền (âm), bán vào tiền (dương)
  def cash_delta
    if side_buy?
      -(gross_amount + fee.to_d)
    else
      gross_amount - fee.to_d - tax.to_d
    end
  end

  def total_cost
    fee.to_d + tax.to_d
  end

  # Cổ phiếu này đã "về" (settle) tính đến ngày cho trước chưa?
  def available_on?(date = Date.current)
    return false unless side_buy?
    return false if status_draft? || status_cancelled?
    settlement_date.present? && settlement_date <= date
  end

  private

  def set_defaults
    self.traded_at ||= Time.current
    if traded_at.present?
      self.settlement_date ||= TradingCalendar.settlement_date(traded_at.to_date)
    end
    auto_fill_costs
  end

  # Tự tính phí/thuế theo biểu phí VNDirect nếu người dùng chưa nhập.
  def auto_fill_costs
    return if quantity.to_i <= 0 || price.to_d <= 0

    rates = account&.user&.fee_rates || FeeCalculator::DEFAULT_RATES
    computed = FeeCalculator.for(side: side, quantity: quantity, price: price, rates: rates)
    self.fee = computed[:fee] if fee.blank? || fee.to_d.zero?
    self.tax = computed[:tax] if tax.blank? || tax.to_d.zero?
  end
end
