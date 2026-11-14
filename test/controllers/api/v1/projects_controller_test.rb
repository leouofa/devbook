require "test_helper"

class Api::V1::ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = Project.create!(name: "Test Project", description: "Sample description")
    @prompt = Prompt.create!(project: @project, title: "Associated Prompt", body: "Hello world")
  end

  test "GET /api/v1/projects lists projects with pagination and prompt counts" do
    get api_v1_projects_url, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert json.key?("projects")
    assert json.key?("meta")
    assert_equal 1, json["meta"]["total_count"]

    item = json["projects"].find { |p| p["id"] == @project.id }
    assert_not_nil item
    assert_equal "Test Project", item["name"]
    assert_equal 1, item["prompts_count"]
  end

  test "GET /api/v1/projects filters with search query" do
    Project.create!(name: "Other Alpha", description: "Unrelated")

    get api_v1_projects_url, params: { q: "Alpha" }, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 1, json["projects"].size
    assert_equal "Other Alpha", json["projects"].first["name"]
  end

  test "GET /api/v1/projects/:id returns project details with associated prompts" do
    get api_v1_project_url(@project), as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal @project.id, json["id"]
    assert_equal "Test Project", json["name"]
    assert_equal "Sample description", json["description"]
    assert_equal 1, json["prompts"].size
    assert_equal @prompt.title, json["prompts"].first["title"]
  end

  test "GET /api/v1/projects/:id returns 404 for unknown project" do
    get api_v1_project_url(id: 999999), as: :json
    assert_response :not_found

    json = JSON.parse(response.body)
    assert_equal "Resource not found", json["error"]
  end

  test "POST /api/v1/projects creates project" do
    assert_difference("Project.count", 1) do
      post api_v1_projects_url, params: { project: { name: "Created Project", description: "A new project" } }, as: :json
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "Created Project", json["name"]
    assert_equal "A new project", json["description"]
    assert_equal 0, json["prompts_count"]
  end

  test "POST /api/v1/projects with invalid parameters returns 422" do
    assert_no_difference("Project.count") do
      post api_v1_projects_url, params: { project: { name: "" } }, as: :json
    end

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_equal "Validation failed", json["error"]
    assert_includes json["details"], "Name can't be blank"
  end

  test "PATCH /api/v1/projects/:id updates project" do
    patch api_v1_project_url(@project), params: { project: { name: "Renamed Project" } }, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal "Renamed Project", json["name"]
    assert_equal "Renamed Project", @project.reload.name
  end

  test "DELETE /api/v1/projects/:id deletes project and nullifies prompts" do
    assert_difference("Project.count", -1) do
      delete api_v1_project_url(@project), as: :json
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "ok", json["status"]
    assert_nil @prompt.reload.project_id
  end
end
