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
end
