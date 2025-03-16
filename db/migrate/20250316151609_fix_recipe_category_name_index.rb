class FixRecipeCategoryNameIndex < ActiveRecord::Migration[8.0]
  def change
    # Remove the incorrect index
    remove_index :recipe_categories, name: "index_recipe_categories_on_name"

    # Add the correct scoped index
    add_index :recipe_categories, [ :user_id, :name ], unique: true
  end
end
