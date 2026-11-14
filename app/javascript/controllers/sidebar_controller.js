import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "expandTrigger"]

  connect() {
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    window.addEventListener("keydown", this.boundHandleKeydown)

    const isCollapsed = localStorage.getItem("devbook:sidebar-collapsed") === "true"
    this.applyState(isCollapsed)
  }

  disconnect() {
    window.removeEventListener("keydown", this.boundHandleKeydown)
  }

  handleKeydown(event) {
    if ((event.metaKey || event.ctrlKey) && (event.key === "\\" || event.code === "Backslash")) {
      event.preventDefault()
      this.toggle()
    }
  }

  toggle() {
    const willBeCollapsed = !this.isCollapsed()
    localStorage.setItem("devbook:sidebar-collapsed", willBeCollapsed ? "true" : "false")
    this.applyState(willBeCollapsed)
  }

  isCollapsed() {
    if (this.hasSidebarTarget) {
      return this.sidebarTarget.classList.contains("hidden") || document.documentElement.classList.contains("sidebar-collapsed")
    }
    return false
  }

  applyState(collapsed) {
    if (collapsed) {
      document.documentElement.classList.add("sidebar-collapsed")
      if (this.hasSidebarTarget) {
        this.sidebarTarget.classList.add("hidden")
      }
      if (this.hasExpandTriggerTarget) {
        this.expandTriggerTarget.classList.remove("hidden")
      }
    } else {
      document.documentElement.classList.remove("sidebar-collapsed")
      if (this.hasSidebarTarget) {
        this.sidebarTarget.classList.remove("hidden")
      }
      if (this.hasExpandTriggerTarget) {
        this.expandTriggerTarget.classList.add("hidden")
      }
    }
  }
}
