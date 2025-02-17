class AddIndexesToTables < ActiveRecord::Migration[8.0]
  def change
    add_index :grocery_sections, :display_order

    add_index :groceries, [:user_id, :grocery_section_id]
    add_index :groceries, [:user_id, :store_section_id]
    add_index :groceries, [:user_id, :name]

    add_index :recipes, [:user_id, :completed]
    add_index :recipes, [:user_id, :name]

    add_index :grocery_list_items, [:user_id, :purchased]
    add_index :grocery_list_items, [:user_id, :grocery_id]

    add_index :units, [:category, :name]
  end
end
