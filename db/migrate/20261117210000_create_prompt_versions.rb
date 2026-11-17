# frozen_string_literal: true

class CreatePromptVersions < ActiveRecord::Migration[8.1]
  def up
    create_table :prompt_versions do |t|
      t.references :prompt, null: false, foreign_key: { on_delete: :cascade }
      t.integer :version_number, null: false
      t.string :title, null: false
      t.text :body, default: "", null: false
      t.datetime :created_at, null: false
    end

    add_index :prompt_versions, %i[prompt_id version_number], unique: true
    add_index :prompt_versions, %i[prompt_id created_at]

    execute <<~SQL.squish
      INSERT INTO prompt_versions (prompt_id, version_number, title, body, created_at)
      SELECT id, 1, title, body, created_at
      FROM prompts
    SQL
  end

  def down
    drop_table :prompt_versions
  end
end
