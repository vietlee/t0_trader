import { Controller } from "@hotwired/stimulus"

// Phản hồi tức thì khi gửi câu hỏi cho AI Coach: hiện ngay tin của user + "đang trả lời…"
// trong lúc chờ AI (form vẫn submit thường và reload khi có kết quả).
export default class extends Controller {
  static targets = ["input", "list", "empty", "send", "body"]

  submit(e) {
    const text = this.inputTarget.value.trim()
    if (!text) { e.preventDefault(); return }

    if (this.hasEmptyTarget) this.emptyTarget.style.display = "none"

    const u = document.createElement("div")
    u.className = "chat-msg chat-user"
    u.textContent = text
    this.listTarget.appendChild(u)

    const a = document.createElement("div")
    a.className = "chat-msg chat-ai"
    a.innerHTML = '<span class="typing"><span></span><span></span><span></span></span>'
    this.listTarget.appendChild(a)

    this.inputTarget.value = ""
    this.inputTarget.disabled = true
    if (this.hasSendTarget) this.sendTarget.disabled = true
    this.scroll()
    // không preventDefault -> form submit thường, reload khi AI trả lời xong
  }

  scroll() {
    const b = this.hasBodyTarget ? this.bodyTarget : this.element
    b.scrollTop = b.scrollHeight
  }
}
