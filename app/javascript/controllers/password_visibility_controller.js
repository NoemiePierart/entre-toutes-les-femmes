import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "icon"]

  connect() {
    if (!this.hasInputTarget) return
    const button = this.element.querySelector(".password-toggle")
    if (!button) return

    this.inputTarget.style.paddingRight = "2.75rem"
    this.element.style.position = "relative"

    requestAnimationFrame(() => {
      const wrapperTop = this.element.getBoundingClientRect().top
      const inputRect = this.inputTarget.getBoundingClientRect()
      const buttonHeight = button.offsetHeight || 24
      button.style.top = `${inputRect.top - wrapperTop + (inputRect.height - buttonHeight) / 2}px`
    })
  }

  toggle() {
    const showing = this.inputTarget.type === "text"
    this.inputTarget.type = showing ? "password" : "text"
    this.iconTarget.className = showing ? "fa-regular fa-eye" : "fa-regular fa-eye-slash"
    this.inputTarget.focus()
  }
}
