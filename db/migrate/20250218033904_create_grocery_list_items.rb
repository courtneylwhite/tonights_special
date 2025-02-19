class CreateGroceryListItems < ActiveRecord::Migration[8.0]
  def change
    create_table :grocery_list_items do |t|
      t.references :user, null: false, foreign_key: true
      t.references :grocery, null: false, foreign_key: true
      t.decimal :quantity
      t.references :unit, null: false, foreign_key: true
      t.text :notes
      t.boolean :purchased

      t.timestamps
    end
  end
end
