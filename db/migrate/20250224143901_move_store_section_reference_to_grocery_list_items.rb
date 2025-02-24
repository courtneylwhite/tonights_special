class MoveStoreSectionReferenceToGroceryListItems < ActiveRecord::Migration[8.0]
  def up
    # First add the store_section_id to grocery_list_items
    add_reference :grocery_list_items, :store_section, foreign_key: true

    # Remove the NOT NULL constraint before removing the column
    change_column_null :groceries, :store_section_id, true

    # Remove store_section_id from groceries
    remove_reference :groceries, :store_section, foreign_key: true, index: true

    # Remove the compound index
    remove_index :groceries, [:user_id, :store_section_id], if_exists: true

    # Add compound index to grocery_list_items
    add_index :grocery_list_items, [:user_id, :store_section_id]
  end
end