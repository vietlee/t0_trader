import { Controller } from "@hotwired/stimulus"

// Popup ghi nhanh giao dịch: gõ text hoặc nói (Web Speech API) -> AI tạo lệnh.
export default class extends Controller {
  static targets = ["modal", "text", "mic", "status"]

  open(e) { e?.preventDefault(); this.modalTarget.classList.add("show"); setTimeout(() => this.textTarget.focus(), 50) }
  close(e) { e?.preventDefault(); this.modalTarget.classList.remove("show"); this.stop() }
  backdrop(e) { if (e.target === this.modalTarget) this.close() }

  toggleMic(e) {
    e?.preventDefault()
    this.recognizing ? this.stop() : this.start()
  }

  start() {
    const SR = window.SpeechRecognition || window.webkitSpeechRecognition
    if (!SR) { this.statusTarget.textContent = "Trình duyệt/thiết bị không hỗ trợ nhập giọng nói. Hãy gõ tay."; return }
    this.rec = new SR()
    this.rec.lang = "vi-VN"
    this.rec.interimResults = true
    this.rec.continuous = true
    this.base = this.textTarget.value.trim()
    this.rec.onresult = (ev) => {
      let t = ""
      for (const r of ev.results) t += r[0].transcript
      this.textTarget.value = (this.base ? this.base + " " : "") + t
    }
    this.rec.onerror = (ev) => { this.statusTarget.textContent = "Lỗi mic: " + ev.error + " (cấp quyền micro và thử lại)" }
    this.rec.onend = () => { this.recognizing = false; this.micTarget.classList.remove("recording"); if (this.statusTarget.textContent.startsWith("Đang nghe")) this.statusTarget.textContent = "" }
    try {
      this.rec.start()
      this.recognizing = true
      this.micTarget.classList.add("recording")
      this.statusTarget.textContent = "Đang nghe… ví dụ: \"mua 1000 BSR giá 23\""
    } catch (_) { /* start khi đang chạy */ }
  }

  stop() {
    if (this.rec) { try { this.rec.stop() } catch (_) {} this.rec = null }
    this.recognizing = false
    this.micTarget?.classList.remove("recording")
  }
}
