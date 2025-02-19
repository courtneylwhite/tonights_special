class CreateStoreSections < ActiveRecord::Migration[8.0]
  def change
    create_table :store_sections do |t|
      t.string :name
      t.integer :display_order

      t.timestamps
    end
  end
end
