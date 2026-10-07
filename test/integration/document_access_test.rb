require "test_helper"

# The core risk in this app is someone seeing or changing a document they
# shouldn't. These tests exercise the real HTTP flow for each role.
class DocumentAccessTest < ActionDispatch::IntegrationTest
  setup do
    @alice = users(:alice) # owner
    @bob = users(:bob)     # editor via fixture share
    @carol = users(:carol) # no access
    @doc = documents(:alice_doc)
  end

  test "owner can rename and edit, and rich-text formatting survives save" do
    sign_in @alice
    html = "<h2>Plan</h2><p><strong>bold</strong> <em>it</em> <u>under</u></p><ul><li>one</li></ul>"

    patch document_path(@doc), params: { document: { title: "Renamed", body: html } }

    assert_redirected_to edit_document_path(@doc)
    @doc.reload
    assert_equal "Renamed", @doc.title
    rendered = @doc.body.to_s
    %w[<h2>Plan</h2> <strong>bold</strong> <em>it</em> <u>under</u> <li>one</li>].each do |fragment|
      assert_includes rendered, fragment
    end
  end

  test "autosave JSON endpoint rejects a blank title" do
    sign_in @alice
    patch document_path(@doc), params: { document: { title: "" } }, as: :json
    assert_response :unprocessable_entity
    assert_equal "Alice's plan", @doc.reload.title
  end

  test "user without access gets 404 and cannot change the document" do
    sign_in @carol
    get document_path(@doc)
    assert_response :not_found

    patch document_path(@doc), params: { document: { title: "hacked" } }
    assert_response :not_found
    assert_equal "Alice's plan", @doc.reload.title
  end

  test "shared editor sees the doc under Shared with me and can edit it" do
    sign_in @bob
    get root_path
    assert_select "#shared-docs .doc-title", text: @doc.title
    assert_select "#owned-docs .doc-title", count: 0

    patch document_path(@doc), params: { document: { title: "Edited by Bob" } }
    assert_equal "Edited by Bob", @doc.reload.title
  end

  test "viewer can read but not edit" do
    @doc.shares.create!(user: @carol, role: "viewer")
    sign_in @carol

    get document_path(@doc)
    assert_response :success

    patch document_path(@doc), params: { document: { title: "nope" } }
    assert_redirected_to document_path(@doc)
    assert_equal "Alice's plan", @doc.reload.title
  end

  test "only the owner can share, and sharing grants access" do
    sign_in @bob
    post document_shares_path(@doc), params: { email_address: @carol.email_address, role: "editor" }
    assert_response :not_found

    sign_in @alice
    assert_difference -> { @doc.shares.count }, 1 do
      post document_shares_path(@doc), params: { email_address: "  CAROL@example.com ", role: "viewer" }
    end
    assert_equal "viewer", @doc.reload.role_for(@carol)
  end

  test "sharing with an unknown email or the owner is rejected" do
    sign_in @alice
    assert_no_difference -> { DocumentShare.count } do
      post document_shares_path(@doc), params: { email_address: "nobody@example.com" }
      post document_shares_path(@doc), params: { email_address: @alice.email_address }
    end
  end

  test "importing a markdown file creates an owned, formatted document" do
    sign_in @alice
    file = upload("# Heading\n\nSome **bold** text\n\n- a\n- b\n", "meeting-notes.md", "text/markdown")

    assert_difference -> { @alice.owned_documents.count }, 1 do
      post import_path, params: { file: file }
    end

    doc = @alice.owned_documents.order(:id).last
    assert_equal "meeting notes", doc.title
    assert_includes doc.body.to_s, "<strong>bold</strong>"
    assert_includes doc.body.to_s, "<li>a</li>"
  end

  test "unsupported file types are rejected with a clear message" do
    sign_in @alice
    assert_no_difference -> { Document.count } do
      post import_path, params: { file: upload("%PDF-1.4", "report.pdf", "application/pdf") }
    end
    follow_redirect!
    assert_match "Unsupported file type .pdf", response.body
  end

  private

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: "password" }
  end

  def upload(content, filename, content_type)
    Rack::Test::UploadedFile.new(StringIO.new(content), content_type, original_filename: filename)
  end
end
