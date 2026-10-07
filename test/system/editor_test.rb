require "application_system_test_case"

# Integration tests don't run JavaScript, so a broken Trix setup passes them.
# This drives the real editor.
class EditorTest < ApplicationSystemTestCase
  setup { @doc = documents(:alice_doc) }

  test "underline and H2 toolbar buttons work and survive reload" do
    sign_in_as users(:alice)
    visit edit_document_path(@doc)

    assert_selector 'trix-toolbar [data-trix-attribute="underline"]'
    assert_selector 'trix-toolbar [data-trix-attribute="heading2"]'

    find("trix-editor").click
    find("trix-editor").send_keys "Section"
    find('trix-toolbar [data-trix-attribute="heading2"]').click
    find("trix-editor").send_keys :enter
    find('trix-toolbar [data-trix-attribute="underline"]').click
    find("trix-editor").send_keys "underlined"
    click_button "Save"
    assert_text "Saved."

    visit edit_document_path(@doc)
    assert_selector "trix-editor h2", text: "Section"
    assert_selector "trix-editor u", text: "underlined"
  end

  test "viewer gets read-only rendering, not the editor" do
    sign_in_as users(:carol)
    @doc.shares.create!(user: users(:carol), role: "viewer")
    visit document_path(@doc)

    assert_selector ".badge-viewer"
    assert_no_selector "trix-editor"
  end
end
