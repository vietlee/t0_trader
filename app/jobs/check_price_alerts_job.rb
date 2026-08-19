class CheckPriceAlertsJob < ApplicationJob
  queue_as :default

  def perform
    User.find_each do |user|
      next unless user.alert_enabled?

      threshold = user.alert_threshold_pct
      next if threshold <= 0

      account = user.primary_account
      next unless account

      calc = PortfolioCalculator.new(account)
      alerts = []

      calc.positions.each do |pos|
        next unless pos.market_price # cần giá thị trường

        pct = pos.unrealized_pct.to_f
        direction = if pct >= threshold then "profit"
                    elsif pct <= -threshold then "loss"
                    end
        next unless direction
        next if AlertLog.recently_alerted?(user, pos.stock, direction)

        alerts << {
          stock: pos.stock, direction: direction, pct: pct,
          unrealized: pos.unrealized, avg_cost: pos.avg_cost,
          price: pos.market_price, quantity: pos.quantity
        }
      end

      next if alerts.empty?

      AlertMailer.profit_alert(user, alerts).deliver_now
      alerts.each do |a|
        AlertLog.create!(user: user, stock: a[:stock], direction: a[:direction], pct: a[:pct])
      end
      Rails.logger.info("CheckPriceAlertsJob: gửi #{alerts.size} cảnh báo cho #{user.email}")
    rescue => e
      Rails.logger.error("CheckPriceAlertsJob lỗi cho user #{user.id}: #{e.class} #{e.message}")
    end
  end
end
