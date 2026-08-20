class WatchlistItemsController < ApplicationController
  def index
    @items = current_account.watchlist_items.ordered.includes(:stock).to_a
  end

  def create
    symbol = params[:symbol].to_s.strip.upcase
    return redirect_to(watchlist_items_path, alert: "Nhập mã cổ phiếu.") if symbol.blank?

    stock = Stock.find_or_create_by(symbol: symbol)
    item = current_account.watchlist_items.find_or_initialize_by(stock: stock)
    item.target_buy_price = params[:target_buy_price].to_s.gsub(/\D/, "").presence&.to_i
    item.note = params[:note]
    item.save
    # lấy giá ngay cho mã mới thêm
    FetchStockPricesJob.perform_later([stock.id])
    redirect_to watchlist_items_path, notice: "Đã thêm #{symbol} vào watchlist."
  end

  def toggle
    item = current_account.watchlist_items.find(params[:id])
    item.update(active: !item.active)
    redirect_to watchlist_items_path, notice: "#{item.stock.symbol}: #{item.active? ? 'BẬT' : 'TẮT'} theo dõi."
  end

  def destroy
    current_account.watchlist_items.find(params[:id]).destroy
    redirect_to watchlist_items_path, notice: "Đã xoá khỏi watchlist."
  end
end
