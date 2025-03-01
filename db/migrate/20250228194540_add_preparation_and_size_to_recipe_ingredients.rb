class AddPreparationAndSizeToRecipeIngredients < ActiveRecord::Migration[8.0]
  def change
    add_column :recipe_ingredients, :preparation, :string
    add_column :recipe_ingredients, :size, :string
  end
end
