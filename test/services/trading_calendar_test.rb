require "test_helper"

class TradingCalendarTest < ActiveSupport::TestCase
  setup do
    TradingHoliday.delete_all
  end

  test "cuối tuần không phải phiên giao dịch" do
    assert_not TradingCalendar.trading_day?(Date.new(2026, 8, 22)) # Thứ 7
    assert_not TradingCalendar.trading_day?(Date.new(2026, 8, 23)) # Chủ nhật
    assert TradingCalendar.trading_day?(Date.new(2026, 8, 21))     # Thứ 6
  end

  test "T+2 nhảy qua cuối tuần" do
    # Thứ 5 20/08/2026 -> +2 phiên: Thứ 6 21, Thứ 2 24 => 24/08
    assert_equal Date.new(2026, 8, 24), TradingCalendar.settlement_date(Date.new(2026, 8, 20))
  end

  test "T+2 nhảy qua ngày nghỉ lễ" do
    TradingHoliday.create!(holiday_on: Date.new(2026, 8, 21), name: "Nghỉ test")
    # Thứ 5 20/08 -> bỏ Thứ 6 21 (lễ) -> Thứ 2 24 (1), Thứ 3 25 (2) => 25/08
    assert_equal Date.new(2026, 8, 25), TradingCalendar.settlement_date(Date.new(2026, 8, 20))
  end

  test "sessions_until đếm số phiên còn lại" do
    assert_equal 0, TradingCalendar.sessions_until(Date.new(2026, 8, 20), from: Date.new(2026, 8, 20))
    assert_equal 2, TradingCalendar.sessions_until(Date.new(2026, 8, 24), from: Date.new(2026, 8, 20))
  end
end
