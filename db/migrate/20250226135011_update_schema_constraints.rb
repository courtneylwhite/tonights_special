class UpdateSchemaConstraints < ActiveRecord::Migration[8.0]
  def change
    change_column_null :recipe_ingredients, :grocery_id, true

    change_column_null :recipe_ingredients, :quantity, false

    change_column_null :grocery_sections, :display_order, false

    change_column_null :grocery_list_items, :grocery_id, true

    change_column_null :recipe_categories, :name, false
    add_index :recipe_categories, :name, unique: true, if_not_exists: true

    add_index :recipes, :name, unique: true, if_not_exists: true
    change_column_null :recipes, :name, false
    change_column_null :recipes, :instructions, false
    change_column_null :recipes, :recipe_category_id, false
  end
end