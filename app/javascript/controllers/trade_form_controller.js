import { Controller } from "@hotwired/stimulus"

// Tự tính phí/thuế theo biểu phí + hiển thị giá trị lệnh, dòng tiền.
export default class extends Controller {
  static targets = ["side", "quantity", "price", "fee", "tax", "gross", "net", "feeHint"]
  static values = { buyFee: Number, sellFee: Number, sellTax: Number }

  connect() { this.feeTouched = false; this.taxTouched = false; this.recalc() }

  markFee() { this.feeTouched = true }
  markTax() { this.taxTouched = true }

  recalc() {
    const qty = parseFloat(this.quantityTarget.value) || 0
    const price = parseFloat(this.priceTarget.value) || 0
    const gross = qty * price
    const isSell = this.sideTarget.value === "sell"

    const feeRate = isSell ? this.sellFeeValue : this.buyFeeValue
    const taxRate = isSell ? this.sellTaxValue : 0

    if (!this.feeTouched) this.feeTarget.value = Math.round(gross * feeRate)
    if (!this.taxTouched) this.taxTarget.value = Math.round(gross * taxRate)

    const fee = parseFloat(this.feeTarget.value) || 0
    const tax = parseFloat(this.taxTarget.value) || 0
    const net = isSell ? (gross - fee - tax) : (gross + fee)

    if (this.hasGrossTarget) this.grossTarget.textContent = this.fmt(gross)
    if (this.hasNetTarget) {
      this.netTarget.textContent = (isSell ? "+" : "-") + this.fmt(net)
      this.netTarget.className = isSell ? "text-emerald-400" : "text-rose-400"
    }
    if (this.hasFeeHintTarget) {
      this.feeHintTarget.textContent = `Phí+thuế ước tính: ${this.fmt(fee + tax)} ₫`
    }
  }

  fmt(n) { return Math.round(n).toLocaleString("vi-VN") }
}
