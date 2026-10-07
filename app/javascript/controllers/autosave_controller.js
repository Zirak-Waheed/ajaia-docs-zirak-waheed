import { Controller } from "@hotwired/stimulus"

// Debounced autosave for the document form. Falls back to the Save button without JS.
export default class extends Controller {
  static targets = ["status"]

  connect() {
    this.timer = null
    this.dirty = false
    this.beforeUnload = (event) => {
      if (this.dirty) { event.preventDefault(); event.returnValue = "" }
    }
    window.addEventListener("beforeunload", this.beforeUnload)
  }

  disconnect() {
    clearTimeout(this.timer)
    window.removeEventListener("beforeunload", this.beforeUnload)
  }

  changed() {
    this.dirty = true
    this.setStatus("Unsaved changes…")
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.save(), 1000)
  }

  async save() {
    this.setStatus("Saving…")
    try {
      const response = await fetch(this.element.action, {
        method: "POST", // Rails reads _method=patch from the form data
        body: new FormData(this.element),
        headers: { Accept: "application/json" },
        credentials: "same-origin"
      })
      if (response.ok) {
        this.dirty = false
        this.setStatus("All changes saved")
      } else {
        const data = await response.json().catch(() => ({}))
        this.setStatus((data.errors || ["Save failed"]).join(", "), true)
      }
    } catch (_error) {
      this.setStatus("Offline: changes not saved yet", true)
    }
  }

  setStatus(text, isError = false) {
    if (!this.hasStatusTarget) return
    this.statusTarget.textContent = text
    this.statusTarget.classList.toggle("is-error", isError)
  }
}
