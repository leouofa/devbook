# frozen_string_literal: true

require "test_helper"

class PromptVersionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @prompt = Prompt.create!(title: "Architecture v1", body: "# Heading\nInitial line")
    @v1 = @prompt.latest_version
    @prompt.update!(title: "Architecture v2", body: "# Heading\nUpdated line\nExtra line")
    @v2 = @prompt.latest_version
  end

  test "should get versions index and show latest version diff by default" do
    get prompt_versions_url(@prompt)
    assert_response :success
    assert_select "h1", text: /Version History/
    assert_select "#version_timeline a", count: 2
    assert_select "#version_diff_container", text: /Updated line/
    assert_select "#title_diff_banner", text: /Architecture v1/
  end

  test "should get specific version in diff, rendered, and raw modes" do
    get prompt_version_url(@prompt, @v1, view: "rendered")
    assert_response :success
    assert_select "#version_rendered_container h1", text: "Heading"

    get prompt_version_url(@prompt, @v1, view: "raw")
    assert_response :success
    assert_select "#version_raw_container pre", text: /Initial line/
  end

  test "should restore previous version and create a new version" do
    assert_difference("@prompt.versions.count", 1) do
      post restore_prompt_version_url(@prompt, @v1)
    end

    assert_redirected_to prompt_url(@prompt)
    @prompt.reload
    assert_equal 3, @prompt.current_version_number
    assert_equal "Architecture v1", @prompt.title
    assert_equal "# Heading\nInitial line", @prompt.body
  end

  test "background auto_save updates prompt without creating a version while explicit update creates a version" do
    assert_no_difference("@prompt.versions.count") do
      patch prompt_url(@prompt, format: :json), params: {
        auto_save: "1",
        prompt: { body: "Auto-saved body change" }
      }
    end
    assert_response :ok
    assert_equal "Auto-saved body change", @prompt.reload.body

    # Explicit save (auto_save: "0") commits the auto-saved draft as a new version
    assert_difference("@prompt.versions.count", 1) do
      patch prompt_url(@prompt, format: :json), params: {
        auto_save: "0",
        prompt: { body: "Auto-saved body change" }
      }
    end
    assert_response :ok
    assert_equal 3, @prompt.reload.current_version_number
  end
end
