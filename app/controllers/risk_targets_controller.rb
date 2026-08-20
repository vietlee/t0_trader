class RiskTargetsController < ApplicationController
  # Đặt/cập nhật cắt lỗ + chốt lời cho một mã (find-or-create theo account+stock).
  def create
    stock = Stock.find(params[:stock_id])
    rt = current_account.risk_targets.find_or_initialize_by(stock: stock)
    rt.stop_loss = normalize(params[:stop_loss])
    rt.take_profit = normalize(params[:take_profit])

    if rt.blank_targets?
      rt.destroy if rt.persisted?
      redirect_back fallback_location: positions_path, notice: "Đã xoá kế hoạch SL/TP cho #{stock.symbol}."
    elsif rt.save
      redirect_back fallback_location: positions_path, notice: "Đã lưu SL/TP cho #{stock.symbol}."
    else
      redirect_back fallback_location: positions_path, alert: rt.errors.full_messages.to_sentence
    end
  end

  private

  def normalize(val)
    v = val.to_s.gsub(/\D/, "")
    v.presence&.to_i
  end
end
