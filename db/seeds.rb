# Devbook Seeds matching the mind map:
# Projects -> Project A -> Prompt AA, Prompt AB
# Prompts  -> Prompt A, Prompt B

puts "Seeding Devbook..."

Prompt.destroy_all
Project.destroy_all

project_a = Project.create!(
  name: "Project A",
  description: "Core developer workflows and architecture review prompts"
)

# Prompts assigned to Project A
Prompt.create!(
  project: project_a,
  title: "Prompt AA",
  body: <<~MARKDOWN
    # Code Architecture Reviewer

    You are a principal software architect reviewing PRs for **clean code**, **security**, and **performance**.

    ## Checklist:
    - [ ] Database query efficiency (N+1 queries avoided)
    - [ ] Proper error handling and edge cases
    - [ ] Idempotent background jobs
    - [ ] Strict input validation

    ### Sample Ruby Pattern:
    ```ruby
    def execute_safely
      ActiveRecord::Base.transaction do
        yield
      end
    rescue StandardError => e
      Rails.logger.error("Transaction failed: \#{e.message}")
      raise
    end
    ```

    > Always explain the *why* behind every suggested refactor.
  MARKDOWN
)

Prompt.create!(
  project: project_a,
  title: "Prompt AB",
  body: <<~MARKDOWN
    # API Documentation Generator

    Generate comprehensive OpenAPI 3.1 compatible documentation for the following endpoint.

    ### Required Output Format:
    | Field | Type | Description |
    | :--- | :--- | :--- |
    | `status` | string | HTTP status indicator (`success` or `error`) |
    | `payload` | object | The entity data dictionary |
    | `timestamp` | ISO8601 | Current UTC server timestamp |

    Provide request and response examples in JSON format with error states (400, 404, 500).
  MARKDOWN
)

# Standalone Prompts (no project assigned)
Prompt.create!(
  project: nil,
  title: "Prompt A",
  body: <<~MARKDOWN
    # Regex & Pattern Assistant

    Analyze the provided string input and generate a robust regular expression with full explanation.

    - Target environment: Ruby / ECMAScript 2024
    - Include named capture groups where appropriate
    - Test against positive and negative edge cases
  MARKDOWN
)

Prompt.create!(
  project: nil,
  title: "Prompt B",
  body: <<~MARKDOWN
    # Git Commit Message Synthesizer

    Given the following `git diff --cached` output, write a clean Conventional Commit message:

    Format:
    `<type>(<scope>): <short summary>`

    `[optional body explaining motivation and breaking changes]`

    Types: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `chore`.
  MARKDOWN
)

puts "Seeded #{Project.count} projects and #{Prompt.count} prompts successfully!"
