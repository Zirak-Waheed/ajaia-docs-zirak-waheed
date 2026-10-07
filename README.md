# Ajaia Docs

A lightweight collaborative document editor built with Ruby on Rails 8 and ActionText.

**Live app:** _<Render URL>_

## Test accounts

All passwords are `password123`.

| Email | What to try |
|---|---|
| `alice@example.com` | Owns two documents, has shared one with Bob (editor) and one with Carol (viewer) |
| `bob@example.com` | Sees Alice's welcome doc under **Shared with me** and can edit it; owns a private draft |
| `carol@example.com` | Has view-only access to Alice's roadmap and gets read-only rendering |

## Features

- **Documents:** create, rename (inline title), edit, reopen, delete (owner only)
- **Rich text:** bold, italic, underline, H1/H2, bulleted and numbered lists, quote, link. Autosaves after 1s of inactivity, with a status indicator and a manual Save fallback.
- **File import:** `.txt`, `.md` and `.docx` (max 5 MB). Each one becomes a new editable document. Other types are rejected with a message.
- **Sharing:** the owner shares by email as **editor** or **viewer** and can revoke access. The dashboard splits **Owned by me** from **Shared with me**, and role badges appear on every row and in the document sidebar.
- **Persistence:** Postgres in production and SQLite locally. Formatting is stored as ActionText HTML.

## Run locally

Requirements: Ruby 3.2+ and Bundler. No database server is needed locally.

```bash
bundle config set --local without production
bundle install
bin/rails db:setup        # create, migrate, seed the three accounts
bin/rails server          # http://localhost:3000
```

## Tests

```bash
bin/rails test
```

- `test/integration/document_access_test.rb` drives the HTTP flow for each role:
  - owner edits and formatting persists
  - a user with no access gets a 404
  - an editor can edit and a viewer cannot
  - only the owner can share
  - import works and unsupported types are rejected
- `test/services/document_importer_test.rb` covers the conversion rules and input validation.

## Deploy (Render, free tier)

`render.yaml` defines the web service and a free Postgres database. In Render, choose **New → Blueprint**, point it at this repo, and apply. The build (`bin/render-build.sh`) installs gems, compiles assets, migrates and seeds.

See [ARCHITECTURE.md](ARCHITECTURE.md) and [AI_WORKFLOW.md](AI_WORKFLOW.md).
