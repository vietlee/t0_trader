require "test_helper"

class TradingFlowsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(email: "flow@example.com", password: "password123")
    @account = @user.primary_account # tạo tự động sau khi user được tạo
    sign_in @user
  end

  test "tạo giao dịch mua với mã mới" do
    assert_difference -> { Trade.count } => 1, -> { Stock.count } => 1 do
      post trades_path, params: { trade: {
        symbol: "vic", side: "buy", quantity: 1000, price: 45_000,
        traded_at: Time.current.strftime("%Y-%m-%dT%H:%M"), status: "pending"
      } }
    end
    trade = Trade.last
    assert_equal "VIC", trade.stock.symbol
    assert trade.fee.positive?, "phí phải được tự tính"
    assert trade.settlement_date.present?, "ngày về T+2 phải được tính"
    assert_redirected_to trades_path
  end

  test "đổi trạng thái giao dịch" do
    stock = Stock.create!(symbol: "VIC")
    trade = @account.trades.create!(stock: stock, side: :buy, quantity: 100, price: 45_000, traded_at: Time.current, status: :pending)
    patch status_trade_path(trade), params: { value: "settled" }
    assert_equal "settled", trade.reload.status
  end

  test "ghi dòng tiền nạp vốn" do
    assert_difference -> { CashFlow.count }, 1 do
      post cash_flows_path, params: { cash_flow: { kind: "deposit", amount: 100_000_000, occurred_on: Date.current } }
    end
    assert_redirected_to cash_flows_path
  end

  test "cập nhật giá cổ phiếu" do
    stock = Stock.create!(symbol: "VIC")
    patch price_stock_path(stock), params: { current_price: 47_500 }
    assert_equal 47_500, stock.reload.current_price
    assert stock.price_updated_at.present?
  end

  test "đăng ký tài khoản mới tự tạo danh mục và vào được ngay" do
    sign_out @user
    assert_difference -> { User.count } => 1, -> { Account.count } => 1 do
      post user_registration_path, params: { user: {
        email: "newbie@example.com", password: "password123", password_confirmation: "password123"
      } }
    end
    assert_redirected_to root_path
    new_user = User.find_by(email: "newbie@example.com")
    assert new_user.primary_account.present?, "user mới phải có danh mục chính"
    follow_redirect!
    assert_response :success
  end

  test "dashboard, positions, reports render 200" do
    [root_path, positions_path, reports_path, trades_path, stocks_path, cash_flows_path,
     settings_path, ai_insights_path, ai_coach_path].each do |path|
      get path
      assert_response :success, "#{path} không trả 200"
    end
  end
end
