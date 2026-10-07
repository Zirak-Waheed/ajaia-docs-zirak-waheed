# Idempotent: safe to run on every deploy.
PASSWORD = "password123"

alice = User.find_or_create_by!(email_address: "alice@example.com") { |u| u.password = PASSWORD }
bob   = User.find_or_create_by!(email_address: "bob@example.com")   { |u| u.password = PASSWORD }
carol = User.find_or_create_by!(email_address: "carol@example.com") { |u| u.password = PASSWORD }

unless alice.owned_documents.exists?
  welcome = alice.owned_documents.create!(
    title: "Welcome to Ajaia Docs",
    body: <<~HTML
      <h1>Welcome</h1>
      <p>This document is owned by <strong>Alice</strong> and shared with <em>Bob</em> as an editor.</p>
      <h2>Try the formatting</h2>
      <ul><li><strong>Bold</strong>, <em>italic</em> and <u>underline</u></li><li>Headings and lists</li></ul>
      <ol><li>Edit this text</li><li>Refresh the page: changes and formatting persist</li></ol>
    HTML
  )
  welcome.shares.create!(user: bob, role: "editor")

  roadmap = alice.owned_documents.create!(
    title: "Q4 roadmap (Carol can view only)",
    body: "<h1>Q4 roadmap</h1><p>Carol has <strong>view-only</strong> access to this document.</p>"
  )
  roadmap.shares.create!(user: carol, role: "viewer")

  bob.owned_documents.create!(
    title: "Bob's private draft",
    body: "<p>Only Bob can see this until he shares it.</p>"
  )
end
