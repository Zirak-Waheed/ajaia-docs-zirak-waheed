require "test_helper"

class DocumentImporterTest < ActiveSupport::TestCase
  test "plain text: blank lines become paragraphs and HTML is escaped" do
    result = DocumentImporter.call(upload("Hello <script>x</script>\n\nSecond line", "notes_v2.txt"))
    assert_equal "notes v2", result.title
    assert_equal "<p>Hello &lt;script&gt;x&lt;/script&gt;</p><p>Second line</p>", result.html
  end

  test "markdown headings and emphasis convert to HTML" do
    html = DocumentImporter.call(upload("## Title\n\n*it* and **b**", "a.md")).html
    assert_includes html, "<h2>Title</h2>"
    assert_includes html, "<em>it</em>"
    assert_includes html, "<strong>b</strong>"
  end

  test "rejects empty files, unsupported types and invalid UTF-8" do
    assert_raises(DocumentImporter::Error) { DocumentImporter.call(upload("", "empty.txt")) }
    assert_raises(DocumentImporter::Error) { DocumentImporter.call(upload("x", "image.png")) }
    assert_raises(DocumentImporter::Error) { DocumentImporter.call(upload("\xFF\xFE\xFA".b, "bad.txt")) }
    assert_raises(DocumentImporter::Error) { DocumentImporter.call(nil) }
  end

  test "docx keeps headings and run formatting, including unstyled paragraphs" do
    file = Rack::Test::UploadedFile.new(file_fixture("sample_report.docx"))
    result = DocumentImporter.call(file)
    assert_equal "sample report", result.title
    assert_equal "<h1>Big title</h1><h2>Sub</h2>" \
                 "<p><strong>bold</strong> and <u>under</u><em> ital &lt;x&gt;</em></p>", result.html
  end

  private

  def upload(content, filename)
    Rack::Test::UploadedFile.new(StringIO.new(content), "application/octet-stream", original_filename: filename)
  end
end
