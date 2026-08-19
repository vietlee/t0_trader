class TradesController < ApplicationController
  before_action :set_trade, only: [:edit, :update, :destroy, :status]

  def index
    @trades = current_account.trades.includes(:stock).recent
    @trades = @trades.where(side: params[:side]) if params[:side].present?
    @trades = @trades.where(status: params[:status]) if params[:status].present?
    if params[:q].present?
      @trades = @trades.joins(:stock).where("stocks.symbol ILIKE ?", "%#{params[:q].strip.upcase}%")
    end
    @trades = @trades.where("traded_at >= ?", params[:from].to_date.beginning_of_day) if params[:from].present?
    @trades = @trades.where("traded_at <= ?", params[:to].to_date.end_of_day) if params[:to].present?
    @trades = @trades.limit(300).to_a
  end

  def new
    @trade = current_account.trades.new(
      side: params[:side].presence || :buy,
      status: :pending,
      traded_at: Time.current,
      quantity: nil, price: nil
    )
    @trade.stock = Stock.find_by(id: params[:stock_id]) if params[:stock_id]
  end

  def create
    @trade = current_account.trades.new(trade_params)
    resolve_stock
    if @trade.stock && @trade.save
      redirect_to after_save_path, notice: "Đã ghi giao dịch #{@trade.stock.symbol}."
    else
      flash.now[:alert] = stock_error || "Không lưu được giao dịch."
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    @trade.assign_attributes(trade_params)
    resolve_stock
    if @trade.stock && @trade.save
      redirect_to trades_path, notice: "Đã cập nhật giao dịch."
    else
      flash.now[:alert] = stock_error || "Không cập nhật được."
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @trade.destroy
    redirect_to trades_path, notice: "Đã xoá giao dịch."
  end

  # Đổi nhanh trạng thái (Đang về / Đã về / Đã đóng / Huỷ)
  def status
    if Trade.statuses.key?(params[:value])
      @trade.update(status: params[:value])
      redirect_back fallback_location: trades_path, notice: "Đã đổi trạng thái #{@trade.stock.symbol} → #{helpers.status_badge(@trade).then { ApplicationHelper::STATUS_LABELS[@trade.status] }}."
    else
      redirect_back fallback_location: trades_path, alert: "Trạng thái không hợp lệ."
    end
  end

  private

  def set_trade
    @trade = current_account.trades.find(params[:id])
  end

  def trade_params
    params.require(:trade).permit(:side, :quantity, :price, :traded_at, :status,
                                  :strategy_tag, :note, :fee, :tax)
  end

  # Cho phép chọn mã có sẵn hoặc gõ mã mới (tự tạo Stock).
  def resolve_stock
    symbol = params.dig(:trade, :symbol).to_s.strip.upcase
    if symbol.present?
      @trade.stock = Stock.find_or_create_by(symbol: symbol)
    elsif params.dig(:trade, :stock_id).present?
      @trade.stock = Stock.find_by(id: params[:trade][:stock_id])
    end
  end

  def stock_error
    @trade.stock&.errors&.full_messages&.first
  end

  def after_save_path
    params[:continue].present? ? new_trade_path(side: @trade.side) : trades_path
  end
end
