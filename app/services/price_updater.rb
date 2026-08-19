# Cập nhật giá thị trường cho nhiều mã từ VnStockPrice.
class PriceUpdater
  Result = Struct.new(:updated, :failed, keyword_init: true)

  # stocks: quan hệ/mảng Stock. Trả về Result(updated:, failed:[symbols]).
  def self.run(stocks)
    updated = 0
    failed = []
    Array(stocks).each do |stock|
      price = VnStockPrice.fetch(stock.symbol)
      if price && price.positive?
        stock.update_columns(current_price: price, price_updated_at: Time.current)
        updated += 1
      else
        failed << stock.symbol
      end
    end
    Result.new(updated: updated, failed: failed)
  end

  # Chỉ các mã đang có người nắm giữ (giảm số request).
  def self.held_stock_ids
    Trade.executed.side_buy.distinct.pluck(:stock_id)
  end
end
