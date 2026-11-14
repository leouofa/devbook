import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "main", "expandTrigger"]

  connect() {
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    this.boundHandleResize = this.handleResize.bind(this)
    window.addEventListener("keydown", this.boundHandleKeydown)
    window.addEventListener("resize", this.boundHandleResize)

    const isCollapsed = this.determineInitialCollapsed()
    this.applyState(isCollapsed)
  }

  disconnect() {
    window.removeEventListener("keydown", this.boundHandleKeydown)
    window.removeEventListener("resize", this.boundHandleResize)
  }

  isMobile() {
    return window.innerWidth < 768
  }

  determineInitialCollapsed() {
    if (this.isMobile()) {
      const hasSpecificPath = Boolean(window.location.pathname.match(/\/(prompts|projects)\/(.+)/))
      const sessionMobile = sessionStorage.getItem("devbook:sidebar-mobile-collapsed")
      if (sessionMobile !== null) {
        return sessionMobile === "true"
      }
      return hasSpecificPath
    } else {
      return localStorage.getItem("devbook:sidebar-collapsed") === "true"
    }
  }

  handleResize() {
    this.applyState(this.isCollapsed())
  }

  handleKeydown(event) {
    if ((event.metaKey || event.ctrlKey) && (event.key === "\\" || event.code === "Backslash")) {
      event.preventDefault()
      this.toggle()
    }
  }

  handleNavClick(event) {
    if (!this.isMobile()) return
    const link = event.target.closest("a")
    if (link) {
      this.collapse()
    }
  }

  toggle() {
    const willBeCollapsed = !this.isCollapsed()
    this.setCollapsed(willBeCollapsed)
  }

  collapse() {
    this.setCollapsed(true)
  }

  expand() {
    this.setCollapsed(false)
  }

  setCollapsed(collapsed) {
    if (this.isMobile()) {
      sessionStorage.setItem("devbook:sidebar-mobile-collapsed", collapsed ? "true" : "false")
    } else {
      localStorage.setItem("devbook:sidebar-collapsed", collapsed ? "true" : "false")
    }
    this.applyState(collapsed)
  }

  isCollapsed() {
    return document.documentElement.classList.contains("sidebar-collapsed")
  }

  applyState(collapsed) {
    const mobile = this.isMobile()

    if (collapsed) {
      document.documentElement.classList.add("sidebar-collapsed")

      if (this.hasSidebarTarget) {
        this.sidebarTarget.classList.add("hidden")
        this.sidebarTarget.classList.remove("w-full")
      }
      if (this.hasMainTarget) {
        this.mainTarget.classList.remove("hidden")
        this.mainTarget.classList.add("flex")
      }
      if (this.hasExpandTriggerTarget) {
        this.expandTriggerTarget.classList.remove("hidden")
      }
    } else {
      document.documentElement.classList.remove("sidebar-collapsed")

      if (this.hasSidebarTarget) {
        this.sidebarTarget.classList.remove("hidden")
        if (mobile) {
          this.sidebarTarget.classList.add("w-full")
        } else {
          this.sidebarTarget.classList.remove("w-full")
        }
      }
      if (this.hasMainTarget) {
        if (mobile) {
          this.mainTarget.classList.add("hidden")
          this.mainTarget.classList.remove("flex")
        } else {
          this.mainTarget.classList.remove("hidden")
          this.mainTarget.classList.add("flex")
        }
      }
      if (this.hasExpandTriggerTarget) {
        this.expandTriggerTarget.classList.add("hidden")
      }
    }
  }
}
