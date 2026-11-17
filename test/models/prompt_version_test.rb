# frozen_string_literal: true

require "test_helper"

class PromptVersionTest < ActiveSupport::TestCase
  test "creating a prompt automatically creates initial v1 version" do
    prompt = Prompt.create!(title: "Initial Title", body: "Initial body content")

    assert_equal 1, prompt.versions.count
    assert_equal 1, prompt.current_version_number

    v1 = prompt.latest_version
    assert_equal 1, v1.version_number
    assert_equal "Initial Title", v1.title
    assert_equal "Initial body content", v1.body
    assert_not prompt.unversioned_changes?
  end

  test "updating title or body creates sequential versions" do
    prompt = Prompt.create!(title: "v1 Title", body: "v1 body")

    prompt.update!(body: "v2 body")
    assert_equal 2, prompt.versions.count
    assert_equal 2, prompt.current_version_number
    assert_equal "v2 body", prompt.latest_version.body

    prompt.update!(title: "v3 Title")
    assert_equal 3, prompt.versions.count
    assert_equal 3, prompt.current_version_number
    assert_equal "v3 Title", prompt.latest_version.title

    assert_equal [ 3, 2, 1 ], prompt.versions.ordered.pluck(:version_number)
  end

  test "updating non-content attributes like pinned or project_id does not create a version" do
    project = Project.create!(name: "Test Project")
    prompt = Prompt.create!(title: "Pin Test", body: "Body content")
    assert_equal 1, prompt.versions.count

    prompt.toggle_pin!
    assert_equal 1, prompt.versions.count

    prompt.update!(project: project)
    assert_equal 1, prompt.versions.count
  end

  test "skip_versioning prevents version creation on background auto-save until explicit snapshot" do
    prompt = Prompt.create!(title: "Draft Prompt", body: "Original text")
    assert_equal 1, prompt.versions.count

    prompt.skip_versioning = true
    prompt.update!(body: "Auto-saved draft 1")
    assert_equal 1, prompt.versions.count
    assert prompt.unversioned_changes?

    prompt.skip_versioning = true
    prompt.update!(body: "Auto-saved draft 2")
    assert_equal 1, prompt.versions.count

    # Explicit save (even with no new column change on this call) snapshots the accumulated draft
    prompt.skip_versioning = false
    prompt.record_version_snapshot!
    assert_equal 2, prompt.versions.count
    assert_equal "Auto-saved draft 2", prompt.latest_version.body
    assert_not prompt.unversioned_changes?
  end

  test "restore_version! non-destructively restores a previous version as a new version" do
    prompt = Prompt.create!(title: "Original Title", body: "Line 1")
    v1 = prompt.latest_version

    prompt.update!(title: "Modified Title", body: "Line 1\nLine 2")
    assert_equal 2, prompt.current_version_number

    prompt.restore_version!(v1)
    prompt.reload

    assert_equal 3, prompt.current_version_number
    assert_equal "Original Title", prompt.title
    assert_equal "Line 1", prompt.body
    assert_equal "Original Title", prompt.latest_version.title
    assert_equal "Line 1", prompt.latest_version.body
  end

  test "restore_version! preserves unversioned auto-saved changes before restoring" do
    prompt = Prompt.create!(title: "v1", body: "First")
    v1 = prompt.latest_version

    prompt.skip_versioning = true
    prompt.update!(body: "Unversioned auto-saved work")
    assert_equal 1, prompt.versions.count

    prompt.restore_version!(v1)
    prompt.reload

    # v2 snapshots the unversioned draft, v3 is the restored v1
    assert_equal 3, prompt.versions.count
    assert_equal "Unversioned auto-saved work", prompt.versions.find_by(version_number: 2).body
    assert_equal "First", prompt.versions.find_by(version_number: 3).body
  end
end
