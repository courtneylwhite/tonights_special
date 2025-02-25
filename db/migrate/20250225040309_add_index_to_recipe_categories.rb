class AddIndexToRecipeCategories < ActiveRecord::Migration[8.0]
  def change
    add_index :recipe_categories, [ :user_id, :display_order ], unique: true
  end
end
