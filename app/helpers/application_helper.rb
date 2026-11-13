module ApplicationHelper
  def render_markdown(text)
    return "" if text.blank?

    renderer = Redcarpet::Render::HTML.new(
      filter_html: false,
      hard_wrap: true,
      link_attributes: { target: "_blank", rel: "noopener noreferrer" }
    )

    markdown = Redcarpet::Markdown.new(
      renderer,
      autolink: true,
      fenced_code_blocks: true,
      tables: true,
      strikethrough: true,
      space_after_headers: true,
      superscript: true,
      underline: true,
      highlight: true,
      no_intra_emphasis: true
    )

    # Sanitize allowed tags and attributes for safety while allowing rich markdown output
    sanitized = sanitize(
      markdown.render(text),
      tags: %w[
        h1 h2 h3 h4 h5 h6 p br hr ul ol li strong em b i s strike u del code pre
        blockquote table thead tbody tr th td a img mark
      ],
      attributes: %w[href src alt title target rel class id]
    )

    sanitized.html_safe
  end
end
