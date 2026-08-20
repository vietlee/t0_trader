class SettingsController < ApplicationController
  def show
    @holidays = TradingHoliday.ordered.where("holiday_on >= ?", Date.current.beginning_of_year).to_a
    @ai_configured = Anthropic::Client.configured?
  end

  def update
    current_user.update_preferences(
      "buy_fee_rate"        => percent_to_rate(params[:buy_fee_pct]),
      "sell_fee_rate"       => percent_to_rate(params[:sell_fee_pct]),
      "sell_tax_rate"       => percent_to_rate(params[:sell_tax_pct]),
      "ai_model"            => params[:ai_model].presence || User::SETTING_DEFAULTS["ai_model"],
      "ai_enabled"          => params[:ai_enabled] == "1",
      "alert_enabled"       => params[:alert_enabled] == "1",
      "alert_threshold_pct" => params[:alert_threshold_pct].to_f,
      "risk_per_trade_pct"  => params[:risk_per_trade_pct].to_f,
      "max_position_pct"    => params[:max_position_pct].to_f,
      "max_daily_trades"    => params[:max_daily_trades].to_i
    )
    redirect_to settings_path, notice: "Đã lưu cài đặt."
  end

  private

  def percent_to_rate(pct)
    (pct.to_f / 100.0).round(6)
  end
end
