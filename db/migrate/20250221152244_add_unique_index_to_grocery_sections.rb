class AddUniqueIndexToGrocerySections < ActiveRecord::Migration[8.0]
  def change
    add_index :grocery_sections, [ :user_id, :display_order ], unique: true
  end
end
