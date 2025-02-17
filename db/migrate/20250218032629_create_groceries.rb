class CreateGroceries < ActiveRecord::Migration[8.0]
  def change
    create_table :groceries do |t|
      t.references :user, null: false, foreign_key: true
      t.references :store_section, null: false, foreign_key: true
      t.references :grocery_section, null: false, foreign_key: true
      t.string :name
      t.decimal :quantity
      t.references :unit, null: false, foreign_key: true

      t.timestamps
    end
  end
end
