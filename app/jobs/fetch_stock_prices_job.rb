class FetchStockPricesJob < ApplicationJob
  queue_as :default

  # Cập nhật giá cho mã đang giữ + mã trong watchlist; nếu truyền stock_ids thì chỉ các mã đó.
  def perform(stock_ids = nil)
    ids = if stock_ids
      stock_ids
    else
      (PriceUpdater.held_stock_ids + WatchlistItem.distinct.pluck(:stock_id)).uniq
    end
    result = PriceUpdater.run(Stock.where(id: ids))
    Rails.logger.info("FetchStockPricesJob: cập nhật #{result.updated}, lỗi #{result.failed.join(',')}")
  end
end
