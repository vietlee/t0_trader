module Ai
  # Trích xuất thông tin giao dịch từ câu mô tả tự nhiên bằng AI.
  # VD: "đã mua BSR giá 23" -> { side: "buy", symbol: "BSR", price: 23000, quantity: nil }
  class TradeParser
    SYSTEM = <<~SYS.freeze
      Bạn trích xuất thông tin GIAO DỊCH CỔ PHIẾU VIỆT NAM từ câu mô tả của người dùng.
      Chỉ trả về DUY NHẤT một JSON object hợp lệ, KHÔNG kèm giải thích, KHÔNG markdown.

      Cấu trúc:
      {"side":"buy"|"sell","symbol":"MÃ_VIẾT_HOA","price":<giá VND mỗi cổ phiếu, số nguyên>,"quantity":<số cổ phiếu hoặc null>,"date":"YYYY-MM-DD" hoặc null}

      Quy tắc:
      - "mua"/"đã mua"/"long" -> side=buy; "bán"/"đã bán"/"chốt"/"short" -> side=sell.
      - Giá người Việt thường nói theo đơn vị NGHÌN ĐỒNG: "giá 23" = 23000, "27.5" = 27500. Nếu số giá < 1000 thì nhân 1000. Trả price là số nguyên VND.
      - symbol là mã 3 ký tự viết HOA (BSR, FPT, HPG...).
      - quantity: nếu có nêu số lượng (vd "1000 cp", "2 lô" = 200) thì trả số cổ phiếu; nếu không rõ trả null.
      - date: nếu người dùng nêu ngày (vd "hôm qua", "15/8", "ngày 10", "thứ 2 tuần trước") thì trả ngày dạng YYYY-MM-DD dựa trên NGÀY HÔM NAY được cung cấp. Không nêu ngày -> null. Ngày không được ở tương lai.
      - Nếu KHÔNG xác định được side, symbol hoặc price, trả: {"error":"mô tả ngắn lý do"}.
    SYS

    Result = Struct.new(:ok, :side, :symbol, :price, :quantity, :traded_on, :error, keyword_init: true)

    def self.parse(text, user:)
      raise Anthropic::Client::Error, "Chưa cấu hình AI" unless Anthropic::Client.configured?

      today = Date.current
      user_msg = "Hôm nay là #{today.strftime('%Y-%m-%d')} (#{I18n.t('date.day_names')[today.wday] rescue today.strftime('%A')}).\n\n#{text}"
      raw = Anthropic::Client.chat(
        system: SYSTEM,
        messages: [{ role: "user", content: user_msg }],
        model: user.ai_model,
        max_tokens: 300
      )
      json = extract_json(raw)
      data = JSON.parse(json)

      if data["error"].present?
        return Result.new(ok: false, error: data["error"])
      end

      side = data["side"].to_s
      symbol = data["symbol"].to_s.strip.upcase
      price = normalize_price(data["price"])
      qty = data["quantity"].present? ? data["quantity"].to_i : nil
      traded_on = parse_date(data["date"])

      if !%w[buy sell].include?(side) || symbol.blank? || price.nil? || price <= 0
        return Result.new(ok: false, error: "Không đủ thông tin (loại lệnh / mã / giá).")
      end

      Result.new(ok: true, side: side, symbol: symbol, price: price, quantity: qty, traded_on: traded_on)
    rescue JSON::ParserError
      Result.new(ok: false, error: "AI trả về dữ liệu không hợp lệ.")
    rescue => e
      Result.new(ok: false, error: e.message)
    end

    def self.extract_json(text)
      text = text.to_s.strip
      text = text.sub(/\A```(?:json)?/, "").sub(/```\z/, "").strip
      m = text.match(/\{.*\}/m)
      m ? m[0] : text
    end

    def self.parse_date(val)
      return nil if val.blank?

      d = Date.parse(val.to_s) rescue nil
      return nil if d.nil?
      d > Date.current ? Date.current : d # không cho tương lai
    end

    def self.normalize_price(val)
      p = val.to_f
      return nil if p <= 0

      p = p * 1000 if p < 1000 # chuẩn hoá nghìn đồng
      p.round
    end
  end
end
