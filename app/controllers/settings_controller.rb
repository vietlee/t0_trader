class SettingsController < ApplicationController
  def show
    @holidays = TradingHoliday.ordered.where("holiday_on >= ?", Date.current.beginning_of_year).to_a
    @ai_configured = Anthropic::Client.configured?
  end

  def update
    Setting["buy_fee_rate"]  = percent_to_rate(params[:buy_fee_pct])
    Setting["sell_fee_rate"] = percent_to_rate(params[:sell_fee_pct])
    Setting["sell_tax_rate"] = percent_to_rate(params[:sell_tax_pct])
    Setting["ai_model"]      = params[:ai_model].presence || Setting::DEFAULTS["ai_model"]
    Setting["ai_enabled"]    = params[:ai_enabled] == "1"
    redirect_to settings_path, notice: "Đã lưu cài đặt."
  end

  private

  def percent_to_rate(pct)
    (pct.to_f / 100.0).round(6)
  end
end
