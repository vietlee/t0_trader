// Overlay loading toàn màn hình + disable nút khi submit form (native + Turbo).
(function () {
  let overlay

  function ensure() {
    if (overlay && document.body.contains(overlay)) return overlay
    overlay = document.createElement("div")
    overlay.className = "app-loading"
    overlay.innerHTML =
      '<div class="app-loading-box"><div class="spinner-lg"></div><div class="app-loading-text">Đang xử lý…</div></div>'
    document.body.appendChild(overlay)
    return overlay
  }
  function show() { ensure().classList.add("show") }
  function hide() { if (overlay) overlay.classList.remove("show") }

  function disableSubmits(form) {
    form.querySelectorAll("button[type=submit], input[type=submit], button:not([type])").forEach((b) => {
      if (!b.disabled) { b.disabled = true; b.setAttribute("data-loading-disabled", "") }
    })
  }
  function reenableAll() {
    document.querySelectorAll("[data-loading-disabled]").forEach((b) => {
      b.disabled = false
      b.removeAttribute("data-loading-disabled")
    })
  }

  function skip(form) {
    return !(form instanceof HTMLFormElement) || form.hasAttribute("data-no-loading")
  }

  // Form không dùng Turbo -> điều hướng full page: hiện overlay tới khi trang mới tải.
  document.addEventListener("submit", (e) => {
    const form = e.target
    if (skip(form)) return
    if (form.getAttribute("data-turbo") === "false") {
      disableSubmits(form)
      show()
    }
  }, true)

  // Form dùng Turbo: submit-start chạy SAU khi confirm (nếu có) đã đồng ý.
  document.addEventListener("turbo:submit-start", (e) => {
    if (skip(e.target)) return
    disableSubmits(e.target)
    show()
  })
  document.addEventListener("turbo:submit-end", () => { hide(); reenableAll() })
  document.addEventListener("turbo:load", () => { hide(); reenableAll() })
  document.addEventListener("turbo:render", () => { hide() })
  window.addEventListener("pageshow", () => { hide(); reenableAll() })
})()
