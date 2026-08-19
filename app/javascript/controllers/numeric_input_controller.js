import { Controller } from "@hotwired/stimulus"

// Hiển thị số có dấu chấm ngăn nghìn (27.000) trong ô nhập,
// tự bỏ dấu chấm trước khi submit để server nhận số nguyên.
export default class extends Controller {
  connect() {
    this.format()
    this.form = this.element.form
    if (this.form) {
      this._onSubmit = () => this.unformat()
      this.form.addEventListener("submit", this._onSubmit)
    }
  }

  disconnect() {
    if (this.form && this._onSubmit) this.form.removeEventListener("submit", this._onSubmit)
  }

  format() {
    const digits = this.element.value.replace(/\D/g, "")
    this.element.value = digits ? Number(digits).toLocaleString("vi-VN") : ""
  }

  unformat() {
    this.element.value = this.element.value.replace(/\D/g, "")
  }
}
