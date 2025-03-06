class AddEstimatesToRecipes < ActiveRecord::Migration[8.0]
  def change
    add_column :recipes, :prep_time, :string
    add_column :recipes, :cook_time, :string
    add_column :recipes, :servings, :float
  end
end
