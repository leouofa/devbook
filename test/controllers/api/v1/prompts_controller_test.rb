require "test_helper"

class Api::V1::PromptsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = Project.create!(name: "API Studio")
    @standalone_prompt = Prompt.create!(title: "Standalone Prompt", body: "# Markdown Header\nSome *content*")
    @assigned_prompt = Prompt.create!(project: @project, title: "Assigned Prompt", body: "Assigned prompt body")
    @pinned_prompt = Prompt.create!(title: "Pinned Prompt", body: "Important content", pinned: true, pinned_position: 1)
  end

  test "GET /api/v1/prompts lists all prompts" do
    get api_v1_prompts_url, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert json.key?("prompts")
    assert json.key?("meta")
    assert_equal 3, json["meta"]["total_count"]
    titles = json["prompts"].map { |p| p["title"] }
    assert_includes titles, @standalone_prompt.title
    assert_includes titles, @assigned_prompt.title
    assert_includes titles, @pinned_prompt.title
  end

  test "GET /api/v1/prompts filters by project_id" do
    get api_v1_prompts_url, params: { project_id: @project.id }, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 1, json["prompts"].size
    assert_equal @assigned_prompt.title, json["prompts"].first["title"]
  end

  test "GET /api/v1/prompts filters by standalone scope" do
    get api_v1_prompts_url, params: { scope: "standalone" }, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    titles = json["prompts"].map { |p| p["title"] }
    assert_includes titles, @standalone_prompt.title
    assert_includes titles, @pinned_prompt.title
    refute_includes titles, @assigned_prompt.title
  end

  test "GET /api/v1/prompts filters by pinned state" do
    get api_v1_prompts_url, params: { pinned: "true" }, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 1, json["prompts"].size
    assert_equal @pinned_prompt.title, json["prompts"].first["title"]
  end

  test "GET /api/v1/prompts searches by keyword" do
    get api_v1_prompts_url, params: { q: "Markdown" }, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 1, json["prompts"].size
    assert_equal @standalone_prompt.title, json["prompts"].first["title"]
  end

  test "GET /api/v1/prompts/:id returns prompt details and attachments" do
    get api_v1_prompt_url(@standalone_prompt), as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal @standalone_prompt.id, json["id"]
    assert_equal "Standalone Prompt", json["title"]
    assert_equal @standalone_prompt.body, json["body"]
    assert json.key?("attachments")
    assert_equal 0, json["attachments"].size
  end

  test "GET /api/v1/prompts/:id with render_markdown=true includes rendered_html" do
    get api_v1_prompt_url(@standalone_prompt), params: { render_markdown: "true" }, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert json.key?("rendered_html")
    assert_includes json["rendered_html"], "<h1>Markdown Header</h1>"
    assert_includes json["rendered_html"], "<em>content</em>"
  end

  test "POST /api/v1/prompts creates a prompt" do
    assert_difference("Prompt.count", 1) do
      post api_v1_prompts_url, params: {
        prompt: {
          title: "New API Prompt",
          body: "Prompt contents here",
          project_id: @project.id,
          pinned: false
        }
      }, as: :json
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "New API Prompt", json["title"]
    assert_equal "Prompt contents here", json["body"]
    assert_equal @project.id, json["project_id"]
    assert_equal "API Studio", json["project_name"]
  end

  test "POST /api/v1/prompts with invalid params returns 422" do
    assert_no_difference("Prompt.count") do
      post api_v1_prompts_url, params: { prompt: { title: "" } }, as: :json
    end

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_equal "Validation failed", json["error"]
    assert_includes json["details"], "Title can't be blank"
  end

  test "PATCH /api/v1/prompts/:id updates prompt" do
    patch api_v1_prompt_url(@standalone_prompt), params: {
      prompt: {
        title: "Updated Title",
        body: "Updated Body"
      }
    }, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Updated Title", json["title"]
    assert_equal "Updated Body", json["body"]
    assert_equal "Updated Title", @standalone_prompt.reload.title
  end

  test "DELETE /api/v1/prompts/:id deletes prompt" do
    assert_difference("Prompt.count", -1) do
      delete api_v1_prompt_url(@standalone_prompt), as: :json
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "ok", json["status"]
  end

  test "PATCH /api/v1/prompts/:id/toggle_pin toggles pin state" do
    # Currently unpinned -> should become pinned
    patch toggle_pin_api_v1_prompt_url(@standalone_prompt), as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal true, json["pinned"]
    assert_not_nil json["pinned_position"]
    assert @standalone_prompt.reload.pinned?

    # Toggle again -> should become unpinned
    patch toggle_pin_api_v1_prompt_url(@standalone_prompt), as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal false, json["pinned"]
    assert_nil json["pinned_position"]
    refute @standalone_prompt.reload.pinned?
  end

  test "PATCH /api/v1/prompts/reorder_pinned reorders pinned prompts" do
    prompt2 = Prompt.create!(title: "Second Pinned", pinned: true, pinned_position: 2)

    patch reorder_pinned_api_v1_prompts_url, params: { prompt_ids: [ prompt2.id, @pinned_prompt.id ] }, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal "ok", json["status"]
    assert_equal 1, prompt2.reload.pinned_position
    assert_equal 2, @pinned_prompt.reload.pinned_position
  end
end
