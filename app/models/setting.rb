class Setting < ApplicationRecord
  # Key-value cấu hình toàn hệ thống (biểu phí, model AI, ...).
  # Giá trị lưu trong jsonb dưới khoá "v" để giữ được kiểu số/chuỗi.

  DEFAULTS = {
    "buy_fee_rate"   => 0.0015,  # 0.15%
    "sell_fee_rate"  => 0.0015,  # 0.15%
    "sell_tax_rate"  => 0.0010,  # 0.10%
    "ai_model"       => "claude-sonnet-5",
    "ai_enabled"     => true
  }.freeze

  def self.[](key)
    key = key.to_s
    record = cache[key]
    return record.value["v"] if record && record.value&.key?("v")

    DEFAULTS[key]
  end

  def self.[]=(key, val)
    record = find_or_initialize_by(key: key.to_s)
    record.value = { "v" => val }
    record.save!
    @cache = nil
    val
  end

  def self.fee_rates
    {
      buy_fee_rate:  self["buy_fee_rate"].to_f,
      sell_fee_rate: self["sell_fee_rate"].to_f,
      sell_tax_rate: self["sell_tax_rate"].to_f
    }
  end

  def self.cache
    @cache ||= all.index_by(&:key)
  end

  def self.reset_cache!
    @cache = nil
  end
end
