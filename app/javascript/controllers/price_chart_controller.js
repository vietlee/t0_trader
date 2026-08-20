import { Controller } from "@hotwired/stimulus"

// Popup mini biểu đồ giá ~1 tháng cho một mã (đường/area).
export default class extends Controller {
  static targets = ["modal", "symbol", "name", "stats", "chart", "status"]

  connect() {
    this._onOpen = (e) => this.open(e.detail.symbol)
    window.addEventListener("open-price-chart", this._onOpen)
  }
  disconnect() { window.removeEventListener("open-price-chart", this._onOpen) }

  backdrop(e) { if (e.target === this.modalTarget) this.close() }
  close() {
    this.modalTarget.classList.remove("show")
    if (this.chart) { try { this.chart.destroy() } catch (_) {} this.chart = null }
  }

  async open(symbol) {
    this.symbolTarget.textContent = symbol
    this.nameTarget.textContent = ""
    this.statsTarget.innerHTML = ""
    this.chartTarget.innerHTML = ""
    this.statusTarget.textContent = "Đang tải dữ liệu giá…"
    this.modalTarget.classList.add("show")

    try {
      const res = await fetch(`/price-chart/${encodeURIComponent(symbol)}`, { headers: { Accept: "application/json" } })
      const d = await res.json()
      if (d.error) { this.statusTarget.textContent = d.error; return }
      this.statusTarget.textContent = ""
      this.nameTarget.textContent = d.name || ""
      this.renderStats(d)
      this.renderChart(d.series)
    } catch (_) {
      this.statusTarget.textContent = "Lỗi tải dữ liệu giá."
    }
  }

  fmt(n) { return Math.round(n).toLocaleString("vi-VN") }

  renderStats(d) {
    const up = d.change_pct >= 0
    const color = up ? "#6ee7b7" : "#fda4b4"
    this.statsTarget.innerHTML = `
      <div><div style="color:#8595b4;font-size:11px">Giá hiện tại</div><div style="font-weight:700">${this.fmt(d.last)} đ</div></div>
      <div><div style="color:#8595b4;font-size:11px">Thay đổi ~1 tháng</div><div style="font-weight:700;color:${color}">${up ? "+" : ""}${d.change_pct}%</div></div>
      <div><div style="color:#8595b4;font-size:11px">Cao nhất</div><div style="font-weight:700">${this.fmt(d.high)}</div></div>
      <div><div style="color:#8595b4;font-size:11px">Thấp nhất</div><div style="font-weight:700">${this.fmt(d.low)}</div></div>`
  }

  renderChart(series) {
    if (this.chart) { try { this.chart.destroy() } catch (_) {} }
    const Chartkick = window.Chartkick
    if (!Chartkick) { this.statusTarget.textContent = "Chưa tải được thư viện biểu đồ."; return }
    const values = series.map((p) => p[1])
    const lo = Math.min(...values), hi = Math.max(...values)
    const pad = Math.max((hi - lo) * 0.15, hi * 0.02)
    this.chart = new Chartkick.AreaChart(this.chartTarget, series, {
      colors: ["#10b981"], curve: true, points: false, thousands: ".", suffix: " đ",
      library: {
        scales: { x: { grid: { display: false }, ticks: { color: "#7182a3", maxTicksLimit: 6 } },
                  y: { min: Math.max(0, Math.floor((lo - pad) / 100) * 100), max: Math.ceil((hi + pad) / 100) * 100,
                       grid: { color: "rgba(255,255,255,.05)" }, ticks: { color: "#7182a3" } } },
        plugins: { legend: { display: false } }
      }
    })
  }
}
