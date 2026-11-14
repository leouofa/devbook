require "test_helper"

class PromptsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = Project.create!(name: "Alpha Project")
    @standalone_prompt = Prompt.create!(title: "Prompt A", body: "# Standalone Body")
    @project_prompt = Prompt.create!(project: @project, title: "Prompt AA", body: "# Assigned Body")
  end

  test "should get index with standalone scope by default" do
    get prompts_url
    assert_response :success
    assert_select "h1", text: /Standalone Prompts/
    assert_select "a", text: @standalone_prompt.title
  end

  test "should get index with all scope" do
    get prompts_url(scope: "all")
    assert_response :success
    assert_select "h1", text: /All Prompts/
    assert_select "a", text: @standalone_prompt.title
    assert_select "a", text: @project_prompt.title
  end

  test "should search prompts" do
    get prompts_url(q: "Assigned")
    assert_response :success
    assert_select "a", text: @project_prompt.title
  end

  test "should get show with rendered markdown" do
    get prompt_url(@standalone_prompt)
    assert_response :success
    assert_select "h1", text: @standalone_prompt.title
    assert_select "#rendered_markdown_container h1", text: "Standalone Body"
  end

  test "should get new" do
    get new_prompt_url
    assert_response :success
  end

  test "should create standalone prompt" do
    assert_difference("Prompt.count") do
      post prompts_url, params: { prompt: { title: "New Prompt", body: "Sample body" } }
    end

    new_prompt = Prompt.last
    assert_nil new_prompt.project_id
    assert_redirected_to prompt_url(new_prompt)
  end

  test "should create prompt assigned to project" do
    assert_difference("Prompt.count") do
      post prompts_url, params: { prompt: { title: "Assigned Prompt", body: "Body", project_id: @project.id } }
    end

    new_prompt = Prompt.last
    assert_equal @project.id, new_prompt.project_id
    assert_redirected_to prompt_url(new_prompt)
  end

  test "should update prompt via HTML" do
    patch prompt_url(@standalone_prompt), params: { prompt: { title: "Renamed Title", body: "Updated **markdown**" } }
    assert_redirected_to prompt_url(@standalone_prompt)
    assert_equal "Renamed Title", @standalone_prompt.reload.title
  end

  test "should update prompt via JSON for auto-save" do
    patch prompt_url(@standalone_prompt, format: :json), params: { prompt: { body: "Auto-saved content" } }
    assert_response :ok
    assert_equal "Auto-saved content", @standalone_prompt.reload.body
  end

  test "should attach files via ActiveStorage endpoint" do
    FileUtils.mkdir_p(Rails.root.join("test/fixtures/files"))
    File.write(Rails.root.join("test/fixtures/files/sample.txt"), "Sample prompt attachment content")
    file = fixture_file_upload("sample.txt", "text/plain")

    assert_difference("@standalone_prompt.files.count", 1) do
      post attach_files_prompt_url(@standalone_prompt), params: { files: [ file ] }
    end

    assert_redirected_to prompt_url(@standalone_prompt)
    assert_equal "sample.txt", @standalone_prompt.files.last.filename.to_s
  end

  test "should purge attachment" do
    FileUtils.mkdir_p(Rails.root.join("test/fixtures/files"))
    File.write(Rails.root.join("test/fixtures/files/sample.txt"), "Sample prompt attachment content")
    file = fixture_file_upload("sample.txt", "text/plain")
    @standalone_prompt.files.attach(file)
    attachment = @standalone_prompt.files.last

    assert_difference("@standalone_prompt.files.count", -1) do
      delete attachment_prompt_url(@standalone_prompt, attachment.id)
    end

    assert_redirected_to prompt_url(@standalone_prompt)
  end

  test "should destroy prompt" do
    assert_difference("Prompt.count", -1) do
      delete prompt_url(@standalone_prompt)
    end

    assert_redirected_to root_url
  end

  test "should toggle pin for prompt" do
    assert_not @standalone_prompt.pinned?
    patch toggle_pin_prompt_url(@standalone_prompt)
    assert_redirected_to prompt_url(@standalone_prompt)
    assert @standalone_prompt.reload.pinned?

    patch toggle_pin_prompt_url(@standalone_prompt, format: :json)
    assert_response :ok
    assert_not @standalone_prompt.reload.pinned?
  end

  test "should reorder pinned prompts" do
    p1 = Prompt.create!(title: "P1", pinned: true, pinned_position: 1)
    p2 = Prompt.create!(title: "P2", pinned: true, pinned_position: 2)

    patch reorder_pinned_prompts_url(format: :json), params: { prompt_ids: [ p2.id, p1.id ] }
    assert_response :ok

    assert_equal 1, p2.reload.pinned_position
    assert_equal 2, p1.reload.pinned_position
  end

  test "sidebar displays project names without nested prompts" do
    get prompts_url
    assert_response :success
    # Projects header and project name are present
    assert_select "span", text: "Projects"
    assert_select "span", text: @project.name
    # Project prompts are not nested in sidebar
    assert_select "nav a", text: /↳/, count: 0
  end

  test "sidebar displays clickable Standalone Prompts and Pinned Prompts" do
    @standalone_prompt.toggle_pin!
    get prompts_url
    assert_response :success

    assert_select "nav a[href=?]", prompts_path(scope: "standalone"), text: /Standalone Prompts/
    assert_select "span", text: "Pinned Prompts"
    assert_select "[data-controller='pinned-sortable'] a", text: @standalone_prompt.title
  end
end
