# frozen_string_literal: true

require "test_helper"

class PromptDifferTest < ActiveSupport::TestCase
  test "computes line-by-line additions, deletions, and unchanged lines" do
    old_text = "alpha\nbeta\ngamma"
    new_text = "alpha\nbeta modified\ngamma\ndelta"

    diff = PromptDiffer.call(old_text, new_text, old_title: "Title A", new_title: "Title B")

    assert diff[:title_changed]
    assert_equal "Title A", diff[:old_title]
    assert_equal "Title B", diff[:new_title]

    assert_equal 2, diff[:stats][:additions]
    assert_equal 1, diff[:stats][:deletions]
    assert_equal 2, diff[:stats][:unchanged]

    types = diff[:lines].map { |l| [ l[:type], l[:content] ] }
    assert_includes types, [ :unchanged, "alpha" ]
    assert_includes types, [ :removed, "beta" ]
    assert_includes types, [ :added, "beta modified" ]
    assert_includes types, [ :unchanged, "gamma" ]
    assert_includes types, [ :added, "delta" ]
  end

  test "handles empty old_text for initial version diff" do
    diff = PromptDiffer.call("", "line 1\nline 2", old_title: nil, new_title: "First")

    assert_not diff[:title_changed]
    assert_equal 2, diff[:stats][:additions]
    assert_equal 0, diff[:stats][:deletions]
  end
end
