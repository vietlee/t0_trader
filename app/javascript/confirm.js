import { Turbo } from "@hotwired/turbo-rails"

// Thay hộp confirm mặc định của trình duyệt bằng modal HTML có style.
Turbo.setConfirmMethod((message) => {
  return new Promise((resolve) => {
    const overlay = document.createElement("div")
    overlay.className = "confirm-overlay"
    overlay.innerHTML = `
      <div class="confirm-box" role="dialog" aria-modal="true">
        <div class="confirm-title">Xác nhận</div>
        <div class="confirm-msg"></div>
        <div class="confirm-actions">
          <button type="button" class="btn btn-ghost" data-act="cancel">Huỷ</button>
          <button type="button" class="btn btn-danger" data-act="ok">Đồng ý</button>
        </div>
      </div>`
    overlay.querySelector(".confirm-msg").textContent = message
    document.body.appendChild(overlay)
    requestAnimationFrame(() => overlay.classList.add("show"))

    const cleanup = (val) => {
      overlay.classList.remove("show")
      document.removeEventListener("keydown", onKey)
      setTimeout(() => overlay.remove(), 150)
      resolve(val)
    }
    const onKey = (e) => {
      if (e.key === "Escape") cleanup(false)
      if (e.key === "Enter") cleanup(true)
    }
    overlay.addEventListener("click", (e) => {
      if (e.target === overlay) return cleanup(false)
      const act = e.target.closest("[data-act]")?.dataset.act
      if (act === "ok") cleanup(true)
      if (act === "cancel") cleanup(false)
    })
    document.addEventListener("keydown", onKey)
    setTimeout(() => overlay.querySelector("[data-act=ok]").focus(), 40)
  })
})
