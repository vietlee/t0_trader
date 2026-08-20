module ApplicationHelper
  # Định dạng tiền VND: 1.234.567 ₫
  def vnd(amount, unit: "₫")
    return "—" if amount.nil?

    n = number_with_delimiter(amount.to_d.round(0).to_i, delimiter: ".")
    unit.present? ? "#{n} #{unit}".html_safe : n
  end

  # Số tiền đầy đủ có dấu chấm ngăn nghìn (vd 1.700.000). Kèm "đ".
  def vnd_short(amount)
    return "—" if amount.nil?

    v = amount.to_d
    sign = v.negative? ? "-" : ""
    "#{sign}#{number_with_delimiter(v.abs.round(0).to_i, delimiter: ".")} đ"
  end

  # Màu theo dấu (lời xanh / lỗ đỏ / hoà xám)
  def pnl_color(value)
    v = value.to_d
    return "text-emerald-400" if v.positive?
    return "text-rose-400" if v.negative?

    "text-slate-400"
  end

  # P&L có dấu + màu
  def pnl(value, short: false)
    v = value.to_d
    sign = v.positive? ? "+" : ""
    text = short ? "#{sign}#{vnd_short(v)}" : "#{sign}#{vnd(v)}"
    content_tag(:span, text, class: pnl_color(v))
  end

  def pct(value, decimals: 2)
    return "—" if value.nil?

    v = value.to_d
    sign = v.positive? ? "+" : ""
    "#{sign}#{number_with_precision(v, precision: decimals, strip_insignificant_zeros: true)}%"
  end

  def pnl_pct(value)
    content_tag(:span, pct(value), class: pnl_color(value))
  end

  def side_badge(trade)
    if trade.side_buy?
      content_tag(:span, "MUA", class: "badge badge-buy")
    else
      content_tag(:span, "BÁN", class: "badge badge-sell")
    end
  end

  STATUS_LABELS = {
    "draft" => "Nháp", "pending" => "Đang về", "settled" => "Đã về",
    "closed" => "Đã đóng", "cancelled" => "Huỷ"
  }.freeze

  def status_badge(trade)
    content_tag(:span, STATUS_LABELS[trade.status] || trade.status,
                class: "badge badge-status badge-#{trade.status}")
  end

  # Gợi ý hành động dựa trên % lời/lỗ so với ngưỡng cảnh báo của user.
  def position_suggestion(pct, threshold)
    p = pct.to_f
    t = threshold.to_f
    if t.positive? && p >= t
      content_tag(:span, "Cân nhắc chốt lời", class: "badge", style: "background:rgba(16,185,129,.18);color:#6ee7b7")
    elsif t.positive? && p <= -t
      content_tag(:span, "Cân nhắc cắt lỗ", class: "badge", style: "background:rgba(244,63,94,.18);color:#fda4b4")
    else
      content_tag(:span, "Tiếp tục giữ", class: "badge", style: "background:rgba(148,163,184,.14);color:#9fb0cc")
    end
  end

  # Nút mở popup biểu đồ giá cho một mã.
  def chart_btn(symbol)
    sym = symbol.to_s.upcase
    content_tag(:button, type: "button", class: "chart-btn", title: "Xem biểu đồ giá #{sym}",
                onclick: "window.dispatchEvent(new CustomEvent('open-price-chart',{detail:{symbol:'#{escape_javascript(sym)}'}}))") do
      raw('<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 3v18h18"/><path d="M7 14l3-3 3 3 5-6"/></svg>')
    end
  end

  def nav_link(name, path, icon)
    active = current_page?(path) || (path != root_path && request.path.start_with?(path))
    classes = ["nav-link"]
    classes << "nav-link-active" if active
    link_to path, class: classes.join(" ") do
      raw(%(<span class="nav-icon">#{icon}</span><span>#{name}</span>))
    end
  end
end
