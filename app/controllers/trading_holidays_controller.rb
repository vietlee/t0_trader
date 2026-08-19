class TradingHolidaysController < ApplicationController
  def create
    if params[:holiday_on].present?
      TradingHoliday.find_or_create_by(holiday_on: params[:holiday_on]) { |h| h.name = params[:name] }
      redirect_to settings_path, notice: "Đã thêm ngày nghỉ."
    else
      redirect_to settings_path, alert: "Chọn ngày nghỉ."
    end
  end

  def destroy
    TradingHoliday.find(params[:id]).destroy
    redirect_to settings_path, notice: "Đã xoá ngày nghỉ."
  end
end
