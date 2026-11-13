import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "form",
    "textarea",
    "titleInput",
    "editorPane",
    "previewPane",
    "splitPane",
    "statusIndicator",
    "previewTab",
    "editTab",
    "splitTab"
  ]
  static values = {
    mode: { type: String, default: "preview" }, // "preview", "edit", "split"
    saveUrl: String,
    autoSave: { type: Boolean, default: true }
  }

  connect() {
    this.saveTimeout = null
    this.applyMode(this.modeValue)
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    window.addEventListener("keydown", this.boundHandleKeydown)
  }

  disconnect() {
    if (this.saveTimeout) clearTimeout(this.saveTimeout)
    window.removeEventListener("keydown", this.boundHandleKeydown)
  }

  handleKeydown(event) {
    if ((event.metaKey || event.ctrlKey) && event.key === "s") {
      event.preventDefault()
      this.saveNow()
    }
  }

  setPreviewMode(event) {
    if (event) event.preventDefault()
    this.applyMode("preview")
  }

  setEditMode(event) {
    if (event) event.preventDefault()
    this.applyMode("edit")
    if (this.hasTextareaTarget) {
      this.textareaTarget.focus()
    }
  }

  setSplitMode(event) {
    if (event) event.preventDefault()
    this.applyMode("split")
    if (this.hasTextareaTarget) {
      this.textareaTarget.focus()
    }
  }

  applyMode(mode) {
    this.modeValue = mode

    const activeClasses = ["bg-neutral-800", "text-neutral-100", "shadow-sm"]
    const inactiveClasses = ["text-neutral-400", "hover:text-neutral-200"]

    const updateTab = (tabTarget, isActive) => {
      if (!tabTarget) return
      if (isActive) {
        tabTarget.classList.add(...activeClasses)
        tabTarget.classList.remove(...inactiveClasses)
      } else {
        tabTarget.classList.remove(...activeClasses)
        tabTarget.classList.add(...inactiveClasses)
      }
    }

    if (this.hasPreviewTabTarget) updateTab(this.previewTabTarget, mode === "preview")
    if (this.hasEditTabTarget) updateTab(this.editTabTarget, mode === "edit")
    if (this.hasSplitTabTarget) updateTab(this.splitTabTarget, mode === "split")

    if (mode === "preview") {
      if (this.hasPreviewPaneTarget) this.previewPaneTarget.classList.remove("hidden")
      if (this.hasEditorPaneTarget) this.editorPaneTarget.classList.add("hidden")
      if (this.hasSplitPaneTarget) {
        this.splitPaneTarget.classList.remove("grid", "grid-cols-1", "lg:grid-cols-2", "gap-6")
        this.splitPaneTarget.classList.add("block")
      }
    } else if (mode === "edit") {
      if (this.hasPreviewPaneTarget) this.previewPaneTarget.classList.add("hidden")
      if (this.hasEditorPaneTarget) this.editorPaneTarget.classList.remove("hidden")
      if (this.hasSplitPaneTarget) {
        this.splitPaneTarget.classList.remove("grid", "grid-cols-1", "lg:grid-cols-2", "gap-6")
        this.splitPaneTarget.classList.add("block")
      }
    } else if (mode === "split") {
      if (this.hasPreviewPaneTarget) this.previewPaneTarget.classList.remove("hidden")
      if (this.hasEditorPaneTarget) this.editorPaneTarget.classList.remove("hidden")
      if (this.hasSplitPaneTarget) {
        this.splitPaneTarget.classList.remove("block")
        this.splitPaneTarget.classList.add("grid", "grid-cols-1", "lg:grid-cols-2", "gap-6")
      }
    }
  }

  onInput() {
    if (!this.autoSaveValue || !this.hasSaveUrlValue) return

    if (this.hasStatusIndicatorTarget) {
      this.statusIndicatorTarget.textContent = "Unsaved changes..."
      this.statusIndicatorTarget.className = "text-xs font-mono text-amber-400/80"
    }

    if (this.saveTimeout) clearTimeout(this.saveTimeout)
    this.saveTimeout = setTimeout(() => {
      this.saveNow()
    }, 1200)
  }

  async saveNow() {
    if (!this.hasFormTarget) return

    if (this.hasStatusIndicatorTarget) {
      this.statusIndicatorTarget.textContent = "Saving..."
      this.statusIndicatorTarget.className = "text-xs font-mono text-cyan-400 animate-pulse"
    }

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content")
    const formData = new FormData(this.formTarget)

    try {
      const response = await fetch(this.formTarget.action, {
        method: "PATCH",
        headers: {
          "Accept": "text/vnd.turbo-stream.html, application/json",
          "X-CSRF-Token": csrfToken
        },
        body: formData
      })

      if (response.ok) {
        const contentType = response.headers.get("Content-Type") || ""
        if (contentType.includes("text/vnd.turbo-stream.html")) {
          const html = await response.text()
          if (window.Turbo) {
            window.Turbo.renderStreamMessage(html)
          }
        }

        if (this.hasStatusIndicatorTarget) {
          const time = new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", second: "2-digit" })
          this.statusIndicatorTarget.textContent = `Saved at ${time}`
          this.statusIndicatorTarget.className = "text-xs font-mono text-emerald-400"
        }
      } else {
        if (this.hasStatusIndicatorTarget) {
          this.statusIndicatorTarget.textContent = "Error saving"
          this.statusIndicatorTarget.className = "text-xs font-mono text-rose-400"
        }
      }
    } catch (err) {
      console.error("Auto-save failed", err)
      if (this.hasStatusIndicatorTarget) {
        this.statusIndicatorTarget.textContent = "Connection error"
        this.statusIndicatorTarget.className = "text-xs font-mono text-rose-400"
      }
    }
  }
}
