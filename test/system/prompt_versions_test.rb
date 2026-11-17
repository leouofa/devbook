# frozen_string_literal: true

require "application_system_test_case"

class PromptVersionsTest < ApplicationSystemTestCase
  setup do
    @prompt = Prompt.create!(title: "Versioned Prompt v1", body: "First version content")
    @prompt.update!(title: "Versioned Prompt v2", body: "Second version content")
  end

  test "viewing version history, inspecting diffs, and restoring a previous version" do
    visit prompt_url(@prompt)
    assert_text "History (v2)"

    click_on "History (v2)"
    assert_selector "h1", text: "Version History"
    assert_text "2 versions"
    assert_text "+1"
    assert_text "-1"
    assert_text "Second version content"

    # Click on v1 in timeline
    find("#version_item_1").click
    assert_text "First version content"
    assert_button "Restore v1"

    accept_confirm do
      click_on "Restore v1"
    end

    assert_text "Restored prompt to v1 (saved as v3)."
    assert_selector "h1", text: "Versioned Prompt v1"
    assert_text "History (v3)"
    assert_text "First version content"
  end
end
