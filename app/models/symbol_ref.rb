class SymbolRef < ApplicationRecord
  validates :symbol, presence: true, uniqueness: true

  # Gợi ý mã khi gõ: ưu tiên mã bắt đầu bằng từ khoá, rồi tới tên công ty.
  def self.search(query, limit: 10)
    term = query.to_s.strip.upcase.gsub(/[^A-Z0-9 ]/, "")
    return [] if term.blank?

    by_symbol = where("symbol LIKE ?", "#{term}%").order(:symbol).limit(limit).to_a
    remaining = limit - by_symbol.size
    return by_symbol if remaining <= 0

    ids = by_symbol.map(&:id)
    by_name = where("UPPER(name) LIKE ?", "%#{term}%")
    by_name = by_name.where.not(id: ids) if ids.any?
    by_symbol + by_name.order(:symbol).limit(remaining).to_a
  end
end
