class FetchStockPricesJob < ApplicationJob
  queue_as :default

  # Cập nhật giá cho mọi mã đang được nắm giữ; nếu truyền stock_ids thì chỉ các mã đó.
  def perform(stock_ids = nil)
    stocks = if stock_ids
      Stock.where(id: stock_ids)
    else
      Stock.where(id: PriceUpdater.held_stock_ids)
    end
    result = PriceUpdater.run(stocks)
    Rails.logger.info("FetchStockPricesJob: cập nhật #{result.updated}, lỗi #{result.failed.join(',')}")
  end
end
