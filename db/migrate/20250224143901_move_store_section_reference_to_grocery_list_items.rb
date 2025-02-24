class MoveStoreSectionReferenceToGroceryListItems < ActiveRecord::Migration[8.0]
  class MoveStoreSectionReferenceToGroceryListItems < ActiveRecord::Migration[8.0]
    def change
      # Add store_section_id to grocery_list_items
      add_reference :grocery_list_items, :store_section, foreign_key: true

      # Remove store_section_id from groceries
      remove_reference :groceries, :store_section, foreign_key: true, index: true

      # Remove the compound index
      remove_index :groceries, [:user_id, :store_section_id], if_exists: true

      add_index :grocery_list_items, [:user_id, :store_section_id]
    end
  end
end
