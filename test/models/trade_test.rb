require "test_helper"

class TradeTest < ActiveSupport::TestCase
  setup do
    TradingHoliday.delete_all
    @user = User.create!(email: "tr@example.com", password: "password123")
    @account = @user.primary_account
    @stock = Stock.create!(symbol: "BSR")
  end

  def build_trade(date)
    @account.trades.create!(stock: @stock, side: :buy, quantity: 100, price: 26_000,
                            traded_at: date.to_time.change(hour: 10), status: :pending)
  end

  test "settlement date tính lại khi sửa ngày mua về quá khứ" do
    t = build_trade(Date.new(2026, 8, 20)) # Thứ 5
    assert_equal Date.new(2026, 8, 24), t.settlement_date # T+2

    # Sửa ngày mua về xa quá khứ -> ngày về phải cập nhật (đã qua)
    t.update!(traded_at: Date.new(2026, 7, 1).to_time.change(hour: 10))
    assert_equal TradingCalendar.settlement_date(Date.new(2026, 7, 1)), t.reload.settlement_date
    assert t.available_on?(Date.current), "hàng mua 1/7 phải đã về tính đến hôm nay"
  end
end
