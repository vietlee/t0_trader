import { Controller } from "@hotwired/stimulus"

// Tự tính phí/thuế theo biểu phí + hiển thị giá trị lệnh, dòng tiền.
// Các ô số hiển thị có dấu chấm ngăn nghìn (numeric-input controller lo việc bỏ chấm khi submit).
export default class extends Controller {
  static targets = ["side", "quantity", "price", "fee", "tax", "gross", "net", "feeHint"]
  static values = { buyFee: Number, sellFee: Number, sellTax: Number }

  connect() { this.feeTouched = false; this.taxTouched = false; this.recalc() }

  markFee() { this.feeTouched = true }
  markTax() { this.taxTouched = true }

  num(el) { return parseFloat((el.value || "").replace(/\./g, "").replace(/,/g, ".")) || 0 }
  fmt(n) { return Math.round(n).toLocaleString("vi-VN") }

  recalc() {
    const qty = this.num(this.quantityTarget)
    const price = this.num(this.priceTarget)
    const gross = qty * price
    const isSell = this.sideTarget.value === "sell"

    const feeRate = isSell ? this.sellFeeValue : this.buyFeeValue
    const taxRate = isSell ? this.sellTaxValue : 0

    if (!this.feeTouched) this.feeTarget.value = this.fmt(gross * feeRate)
    if (!this.taxTouched) this.taxTarget.value = this.fmt(gross * taxRate)

    const fee = this.num(this.feeTarget)
    const tax = this.num(this.taxTarget)
    const net = isSell ? (gross - fee - tax) : (gross + fee)

    if (this.hasGrossTarget) this.grossTarget.textContent = this.fmt(gross) + " đ"
    if (this.hasNetTarget) {
      this.netTarget.textContent = (isSell ? "+" : "-") + this.fmt(net) + " đ"
      this.netTarget.className = isSell ? "text-emerald-400" : "text-rose-400"
    }
    if (this.hasFeeHintTarget) {
      this.feeHintTarget.textContent = `Phí+thuế ước tính: ${this.fmt(fee + tax)} đ`
    }
  }
}
