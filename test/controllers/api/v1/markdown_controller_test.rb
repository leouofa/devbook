require "test_helper"

class Api::V1::MarkdownControllerTest < ActionDispatch::IntegrationTest
  test "POST /api/v1/markdown/render renders markdown text to sanitized HTML" do
    markdown_input = "# Heading 1\n\n- item A\n- item B\n\n**bold** and `code`\n<script>alert('xss')</script>"

    post api_v1_markdown_render_url, params: { text: markdown_input }, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert json.key?("html")
    assert_includes json["html"], "<h1>Heading 1</h1>"
    assert_includes json["html"], "<li>item A</li>"
    assert_includes json["html"], "<strong>bold</strong>"
    assert_includes json["html"], "<code>code</code>"
    refute_includes json["html"], "<script>"
  end

  test "POST /api/v1/markdown/render handles empty or blank string gracefully" do
    post api_v1_markdown_render_url, params: { text: "" }, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal "", json["html"]
  end
end
