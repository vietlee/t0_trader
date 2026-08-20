require "net/http"
require "json"

# Nạp danh sách mã cổ phiếu VN (đang niêm yết) từ VNDirect vào bảng symbol_refs
# để gợi ý khi gõ. Chạy lại định kỳ để cập nhật mã mới.
class SymbolImporter
  URL = "https://api-finfo.vndirect.com.vn/v4/stocks".freeze

  def self.run
    uri = URI(URL)
    uri.query = URI.encode_www_form(
      q: "type:STOCK~status:LISTED", size: 3000, fields: "code,companyName,floor"
    )
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 20
    req = Net::HTTP::Get.new(uri)
    req["User-Agent"] = "Mozilla/5.0 (T0Trader)"
    req["Accept"] = "*/*"

    res = http.request(req)
    return { ok: false, error: "HTTP #{res.code}" } unless res.is_a?(Net::HTTPSuccess)

    data = JSON.parse(res.body)["data"] || []
    now = Time.current
    rows = data.filter_map do |d|
      code = d["code"].to_s.strip.upcase
      next if code.blank?

      { symbol: code, name: d["companyName"], exchange: d["floor"], created_at: now, updated_at: now }
    end

    SymbolRef.upsert_all(rows, unique_by: :symbol) if rows.any?
    { ok: true, count: rows.size }
  rescue => e
    Rails.logger.warn("SymbolImporter lỗi: #{e.class} #{e.message}")
    { ok: false, error: e.message }
  end
end
