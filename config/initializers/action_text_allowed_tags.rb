# ActionText's default sanitizer strips <u>. Allow it so underline survives save + render.
Rails.application.config.after_initialize do
  ActionText::ContentHelper.allowed_tags =
    Rails::HTML::Sanitizer.safe_list_sanitizer.allowed_tags.to_a +
    [ ActionText::Attachment.tag_name, "figure", "figcaption", "u" ]
end
