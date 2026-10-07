# Architecture note

## Shape

A single Rails 8 monolith with server-rendered HTML, Hotwire (Turbo and Stimulus) and ActionText's Trix editor. One deployable unit with one database.

```
Browser ──Turbo/Stimulus──▶ Rails controllers ──▶ ActiveRecord ──▶ Postgres (prod) / SQLite (dev, test)
          Trix editor        Documents / Shares / Imports       users, sessions, documents,
          autosave (JSON)    DocumentImporter (service)         document_shares, action_text_rich_texts
```

## Data model

- `users` and `sessions` come from the Rails 8 authentication generator, using bcrypt passwords and a cookie session.
- `documents` holds `title` and `owner_id`. The body is an ActionText `has_rich_text :body`, stored as sanitized HTML.
- `document_shares` holds `document_id`, `user_id` and `role` (`editor` | `viewer`). A unique index on (document, user) means one grant per user. The owner is never stored as a share; ownership lives on the document.

## Access control

There's one scope, `Document.accessible_by(user)`, which returns owned documents plus shared ones, and every document lookup goes through it.

- A user with no access gets a **404, not a 403**, so a document's existence isn't revealed.
- `editable_by?` gates edit and update. Viewers are redirected to a read-only view.
- Sharing endpoints load the document through `Current.user.owned_documents`, so only owners can grant or revoke access.

The integration tests target this layer, because a bug here is the costliest kind for a document product.

## Key decisions and tradeoffs

| Decision | Why | Cost |
|---|---|---|
| Rails + ActionText over a JS SPA with TipTap | Persistence, sanitization and the editor are already integrated, which leaves time for sharing and tests | Trix has no underline or H2, so I added both through Trix config and widened the sanitizer allowlist for `<u>` |
| Real lightweight auth (Rails 8 generator) with seeded accounts | Sharing is meaningless without distinct identities. The generator is quick and secure by default | No sign-up flow. Reviewers use the seeded accounts |
| Share by exact email, with editor and viewer roles | Simplest model that still shows owner vs. shared and real permissions | No invites for people without an account, and no link sharing |
| Import creates a **new** document | Clear ownership and no merge semantics to design | You can't append a file into an existing document |
| Debounced autosave via JSON PATCH | Feels like a modern editor and reuses the same `update` action and validations | Last write wins, with no conflict detection |

## Intentionally deprioritized

- **Real-time co-editing and presence.** This needs Action Cable plus OT or CRDTs. It's the biggest and riskiest item, and it wasn't required.
- **Comments, version history, export.** These are stretch items. ActionText makes export and version snapshots straightforward next steps.
- **Concurrent-edit conflicts.** Two editors saving at once means the last write wins. The next step would be an `updated_at` precondition (optimistic locking) on autosave.
- **.docx fidelity.** Paragraphs, headings, bold, italic and underline carry over. Lists, tables and images are flattened.
- **File attachments inside documents.** Trix supports them through Active Storage, but Render's free disk is ephemeral, so production would need S3 or a similar store.

## What I'd do next

1. Add optimistic locking on autosave, with a "someone else edited this" prompt.
2. Add version snapshots on save, plus restore.
3. Move Active Storage to S3 for durable attachments.
4. Add an invite-by-email flow for people without an account.
