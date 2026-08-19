import { Controller } from "@hotwired/stimulus"

// Đóng/mở sidebar trên mobile.
export default class extends Controller {
  toggle() { this.element.classList.toggle("nav-open") }
  close() { this.element.classList.remove("nav-open") }
}
