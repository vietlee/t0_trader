require "test_helper"

class AlertMailerTest < ActionMailer::TestCase
  test "profit_alert gửi tới đúng user với nội dung mã" do
    user = User.create!(email: "alert@example.com", password: "password123")
    stock = Stock.create!(symbol: "BSR", name: "Lọc hoá dầu Bình Sơn", current_price: 27_000)
    alerts = [{ stock: stock, direction: "profit", pct: 6.5, unrealized: 5_000_000,
                avg_cost: 25_000, price: 27_000, quantity: 5000 }]
    mail = AlertMailer.profit_alert(user, alerts)
    assert_equal ["alert@example.com"], mail.to
    assert_match "BSR", mail.subject
    assert_match "BSR", mail.body.encoded
  end
end
