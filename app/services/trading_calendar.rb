# Lịch giao dịch HOSE/HNX: bỏ Thứ 7, Chủ nhật và ngày nghỉ lễ (TradingHoliday).
# Dùng để tính ngày cổ phiếu "về" theo chu kỳ thanh toán T+2.
class TradingCalendar
  class << self
    # Ngày này có phải phiên giao dịch không?
    def trading_day?(date)
      date = date.to_date
      return false if date.saturday? || date.sunday?

      !holiday?(date)
    end

    def holiday?(date)
      TradingHoliday.dates_set.include?(date.to_date)
    end

    # Phiên giao dịch kế tiếp (không tính ngày đưa vào).
    def next_trading_day(date)
      d = date.to_date + 1
      d += 1 until trading_day?(d)
      d
    end

    # Cộng n phiên giao dịch kể từ date.
    def add_trading_days(date, n)
      d = date.to_date
      n.times { d = next_trading_day(d) }
      d
    end

    # Ngày cổ phiếu mua ngày `trade_date` về tài khoản (bán được).
    # VN: mua T, sáng T+2 hàng về → cộng 2 phiên giao dịch.
    def settlement_date(trade_date, t: 2)
      add_trading_days(trade_date, t)
    end

    # Số phiên giao dịch còn lại cho tới khi hàng về (0 nếu đã về).
    def sessions_until(settlement_date, from: Date.current)
      settlement_date = settlement_date.to_date
      from = from.to_date
      return 0 if settlement_date <= from

      count = 0
      d = from
      while d < settlement_date
        d = next_trading_day(d)
        count += 1
      end
      count
    end
  end
end
