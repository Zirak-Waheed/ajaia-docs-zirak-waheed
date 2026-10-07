# AI workflow note

> DRAFT. Edit this into your own words and correct anything that doesn't match what you did.

## Tools

- **Claude (claude.ai, agentic mode):** scoping, code generation, docs drafting
- **Local Rails toolchain:** generators, the test runner, the browser for manual checks
- _Add Claude Code or Cursor here if you used them locally._

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
- _Fill in from your log: errors you hit and fixes you made, anything you rewrote, anything you removed._

## How I verified correctness

- `bin/rails test` runs integration tests over the real HTTP flow for owner, editor, viewer and no-access users, plus import validation, and unit tests on the importer.
- I checked by hand, logged in as each seeded user:
  - refresh persistence
  - every formatting button surviving reload
  - .docx import with a real Word file
  - the Shared with me split
  - the viewer redirect
- _Note anything that failed first time and how you caught it._
