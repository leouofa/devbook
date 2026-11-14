require "test_helper"

class Api::V1::OpenapiControllerTest < ActionDispatch::IntegrationTest
  test "GET /api/v1/openapi returns valid OpenAPI 3.1 schema specification" do
    get api_v1_openapi_url
    assert_response :success
    assert_equal "application/json", response.media_type

    json = JSON.parse(response.body)
    assert_equal "3.1.0", json["openapi"]
    assert_equal "Devbook Platform API", json["info"]["title"]
    assert json["paths"].key?("/api/v1/projects")
    assert json["paths"].key?("/api/v1/prompts")
    assert json["paths"].key?("/api/v1/stats")
    assert json["paths"].key?("/api/v1/markdown/render")
  end
end
