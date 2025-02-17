class CreateRecipes < ActiveRecord::Migration[8.0]
  def change
    create_table :recipes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.text :instructions
      t.boolean :completed
      t.datetime :completed_at
      t.text :notes

      t.timestamps
    end
  end
end
