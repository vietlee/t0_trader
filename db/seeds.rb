# Idempotent seeds. Chạy được nhiều lần.

# ---- Ngày nghỉ giao dịch HOSE 2026 (chỉnh lại trong Settings nếu sai) -------
holidays_2026 = {
  "2026-01-01" => "Tết Dương lịch",
  "2026-02-16" => "Nghỉ Tết Nguyên đán",
  "2026-02-17" => "Tết Nguyên đán (mùng 1)",
  "2026-02-18" => "Tết Nguyên đán (mùng 2)",
  "2026-02-19" => "Tết Nguyên đán (mùng 3)",
  "2026-02-20" => "Nghỉ Tết Nguyên đán",
  "2026-04-27" => "Giỗ Tổ Hùng Vương",
  "2026-04-30" => "Giải phóng miền Nam",
  "2026-05-01" => "Quốc tế Lao động",
  "2026-09-02" => "Quốc khánh"
}
holidays_2026.each do |date, name|
  TradingHoliday.find_or_create_by!(holiday_on: Date.parse(date)) { |h| h.name = name }
end
puts "Ngày nghỉ giao dịch: #{TradingHoliday.count}"

# ---- Người dùng + danh mục -------------------------------------------------
email = ENV.fetch("SEED_EMAIL", "quocvietlee@gmail.com")
password = ENV.fetch("SEED_PASSWORD", "t0trader@2026")
user = User.find_or_initialize_by(email: email)
if user.new_record?
  user.password = password
  user.password_confirmation = password
  user.save!
  puts "Tạo user #{email} (mật khẩu mặc định: #{password} — đổi ngay sau khi đăng nhập)"
else
  puts "User #{email} đã tồn tại"
end

account = user.accounts.first_or_create!(name: "Danh mục chính", broker: "VNDirect")

# ---- Cấu hình mặc định -----------------------------------------------------
Setting.reset_cache!

# ---- Dữ liệu mẫu (chỉ khi SEED_SAMPLE=1 hoặc môi trường development) --------
if ENV["SEED_SAMPLE"] == "1" || (Rails.env.development? && account.trades.none?)
  puts "Nạp dữ liệu mẫu..."

  stocks = {
    "FPT" => { name: "FPT Corp", exchange: "HOSE", sector: "Công nghệ", price: 138_000 },
    "HPG" => { name: "Hoà Phát", exchange: "HOSE", sector: "Thép", price: 27_500 },
    "MWG" => { name: "Thế Giới Di Động", exchange: "HOSE", sector: "Bán lẻ", price: 62_800 },
    "SSI" => { name: "Chứng khoán SSI", exchange: "HOSE", sector: "Chứng khoán", price: 33_400 },
    "VND" => { name: "VNDirect", exchange: "HOSE", sector: "Chứng khoán", price: 18_900 }
  }
  stock_records = stocks.map do |sym, attrs|
    s = Stock.find_or_create_by!(symbol: sym) do |st|
      st.name = attrs[:name]; st.exchange = attrs[:exchange]; st.sector = attrs[:sector]
    end
    s.update!(current_price: attrs[:price], price_updated_at: Time.current)
    [sym, s]
  end.to_h

  account.cash_flows.create!(kind: :deposit, amount: 500_000_000, occurred_on: Date.current - 90, note: "Nạp vốn ban đầu")

  def make_trade(account, stock, side, qty, price, days_ago, status:, tag: nil)
    traded = (Date.current - days_ago).to_time.change(hour: 10)
    account.trades.create!(
      stock: stock, side: side, quantity: qty, price: price,
      traded_at: traded, status: status, strategy_tag: tag
    )
  end

  s = stock_records
  # Vị thế đã đóng (có lời/lỗ)
  make_trade(account, s["FPT"], :buy, 1000, 120_000, 60, status: :closed, tag: "Swing")
  make_trade(account, s["FPT"], :sell, 1000, 135_000, 40, status: :closed, tag: "Swing")
  make_trade(account, s["HPG"], :buy, 3000, 29_000, 50, status: :closed, tag: "T+0")
  make_trade(account, s["HPG"], :sell, 3000, 27_800, 45, status: :closed, tag: "T+0")
  make_trade(account, s["SSI"], :buy, 2000, 30_000, 35, status: :closed, tag: "Swing")
  make_trade(account, s["SSI"], :sell, 2000, 34_500, 20, status: :closed, tag: "Swing")

  # Vị thế đang mở — hàng đã về (settled)
  make_trade(account, s["MWG"], :buy, 1500, 58_000, 15, status: :settled, tag: "Đầu tư")
  make_trade(account, s["FPT"], :buy, 500, 130_000, 10, status: :settled, tag: "Swing")
  # Vị thế đang mở — hàng chưa về (T+ pending)
  make_trade(account, s["VND"], :buy, 5000, 18_500, 1, status: :pending, tag: "T+0")
  make_trade(account, s["HPG"], :buy, 2000, 27_200, 0, status: :pending, tag: "T+0")

  puts "Đã tạo #{account.trades.count} giao dịch mẫu, #{Stock.count} mã."
end

puts "Seed xong."
