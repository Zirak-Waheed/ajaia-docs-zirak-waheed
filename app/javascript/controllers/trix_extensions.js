// Adds Underline and Heading 2 to Trix (ActionText's editor ships with neither).
// Trix registers its custom elements on a setTimeout, so config set here applies
// before any editor loads its saved HTML.
import Trix from "trix"

Trix.config.textAttributes.underline = { tagName: "u", inheritable: true }
Trix.config.blockAttributes.heading2 = { tagName: "h2", terminal: true, breakOnReturn: true, group: false }

addEventListener("trix-initialize", (event) => {
  const toolbar = event.target.toolbarElement
  if (!toolbar || toolbar.querySelector('[data-trix-attribute="underline"]')) return

  toolbar.querySelector('[data-trix-attribute="italic"]')?.insertAdjacentHTML(
    "afterend",
    '<button type="button" class="trix-button trix-button--text" data-trix-attribute="underline" data-trix-key="u" title="Underline (Ctrl+U)" tabindex="-1"><u>U</u></button>'
  )
  toolbar.querySelector('[data-trix-attribute="heading1"]')?.insertAdjacentHTML(
    "afterend",
    '<button type="button" class="trix-button trix-button--text" data-trix-attribute="heading2" title="Heading 2" tabindex="-1">H2</button>'
  )
})
