# Converts an uploaded .txt / .md / .docx file into HTML that Trix/ActionText can edit.
class DocumentImporter
  class Error < StandardError; end

  Result = Struct.new(:title, :html)

  SUPPORTED_EXTENSIONS = %w[.txt .md .markdown .docx].freeze
  MAX_BYTES = 5.megabytes

  def self.call(file) = new(file).call

  def initialize(file)
    @file = file
  end

  def call
    raise Error, "Choose a file to upload." unless @file.respond_to?(:original_filename)

    ext = File.extname(@file.original_filename.to_s).downcase
    unless SUPPORTED_EXTENSIONS.include?(ext)
      raise Error, "Unsupported file type #{ext.presence || '(no extension)'}. Supported: .txt, .md, .docx."
    end
    raise Error, "That file is empty." if @file.size.zero?
    raise Error, "That file is too large (max 5 MB)." if @file.size > MAX_BYTES

    html =
      case ext
      when ".txt" then from_text(read_utf8)
      when ".md", ".markdown" then from_markdown(read_utf8)
      when ".docx" then from_docx
      end

    Result.new(title, html)
  end

  private

  def title
    File.basename(@file.original_filename, ".*").tr("_-", "  ").squish.first(200).presence || "Imported document"
  end

  def read_utf8
    text = @file.read.dup.force_encoding(Encoding::UTF_8)
    raise Error, "That file isn't valid UTF-8 text." unless text.valid_encoding?
    text.delete_prefix("﻿")
  end

  # Blank lines separate paragraphs; single newlines become <br>.
  def from_text(text)
    text.split(/\r?\n\s*\r?\n/).reject(&:blank?).map do |para|
      "<p>#{ERB::Util.html_escape(para.strip).gsub(/\r?\n/, '<br>')}</p>"
    end.join
  end

  def from_markdown(text)
    renderer = Redcarpet::Render::HTML.new(escape_html: true)
    Redcarpet::Markdown.new(renderer, strikethrough: true, autolink: true, no_intra_emphasis: true).render(text)
  end

  # Keeps paragraphs, headings, bold, italic and underline. Lists, tables and
  # images in .docx are flattened to paragraphs (documented limitation).
  def from_docx
    doc = Docx::Document.open(@file.path)
    doc.paragraphs.filter_map do |para|
      inner = para.text_runs.map { |run| run_html(run) }.join
      next if inner.strip.empty?

      tag = heading_tag(doc, para)
      "<#{tag}>#{inner}</#{tag}>"
    end.join
  rescue Error
    raise
  rescue StandardError
    raise Error, "Couldn't read that .docx file. Is it a valid Word document?"
  end

  # Reads w:pStyle directly: docx 0.13's Paragraph#style raises on paragraphs
  # without a <w:pPr>, which plain Word paragraphs often lack.
  def heading_tag(doc, para)
    style_id = para.node.at_xpath("w:pPr/w:pStyle")&.get_attribute("w:val").to_s
    return "p" if style_id.empty?

    case style_name(doc, style_id)
    when /\A(title|heading ?1)\z/i then "h1"
    when /\Aheading ?[2-6]\z/i then "h2"
    else "p"
    end
  end

  # Word stores ids like "Heading1" and display names like "heading 1"; fall
  # back to the id when styles.xml is missing or doesn't define it.
  def style_name(doc, style_id)
    doc.style_name_of(style_id) || style_id
  rescue StandardError
    style_id
  end

  def run_html(run)
    html = ERB::Util.html_escape(run.text.to_s)
    formatting = run.respond_to?(:formatting) ? (run.formatting || {}) : {}
    html = "<u>#{html}</u>" if formatting[:underline]
    html = "<em>#{html}</em>" if formatting[:italic]
    html = "<strong>#{html}</strong>" if formatting[:bold]
    html
  end
end
