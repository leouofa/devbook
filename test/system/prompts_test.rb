require "application_system_test_case"

class PromptsTest < ApplicationSystemTestCase
  setup do
    @prompt = Prompt.create!(title: "System Test Prompt", body: "# Hello World\n\nThis is a system test prompt.")
  end

  test "visiting the index and viewing prompt" do
    visit root_url
    assert_selector "h1", text: "Standalone Prompts"
    assert_text "System Test Prompt"

    within "main" do
      click_on "System Test Prompt"
    end
    assert_selector "h1", text: "System Test Prompt"
    assert_text "Hello World"
  end

  test "creating a new prompt" do
    visit root_url
    within "main" do
      click_on "New Prompt"
    end

    fill_in "Prompt Title", with: "Created via System Test"
    fill_in "Markdown Content", with: "System test body content"
    click_on "Create Prompt"

    assert_text "Prompt created successfully."
    assert_text "Created via System Test"
  end

  test "clicking prompt card navigates to prompt details" do
    visit root_url
    find(".group.relative", text: "System Test Prompt").click
    assert_selector "h1", text: "System Test Prompt"
  end

  test "pinning and unpinning a prompt from card" do
    visit root_url
    assert_text "No pinned prompts yet."

    within "main" do
      click_on "Pin"
    end

    assert_text "Pinned"
    within "aside" do
      assert_text "System Test Prompt"
    end

    within "main" do
      click_on "Pinned"
    end

    within "aside" do
      assert_text "No pinned prompts yet."
    end
  end

  test "pin, copy, and toolbar buttons have pointer cursor" do
    visit root_url
    assert_equal "pointer", find("button", text: "Pin").native.css_value("cursor")
    assert_equal "pointer", find("button", text: "Copy").native.css_value("cursor")

    within "main" do
      click_on "System Test Prompt"
    end
    assert_selector "h1", text: "System Test Prompt"

    assert_equal "pointer", find("button", text: "Pin").native.css_value("cursor")
    assert_equal "pointer", find("button", text: "Copy Markdown").native.css_value("cursor")
    assert_equal "pointer", find("[data-markdown-editor-target='previewTab']").native.css_value("cursor")
    assert_equal "pointer", find("[data-markdown-editor-target='editTab']").native.css_value("cursor")
    assert_equal "pointer", find("[data-markdown-editor-target='splitTab']").native.css_value("cursor")
  end
end
