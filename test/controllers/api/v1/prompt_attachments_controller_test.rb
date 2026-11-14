require "test_helper"

class Api::V1::PromptAttachmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @prompt = Prompt.create!(title: "Attachment Prompt", body: "Sample body")
    FileUtils.mkdir_p(Rails.root.join("test/fixtures/files"))
    File.write(Rails.root.join("test/fixtures/files/sample.txt"), "Sample prompt attachment content")
  end

  test "GET /api/v1/prompts/:id/attachments lists attachments" do
    file = fixture_file_upload("sample.txt", "text/plain")
    @prompt.files.attach(file)

    get attachments_api_v1_prompt_url(@prompt), as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert json.key?("attachments")
    assert_equal 1, json["attachments"].size

    att = json["attachments"].first
    assert_equal "sample.txt", att["filename"]
    assert_equal "text/plain", att["content_type"]
    assert_not_nil att["url"]
  end

  test "POST /api/v1/prompts/:id/attachments attaches uploaded files" do
    file = fixture_file_upload("sample.txt", "text/plain")

    assert_difference("@prompt.files.count", 1) do
      post attachments_api_v1_prompt_url(@prompt), params: { files: [ file ] }
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "ok", json["status"]
    assert_equal 1, json["attachments"].size
    assert_equal "sample.txt", json["attachments"].first["filename"]
  end

  test "POST /api/v1/prompts/:id/attachments with no files returns 400" do
    post attachments_api_v1_prompt_url(@prompt), params: {}, as: :json
    assert_response :bad_request

    json = JSON.parse(response.body)
    assert_equal "No files provided for attachment", json["error"]
  end

  test "DELETE /api/v1/prompts/:id/attachments/:attachment_id purges attachment" do
    file = fixture_file_upload("sample.txt", "text/plain")
    @prompt.files.attach(file)
    attachment = @prompt.files.last

    assert_difference("@prompt.files.count", -1) do
      delete attachments_api_v1_prompt_url(@prompt) + "/#{attachment.id}", as: :json
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "ok", json["status"]
    assert_equal "Attachment removed successfully", json["message"]
  end
end
