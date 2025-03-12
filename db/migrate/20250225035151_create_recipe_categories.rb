class CreateRecipeCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :recipe_categories do |t|
      t.string :name
      t.integer :display_order
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end
