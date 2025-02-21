class AddUniqueIndexToStoreSections < ActiveRecord::Migration[8.0]
  def change
    add_index :store_sections, [ :user_id, :display_order ], unique: true
  end
end
