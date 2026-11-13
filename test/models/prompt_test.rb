require "test_helper"

class PromptTest < ActiveSupport::TestCase
  test "validates presence of title" do
    prompt = Prompt.new(title: "")
    assert_not prompt.valid?
    assert_includes prompt.errors[:title], "can't be blank"

    prompt.title = "Valid Title"
    assert prompt.valid?
  end

  test "can be standalone without a project" do
    prompt = Prompt.create!(title: "Standalone Prompt", body: "# Standalone")
    assert_nil prompt.project
    assert_includes Prompt.standalone, prompt
  end

  test "search scope filters by title and body" do
    p1 = Prompt.create!(title: "Rails Optimization", body: "Use bullet for N+1 queries")
    p2 = Prompt.create!(title: "Python Tips", body: "List comprehensions are fast")

    assert_includes Prompt.search("Optimization"), p1
    assert_not_includes Prompt.search("Optimization"), p2

    assert_includes Prompt.search("bullet"), p1
    assert_not_includes Prompt.search("bullet"), p2
  end
end
