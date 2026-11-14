require "application_system_test_case"

class SidebarTest < ApplicationSystemTestCase
  test "toggling sidebar with collapse and expand buttons" do
    visit root_url

    # Sidebar is visible initially
    assert_selector "aside[data-sidebar-target='sidebar']", visible: :visible
    assert_no_selector "div[data-sidebar-target='expandTrigger'] button", visible: :visible

    # Click collapse button
    find("button[aria-label='Collapse sidebar']").click

    # Sidebar is now collapsed
    assert_selector "aside[data-sidebar-target='sidebar']", visible: :hidden
    assert_selector "div[data-sidebar-target='expandTrigger'] button", visible: :visible

    # Click expand button
    find("button[aria-label='Expand sidebar']").click

    # Sidebar is restored
    assert_selector "aside[data-sidebar-target='sidebar']", visible: :visible
    assert_no_selector "div[data-sidebar-target='expandTrigger'] button", visible: :visible
  end

  test "toggling sidebar with Cmd+\\ / Ctrl+\\ keyboard shortcut" do
    visit root_url

    assert_selector "aside[data-sidebar-target='sidebar']", visible: :visible

    # Trigger Cmd+\
    page.execute_script("window.dispatchEvent(new KeyboardEvent('keydown', { key: '\\\\', metaKey: true, bubbles: true }))")

    # Should collapse
    assert_selector "aside[data-sidebar-target='sidebar']", visible: :hidden
    assert_selector "div[data-sidebar-target='expandTrigger'] button", visible: :visible

    # Trigger Ctrl+\
    page.execute_script("window.dispatchEvent(new KeyboardEvent('keydown', { key: '\\\\', ctrlKey: true, bubbles: true }))")

    # Should expand again
    assert_selector "aside[data-sidebar-target='sidebar']", visible: :visible
    assert_no_selector "div[data-sidebar-target='expandTrigger'] button", visible: :visible
  end

  test "persisting collapsed state across page reload via localStorage" do
    visit root_url

    find("button[aria-label='Collapse sidebar']").click
    assert_selector "aside[data-sidebar-target='sidebar']", visible: :hidden

    # Reload the page
    visit root_url

    # State persists as collapsed
    assert_selector "aside[data-sidebar-target='sidebar']", visible: :hidden
    assert_selector "div[data-sidebar-target='expandTrigger'] button", visible: :visible

    # Expand again
    find("button[aria-label='Expand sidebar']").click
    assert_selector "aside[data-sidebar-target='sidebar']", visible: :visible

    # Reload again
    visit root_url
    assert_selector "aside[data-sidebar-target='sidebar']", visible: :visible
  end
end
