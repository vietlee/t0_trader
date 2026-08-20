import { Controller } from "@hotwired/stimulus"

// Gợi ý mã cổ phiếu khi gõ (dropdown), tránh gõ sai mã.
export default class extends Controller {
  static targets = ["input", "list"]
  static values = { url: String }

  connect() {
    this.index = -1
    this.onDocClick = (e) => { if (!this.element.contains(e.target)) this.close() }
    document.addEventListener("click", this.onDocClick)
  }
  disconnect() { document.removeEventListener("click", this.onDocClick) }

  onInput() {
    // Bỏ qua sự kiện input phát ra do vừa chọn (tránh mở lại dropdown).
    if (this.justPicked) { this.justPicked = false; return }
    const q = this.inputTarget.value.trim()
    clearTimeout(this.timer)
    if (q.length < 1) { this.close(); return }
    this.timer = setTimeout(() => this.fetch(q), 180)
  }

  async fetch(q) {
    try {
      const res = await fetch(`${this.urlValue}?q=${encodeURIComponent(q)}`, { headers: { Accept: "application/json" } })
      const data = await res.json()
      this.render(data)
    } catch (_) { this.close() }
  }

  render(items) {
    if (!items || items.length === 0) { this.close(); return }
    this.index = -1
    this.listTarget.innerHTML = items.map((it, i) => `
      <div class="ac-item" data-i="${i}" data-symbol="${it.symbol}">
        <span class="ac-sym">${it.symbol}</span>
        <span class="ac-ex">${it.exchange || ""}</span>
        <span class="ac-name">${(it.name || "").replace(/</g, "")}</span>
      </div>`).join("")
    this.listTarget.querySelectorAll(".ac-item").forEach((el) => {
      el.addEventListener("mousedown", (e) => { e.preventDefault(); this.pick(el.dataset.symbol) })
    })
    this.listTarget.classList.add("show")
  }

  pick(symbol) {
    this.justPicked = true
    clearTimeout(this.timer)
    this.inputTarget.value = symbol
    this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.close()
    this.inputTarget.focus()
  }

  onKey(e) {
    const items = this.listTarget.querySelectorAll(".ac-item")
    if (!this.listTarget.classList.contains("show") || items.length === 0) return
    if (e.key === "ArrowDown") { e.preventDefault(); this.move(1, items) }
    else if (e.key === "ArrowUp") { e.preventDefault(); this.move(-1, items) }
    else if (e.key === "Enter") {
      if (this.index >= 0) { e.preventDefault(); this.pick(items[this.index].dataset.symbol) }
    } else if (e.key === "Escape") { this.close() }
  }

  move(dir, items) {
    this.index = (this.index + dir + items.length) % items.length
    items.forEach((el, i) => el.classList.toggle("active", i === this.index))
    items[this.index].scrollIntoView({ block: "nearest" })
  }

  close() { this.listTarget.classList.remove("show"); this.listTarget.innerHTML = ""; this.index = -1 }
}
