require "test_helper"

class PortfolioCalculatorTest < ActiveSupport::TestCase
  setup do
    TradingHoliday.delete_all
    @user = User.create!(email: "t@example.com", password: "password123")
    # Tắt phí để kiểm tra phần lõi math
    @user.update_preferences("buy_fee_rate" => 0, "sell_fee_rate" => 0, "sell_tax_rate" => 0)
    @account = @user.accounts.create!(name: "Test")
    @fpt = Stock.create!(symbol: "FPT", current_price: 130_000)
    @account.cash_flows.create!(kind: :deposit, amount: 500_000_000, occurred_on: Date.current - 30)
  end

  def buy(qty, price, days_ago, status: :settled)
    @account.trades.create!(stock: @fpt, side: :buy, quantity: qty, price: price,
                            traded_at: (Date.current - days_ago).to_time.change(hour: 10), status: status)
  end

  def sell(qty, price, days_ago, status: :closed)
    @account.trades.create!(stock: @fpt, side: :sell, quantity: qty, price: price,
                            traded_at: (Date.current - days_ago).to_time.change(hour: 10), status: status)
  end

  test "realized P&L FIFO" do
    buy(1000, 100_000, 20)
    sell(1000, 110_000, 10)
    calc = PortfolioCalculator.new(@account)
    assert_equal 10_000_000, calc.realized_total   # (110k-100k)*1000
    assert_empty calc.positions
  end

  test "FIFO khớp đúng lô mua trước" do
    buy(1000, 100_000, 30)
    buy(1000, 120_000, 20)
    sell(1000, 130_000, 10)   # khớp lô 100k trước => lời 30k*1000
    calc = PortfolioCalculator.new(@account)
    assert_equal 30_000_000, calc.realized_total
    assert_equal 1, calc.positions.size
    assert_equal 1000, calc.positions.first.quantity
    assert_equal 120_000, calc.positions.first.avg_cost.to_i   # còn lô 120k
  end

  test "unrealized theo giá hiện tại" do
    buy(1000, 100_000, 10)     # giá hiện tại 130k
    calc = PortfolioCalculator.new(@account)
    assert_equal 30_000_000, calc.unrealized_total
  end

  test "T+0: hàng đã về bán được, hàng mới mua đang chờ" do
    buy(1000, 100_000, 10)          # đã về (settlement quá khứ)
    buy(500, 100_000, 0, status: :pending)  # mua hôm nay -> chưa về
    calc = PortfolioCalculator.new(@account)
    pos = calc.positions.first
    assert_equal 1500, pos.quantity
    assert_equal 1000, pos.available_qty
    assert_equal 500, pos.pending_qty
  end

  test "tiền mặt và NAV" do
    buy(1000, 100_000, 10)   # chi 100tr
    calc = PortfolioCalculator.new(@account)
    assert_equal 500_000_000, calc.capital_in
    assert_equal 400_000_000, calc.cash          # 500tr - 100tr
    assert_equal 130_000_000, calc.market_value  # 1000 * 130k
    assert_equal 530_000_000, calc.nav
  end

  test "thống kê win rate" do
    buy(1000, 100_000, 30); sell(1000, 110_000, 20)  # win
    buy(1000, 100_000, 15); sell(1000, 90_000, 10)   # loss
    calc = PortfolioCalculator.new(@account)
    stats = calc.stats
    assert_equal 2, stats[:closed_count]
    assert_equal 50.0, stats[:win_rate]
  end
end
