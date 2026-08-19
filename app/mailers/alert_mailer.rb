class AlertMailer < ApplicationMailer
  default from: ENV.fetch("MAIL_FROM", "T0 Trader <noreply@stock.czin.net>")

  # alerts: mảng hash { stock:, direction:, pct:, unrealized:, avg_cost:, price:, quantity: }
  def profit_alert(user, alerts)
    @user = user
    @alerts = alerts
    @threshold = user.alert_threshold_pct
    subject = if alerts.size == 1
      a = alerts.first
      "#{a[:direction] == 'profit' ? '📈' : '📉'} #{a[:stock].symbol} #{format('%+.2f', a[:pct])}% — T0 Trader"
    else
      "🔔 #{alerts.size} mã vượt ngưỡng #{@threshold.to_i}% — T0 Trader"
    end
    mail(to: user.email, subject: subject)
  end
end
