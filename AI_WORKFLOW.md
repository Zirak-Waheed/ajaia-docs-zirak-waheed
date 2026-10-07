# AI workflow note

> DRAFT. Edit this into your own words and correct anything that doesn't match what you did.

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
  - Checked and needed no change: the `<u>` sanitizer allowlist (`<u>` and `<h2>` survive save and render).

## How I verified correctness

- `bin/rails test` runs integration tests over the real HTTP flow for owner, editor, viewer and no-access users, plus import validation, and unit tests on the importer.
- I checked by hand, logged in as each seeded user:
  - refresh persistence
  - every formatting button surviving reload
  - .docx import with a real Word file
  - the Shared with me split
  - the viewer redirect
- Claude Code also scripted those flows in headless Chrome (Capybara + Selenium) against the dev server, with 16/16 checks passing: Underline/H2 buttons present; H2 and underline survive autosave and reload; clicking the Underline button applies `<u>`; .docx import keeps h1/h2/bold/italic/underline; Bob (editor) gets the editor and sees Alice's edits but not the roadmap; Carol (viewer) gets the read-only view, `/edit` keeps her out of the editor, and she can't see the Welcome doc.
- What failed first time: fixes 5 and 6 above. The whole test suite passed while the editor was broken in the browser, because nothing in it executes JavaScript.
