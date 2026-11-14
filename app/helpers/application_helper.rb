module ApplicationHelper
  def render_markdown(text)
    MarkdownRenderer.render(text)
  end
end
