import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "label", "icon", "source"]
  static values = {
    content: String,
    successMessage: { type: String, default: "Copied!" },
    timeout: { type: Number, default: 2000 }
  }

  copy(event) {
    if (event) event.preventDefault()

    let textToCopy = this.hasContentValue ? this.contentValue : ""
    if (!textToCopy && this.hasSourceTarget) {
      textToCopy = this.sourceTarget.value || this.sourceTarget.innerText || this.sourceTarget.textContent
    }

    if (!textToCopy) return

    navigator.clipboard.writeText(textToCopy).then(() => {
      this.showCopiedState()
    }).catch(err => {
      console.error("Failed to copy text: ", err)
    })
  }

  showCopiedState() {
    const originalLabel = this.hasLabelTarget ? this.labelTarget.textContent : null
    const originalClass = this.hasButtonTarget ? this.buttonTarget.className : null

    if (this.hasLabelTarget) {
      this.labelTarget.textContent = this.successMessageValue
    }
    if (this.hasButtonTarget) {
      this.buttonTarget.classList.add("text-emerald-400", "border-emerald-500/50", "bg-emerald-500/10")
    }

    setTimeout(() => {
      if (this.hasLabelTarget && originalLabel !== null) {
        this.labelTarget.textContent = originalLabel
      }
      if (this.hasButtonTarget) {
        this.buttonTarget.classList.remove("text-emerald-400", "border-emerald-500/50", "bg-emerald-500/10")
      }
    }, this.timeoutValue)
  }
}
