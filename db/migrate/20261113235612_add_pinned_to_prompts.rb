class AddPinnedToPrompts < ActiveRecord::Migration[8.1]
  def change
    add_column :prompts, :pinned, :boolean, default: false, null: false
    add_column :prompts, :pinned_position, :integer
    add_index :prompts, [ :pinned, :pinned_position ]
  end
end
