require "net/http"
require "json"

# Lấy giá cổ phiếu VN từ VNDirect dchart-api (giá đóng cửa gần nhất).
# API trả giá đơn vị nghìn đồng (vd 26.7 = 26.700đ) -> nhân 1000, làm tròn 10đ.
class VnStockPrice
  BASE = "https://dchart-api.vndirect.com.vn/dchart/history".freeze

  # Trả về giá (Integer VND) hoặc nil nếu không lấy được.
  def self.fetch(symbol)
    symbol = symbol.to_s.strip.upcase
    return nil if symbol.blank?

    now = Time.now.to_i
    from = now - (20 * 24 * 3600) # 20 ngày gần nhất
    uri = URI(BASE)
    uri.query = URI.encode_www_form(resolution: "D", symbol: symbol, from: from, to: now)

    res = http_get(uri)
    return nil unless res.is_a?(Net::HTTPSuccess)

    data = JSON.parse(res.body)
    return nil unless data["s"].nil? || data["s"] == "ok"

    closes = Array(data["c"]).compact
    return nil if closes.empty?

    raw = closes.last.to_f
    return nil if raw <= 0

    price = raw < 1000 ? raw * 1000 : raw # chuẩn hoá nghìn đồng -> đồng
    (price / 10.0).round * 10 # làm tròn bước giá 10đ
  rescue => e
    Rails.logger.warn("VnStockPrice fetch #{symbol} lỗi: #{e.class} #{e.message}")
    nil
  end

  def self.http_get(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 8
    http.read_timeout = 12
    req = Net::HTTP::Get.new(uri)
    req["User-Agent"] = "Mozilla/5.0 (T0Trader price fetch)"
    req["Accept"] = "*/*"
    http.request(req)
  end
end
