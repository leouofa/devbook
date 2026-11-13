import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "area", "preview", "status"]
  static values = {
    uploadUrl: String
  }

  connect() {
    this.boundPreventDefaults = this.preventDefaults.bind(this)
    ;["dragenter", "dragover", "dragleave", "drop"].forEach(eventName => {
      this.areaTarget.addEventListener(eventName, this.boundPreventDefaults, false)
    })
  }

  disconnect() {
    ;["dragenter", "dragover", "dragleave", "drop"].forEach(eventName => {
      this.areaTarget.removeEventListener(eventName, this.boundPreventDefaults, false)
    })
  }

  preventDefaults(e) {
    e.preventDefault()
    e.stopPropagation()
  }

  dragOver() {
    this.areaTarget.classList.add("border-cyan-500", "bg-cyan-500/10", "ring-2", "ring-cyan-500/20")
  }

  dragLeave() {
    this.areaTarget.classList.remove("border-cyan-500", "bg-cyan-500/10", "ring-2", "ring-cyan-500/20")
  }

  drop(e) {
    this.dragLeave()
    const dt = e.dataTransfer
    const files = dt.files

    if (!files || files.length === 0) return

    if (this.hasUploadUrlValue && this.uploadUrlValue.length > 0) {
      this.uploadFiles(files)
    } else {
      this.stageFilesLocally(files)
    }
  }

  fileChosen(e) {
    const files = e.target.files
    if (!files || files.length === 0) return

    if (this.hasUploadUrlValue && this.uploadUrlValue.length > 0) {
      this.uploadFiles(files)
    } else {
      this.stageFilesLocally(files)
    }
  }

  stageFilesLocally(files) {
    // Used on "new prompt" form where prompt doesn't have an ID yet
    if (this.hasInputTarget) {
      const dt = new DataTransfer()
      Array.from(files).forEach(file => dt.items.add(file))
      this.inputTarget.files = dt.files
    }

    if (this.hasPreviewTarget) {
      this.previewTarget.innerHTML = ""
      Array.from(files).forEach(file => {
        const item = document.createElement("div")
        item.className = "flex items-center gap-2 text-xs text-neutral-300 bg-neutral-800/80 px-2.5 py-1.5 rounded border border-neutral-700/60"
        item.innerHTML = `
          <svg class="w-3.5 h-3.5 text-neutral-400 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13" />
          </svg>
          <span class="truncate font-mono">${file.name}</span>
          <span class="text-neutral-500 ml-auto shrink-0 font-mono">${this.formatBytes(file.size)}</span>
        `
        this.previewTarget.appendChild(item)
      })
      this.previewTarget.classList.remove("hidden")
    }
  }

  async uploadFiles(files) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = `Uploading ${files.length} file(s)...`
      this.statusTarget.className = "text-xs font-mono text-cyan-400 animate-pulse mt-2"
    }

    const formData = new FormData()
    Array.from(files).forEach(file => {
      formData.append("files[]", file)
    })

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content")

    try {
      const response = await fetch(this.uploadUrlValue, {
        method: "POST",
        headers: {
          "Accept": "text/vnd.turbo-stream.html, text/html",
          "X-CSRF-Token": csrfToken
        },
        body: formData
      })

      if (response.ok) {
        const html = await response.text()
        if (window.Turbo) {
          window.Turbo.renderStreamMessage(html)
        }
        if (this.hasStatusTarget) {
          this.statusTarget.textContent = "Upload complete!"
          this.statusTarget.className = "text-xs font-mono text-emerald-400 mt-2"
          setTimeout(() => {
            this.statusTarget.textContent = ""
          }, 3000)
        }
      } else {
        throw new Error("Upload failed")
      }
    } catch (err) {
      console.error("Dropzone upload failed", err)
      if (this.hasStatusTarget) {
        this.statusTarget.textContent = "Upload failed. Please try again."
        this.statusTarget.className = "text-xs font-mono text-rose-400 mt-2"
      }
    } finally {
      if (this.hasInputTarget) {
        this.inputTarget.value = ""
      }
    }
  }

  formatBytes(bytes) {
    if (bytes === 0) return "0 B"
    const k = 1024
    const sizes = ["B", "KB", "MB", "GB"]
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + " " + sizes[i]
  }
}
