class AlertMailer < ApplicationMailer
  default from: ENV.fetch("MAIL_FROM", "T0 Trader <noreply@stock.czin.net>")

  # alerts: mảng hash { stock:, direction:, pct:, unrealized:, avg_cost:, price:, quantity: }
  def profit_alert(user, alerts)
    @user = user
    @alerts = alerts
    @threshold = user.alert_threshold_pct
    subject = if alerts.size == 1
      a = alerts.first
      "#{a[:stock].symbol} #{format('%+.2f', a[:pct])}% so với giá vốn — T0 Trader"
    else
      "#{alerts.size} mã vượt ngưỡng #{@threshold.to_i}% giá vốn — T0 Trader"
    end
    # Tín hiệu transactional để Gmail ưu tiên Primary (không phải Promotions).
    headers["X-Entity-Ref-ID"] = "t0trader-alert-#{Time.current.to_i}"
    headers["Auto-Submitted"] = "auto-generated"
    mail(to: user.email, subject: subject)
  end
end
