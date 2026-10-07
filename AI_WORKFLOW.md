# AI workflow note

## Tools

- **Claude (claude.ai, agentic mode):** scoping, code generation, docs drafting
- **Local Rails toolchain:** generators, the test runner, the browser for manual checks
- **Claude Code (local CLI):** ran the overlay against the real Rails 8 skeleton, diagnosed and fixed the integration failures below, and drove headless Chrome for browser checks

## How I split the work

- **I made the product and architecture calls.** That covered the stack (Rails + ActionText, chosen over the AI's suggested Node/React/TipTap stack, to play to my strengths), the scope cuts, the role model and the deploy target.
- **AI produced first drafts of:** models, controllers, the importer service, views, the autosave Stimulus controller, the Trix extensions, the tests and these docs.
- **The skeleton came from Rails generators on my machine** (`rails new`, `action_text:install`, `generate authentication`). The AI's sandbox couldn't reach RubyGems, so it wrote code and I ran it locally and fed errors back.

## Where AI materially accelerated the work

- It wrote the whole permission layer and its integration tests in one pass, including the 404-not-403 decision and the owner-only share endpoints.
- It wrote the importer: .txt paragraphing, Markdown via Redcarpet, and .docx runs to HTML.
- It wrote the CSS and view layer, and drafted the README and architecture note.

## What I changed or rejected

- **Rejected:** the recommended Node + React + TipTap stack.
- **Fix log (integrating the overlay into the generated skeleton):**
  1. **`db:seed` crashed: `undefined method 'owned_documents' for User`.** `generate authentication` had overwritten `app/models/user.rb`. Restored the `owned_documents`, `document_shares` and `shared_documents` associations.
  2. **Migration order.** `create_documents` was timestamped before `create_users` but adds a foreign key to `users`. SQLite accepted that; Postgres on a fresh database would fail. Renamed it to `20261007124206_create_documents.rb` and regenerated `db/schema.rb`.
  3. **All 24 tests errored with fixture foreign-key violations.** The auth generator had also replaced `test/fixtures/users.yml` with `one`/`two`, so the `alice`/`bob`/`carol` fixtures the document fixtures and tests depend on were gone. Restored them.
  4. **`pg` was missing from the Gemfile** while `database.yml` uses `postgresql` in production, so the Render deploy would crash at boot. `bundle add pg --group production` crashed inside Bundler (because `without production` is set locally), so I added `gem "pg"` to a production group by hand and ran `bundle lock`.
  5. **Underline/H2 buttons never appeared.** `trix_extensions.js` lives in `controllers/` but isn't a `*_controller.js`, so Stimulus's eager loader never imported it. Added `import "controllers/trix_extensions"` to `application.js`.
  6. **Fixing 5 then broke the whole editor.** The `trix` importmap pin is a UMD build with no default export, so `import Trix from "trix"` was a SyntaxError that stopped the whole module graph, and `<trix-editor>` never initialized. Changed it to `import "trix"` plus `const Trix = window.Trix`. Caught via the headless-Chrome console, not by the test suite.
  7. **.docx import failed on ordinary Word files.** docx 0.13's `Paragraph#style` raises `NoMethodError` on any paragraph without `<w:pPr>`, and the importer's catch-all rescue turned that into "Couldn't read that .docx file". The importer now reads `w:pStyle` from the XML and resolves the display name safely (falling back to the style id). Added `test/fixtures/files/sample_report.docx` and a regression test, since the suite had no .docx coverage at all.
    8. **The editor page scrolled sideways (1968px wide at a 1400px window).** Rails' `f.text_field` with `maxlength: 200` also emits `size="200"`, and a flex item won't shrink below that intrinsic width. Added `min-width: 0` to `.title-input`. Found by measuring `scrollWidth` while taking screenshots.
  9. **The title input ignored its font.** `font: 600 1.5rem/1.3 inherit` is invalid (`inherit` isn't allowed inside the shorthand), so the browser dropped the whole declaration. Split it into longhand properties.
  10. **H1 rendered smaller than H2 in the editor.** ActionText's `.trix-content h1 { font-size: 1.2em }` out-ranked our `trix-editor h1` rule on specificity, but our H2 rule still applied. Scoped both rules to `trix-editor.trix-content`.
  11. **Added a system test** (`test/system/editor_test.rb`, headless Chrome) because the suite stayed green while fixes 5–6 had the editor broken. I confirmed it fails against the broken `trix_extensions.js` and passes on the fix. It runs with `bin/rails test:system`, separate from `bin/rails test`.
  - Checked and needed no change: the `<u>` sanitizer allowlist (`<u>` and `<h2>` survive save and render).

## How I verified correctness

- `bin/rails test` runs integration tests over the real HTTP flow for owner, editor, viewer and no-access users, plus import validation, and unit tests on the importer.
- `bin/rails test:system` drives the real editor in headless Chrome: the Underline and H2 buttons apply formatting that survives a reload, and a viewer gets the read-only page.
- Browser checks: Claude Code scripted these flows in headless Chrome (Capybara + Selenium) against the dev server, with 16/16 checks passing: Underline/H2 buttons present; H2 and underline survive autosave and reload; clicking the Underline button applies `<u>`; .docx import keeps h1/h2/bold/italic/underline; Bob (editor) gets the editor and sees Alice's edits but not the roadmap; Carol (viewer) gets the read-only view, `/edit` keeps her out of the editor, and she can't see the Welcome doc. The .docx used is a generated fixture with Word's heading styles and run formatting (`test/fixtures/files/sample_report.docx`), not a file saved from Microsoft Word. The screenshots in `screenshots/` come from the same run.
- What failed first time: fixes 5–10 above, all caught in the browser rather than by the test suite. The whole test suite passed while the editor was broken in the browser, because nothing in it executes JavaScript.
