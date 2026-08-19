class StocksController < ApplicationController
  before_action :set_stock, only: [:edit, :update, :destroy, :price]

  def index
    @stocks = Stock.ordered.to_a
    # Vị thế đang mở để hiển thị KL đang giữ
    @positions_by_stock = portfolio.positions.index_by { |p| p.stock&.id }
  end

  def new
    @stock = Stock.new(exchange: "HOSE")
  end

  def create
    @stock = Stock.new(stock_params)
    @stock.price_updated_at = Time.current if @stock.current_price.present?
    if @stock.save
      redirect_to stocks_path, notice: "Đã thêm mã #{@stock.symbol}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @stock.update(stock_params)
      redirect_to stocks_path, notice: "Đã cập nhật #{@stock.symbol}."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @stock.destroy
      redirect_to stocks_path, notice: "Đã xoá mã."
    else
      redirect_to stocks_path, alert: @stock.errors.full_messages.first
    end
  end

  # Cập nhật nhanh giá thị trường (inline).
  def price
    @stock.update_price!(params[:current_price])
    redirect_back fallback_location: stocks_path, notice: "Đã cập nhật giá #{@stock.symbol}."
  end

  # Tự lấy giá VN cho các mã đang nắm giữ (VNDirect).
  def refresh
    ids = PriceUpdater.held_stock_ids
    ids = Stock.pluck(:id) if ids.empty?
    result = PriceUpdater.run(Stock.where(id: ids))
    notice = "Đã cập nhật giá #{result.updated} mã từ VNDirect."
    notice += " Không lấy được: #{result.failed.join(', ')}." if result.failed.any?
    redirect_back fallback_location: stocks_path, notice: notice
  end

  private

  def set_stock
    @stock = Stock.find(params[:id])
  end

  def stock_params
    params.require(:stock).permit(:symbol, :name, :exchange, :sector, :current_price)
  end
end
