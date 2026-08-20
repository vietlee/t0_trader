import { Controller } from "@hotwired/stimulus"

// Tính khối lượng nên mua theo % rủi ro và khoảng cắt lỗ.
export default class extends Controller {
  static targets = ["capital", "risk", "entry", "stop", "nav",
                    "riskAmount", "shares", "orderValue", "navPct", "warn"]

  connect() { this.calc() }

  num(el) { return parseFloat((el.value || "").replace(/\./g, "").replace(/,/g, ".")) || 0 }
  fmt(n) { return Math.round(n).toLocaleString("vi-VN") }

  calc() {
    const capital = this.num(this.capitalTarget)
    const riskPct = this.num(this.riskTarget)
    const entry = this.num(this.entryTarget)
    const stop = this.num(this.stopTarget)
    const nav = parseFloat(this.navTarget.dataset.nav) || capital

    const riskAmount = capital * riskPct / 100
    const perShare = Math.abs(entry - stop)
    let shares = 0
    if (perShare > 0 && riskAmount > 0) {
      shares = Math.floor(riskAmount / perShare / 100) * 100 // làm tròn lô 100
    }
    const orderValue = shares * entry
    const navPct = nav > 0 ? (orderValue / nav * 100) : 0

    this.riskAmountTarget.textContent = this.fmt(riskAmount) + " đ"
    this.sharesTarget.textContent = shares > 0 ? this.fmt(shares) + " CP" : "—"
    this.orderValueTarget.textContent = this.fmt(orderValue) + " đ"
    this.navPctTarget.textContent = navPct.toFixed(1) + "% NAV"

    let warn = ""
    if (perShare <= 0) warn = "Nhập giá vào và giá cắt lỗ khác nhau."
    else if (stop >= entry) warn = "Với lệnh mua, giá cắt lỗ nên THẤP hơn giá vào."
    else if (navPct > 40) warn = "⚠ Lệnh này chiếm >40% NAV — rủi ro tập trung cao."
    this.warnTarget.textContent = warn
    this.warnTarget.style.display = warn ? "block" : "none"
  }
}
