class CheckPriceAlertsJob < ApplicationJob
  queue_as :default

  def perform
    User.find_each do |user|
      next unless user.alert_enabled?

      account = user.primary_account
      next unless account

      calc = PortfolioCalculator.new(account)
      check_threshold(user, calc)
      check_sl_tp(user, account, calc)
      check_watchlist(user, account)
    rescue => e
      Rails.logger.error("CheckPriceAlertsJob lỗi user #{user.id}: #{e.class} #{e.message}")
    end
  end

  private

  # 1. Lời/lỗ vượt ngưỡng %
  def check_threshold(user, calc)
    threshold = user.alert_threshold_pct
    return if threshold <= 0

    alerts = []
    calc.positions.each do |pos|
      next unless pos.market_price

      pct = pos.unrealized_pct.to_f
      direction = if pct >= threshold then "profit"
                  elsif pct <= -threshold then "loss"
                  end
      next unless direction
      next if AlertLog.recently_alerted?(user, pos.stock, direction)

      alerts << { stock: pos.stock, direction: direction, pct: pct, unrealized: pos.unrealized,
                  avg_cost: pos.avg_cost, price: pos.market_price, quantity: pos.quantity }
    end
    return if alerts.empty?

    AlertMailer.profit_alert(user, alerts).deliver_now
    alerts.each { |a| AlertLog.create!(user: user, stock: a[:stock], direction: a[:direction], pct: a[:pct]) }
  end

  # 2. Chạm cắt lỗ / chốt lời
  def check_sl_tp(user, account, calc)
    positions = calc.positions.index_by { |p| p.stock&.id }
    items = []
    logs = []
    account.risk_targets.includes(:stock).each do |rt|
      pos = positions[rt.stock_id]
      next unless pos&.market_price

      price = pos.market_price
      if rt.stop_hit?(price) && !AlertLog.recently_alerted?(user, rt.stock, "stop")
        items << { symbol: rt.stock.symbol, name: rt.stock.name,
                   line: "Giá #{fmt price} đã chạm/hụt mức CẮT LỖ #{fmt rt.stop_loss}. Cân nhắc thoát vị thế theo kế hoạch.", color: "#fda4b4" }
        logs << [rt.stock, "stop"]
      elsif rt.target_hit?(price) && !AlertLog.recently_alerted?(user, rt.stock, "target")
        items << { symbol: rt.stock.symbol, name: rt.stock.name,
                   line: "Giá #{fmt price} đã đạt mức CHỐT LỜI #{fmt rt.take_profit}. Cân nhắc chốt lời.", color: "#6ee7b7" }
        logs << [rt.stock, "target"]
      end
    end
    return if items.empty?

    AlertMailer.notify(user, "SL/TP chạm mức — T0 Trader", "Cảnh báo cắt lỗ / chốt lời", items).deliver_now
    logs.each { |stock, dir| AlertLog.create!(user: user, stock: stock, direction: dir) }
  end

  # 3. Watchlist về vùng mua
  def check_watchlist(user, account)
    items = []
    logs = []
    account.watchlist_items.includes(:stock).each do |wi|
      price = wi.stock.current_price
      next unless price && wi.target_buy_price
      next unless wi.target_hit?(price)
      next if AlertLog.recently_alerted?(user, wi.stock, "watch")

      items << { symbol: wi.stock.symbol, name: wi.stock.name,
                 line: "Giá #{fmt price} đã về vùng mua bạn đặt (#{fmt wi.target_buy_price}).", color: "#6ee7b7" }
      logs << wi.stock
    end
    return if items.empty?

    AlertMailer.notify(user, "#{items.size} mã về vùng mua — T0 Trader", "Mã trong watchlist về vùng mua", items).deliver_now
    logs.each { |stock| AlertLog.create!(user: user, stock: stock, direction: "watch") }
  end

  def fmt(n)
    ActiveSupport::NumberHelper.number_to_delimited(n.to_i, delimiter: ".") + "đ"
  end
end
