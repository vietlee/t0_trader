require "net/http"
require "json"

# Lấy lịch sử giá (đóng cửa) ~1 tháng từ VNDirect dchart để vẽ mini biểu đồ.
class VnStockHistory
  BASE = "https://dchart-api.vndirect.com.vn/dchart/history".freeze

  Result = Struct.new(:series, :high, :low, :last, :first, :change_pct, keyword_init: true)

  # days: số ngày lịch (mặc định ~45 ngày lịch để đủ ~1 tháng phiên).
  def self.fetch(symbol, days: 45)
    symbol = symbol.to_s.strip.upcase
    return nil if symbol.blank?

    now = Time.now.to_i
    from = now - (days * 24 * 3600)
    uri = URI(BASE)
    uri.query = URI.encode_www_form(resolution: "D", symbol: symbol, from: from, to: now)

    res = VnStockPrice.http_get(uri)
    return nil unless res.is_a?(Net::HTTPSuccess)

    data = JSON.parse(res.body)
    times = Array(data["t"])
    closes = Array(data["c"])
    return nil if times.empty? || closes.empty?

    series = times.each_with_index.filter_map do |t, i|
      c = closes[i]
      next if c.nil?

      price = c.to_f < 1000 ? c.to_f * 1000 : c.to_f
      [Time.at(t).strftime("%d/%m"), price.round]
    end
    return nil if series.empty?

    values = series.map(&:last)
    first = values.first
    last = values.last
    Result.new(
      series: series, high: values.max, low: values.min, last: last, first: first,
      change_pct: first.positive? ? ((last - first) / first.to_f * 100).round(2) : 0
    )
  rescue => e
    Rails.logger.warn("VnStockHistory #{symbol} lỗi: #{e.class} #{e.message}")
    nil
  end
end
