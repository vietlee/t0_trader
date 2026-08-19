require "test_helper"

class UserPreferencesTest < ActiveSupport::TestCase
  test "mặc định dùng biểu phí chuẩn" do
    u = User.create!(email: "d@example.com", password: "password123")
    assert_equal 0.0015, u.fee_rates[:buy_fee_rate]
    assert_equal "claude-sonnet-5", u.ai_model
    assert u.ai_enabled?
  end

  test "mỗi user có biểu phí riêng, ảnh hưởng phí tự tính" do
    u1 = User.create!(email: "u1@example.com", password: "password123")
    u2 = User.create!(email: "u2@example.com", password: "password123")
    u1.update_preferences("buy_fee_rate" => 0.002)   # 0,2%
    u2.update_preferences("buy_fee_rate" => 0.001)   # 0,1%
    stock = Stock.create!(symbol: "AAA")

    t1 = u1.primary_account.trades.create!(stock: stock, side: :buy, quantity: 1000, price: 100_000, traded_at: Time.current, status: :pending)
    t2 = u2.primary_account.trades.create!(stock: stock, side: :buy, quantity: 1000, price: 100_000, traded_at: Time.current, status: :pending)

    assert_equal 200_000, t1.fee   # 100tr * 0,2%
    assert_equal 100_000, t2.fee   # 100tr * 0,1%
  end

  test "đổi model AI riêng cho từng user" do
    u = User.create!(email: "m@example.com", password: "password123")
    u.update_preferences("ai_model" => "claude-opus-5")
    assert_equal "claude-opus-5", u.ai_model
  end
end
