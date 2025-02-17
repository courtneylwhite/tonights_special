class CreateUnitConversions < ActiveRecord::Migration[8.0]
  def change
    create_table :unit_conversions do |t|
      t.references :from_unit, null: false, foreign_key: { to_table: :units }
      t.references :to_unit, null: false, foreign_key: { to_table: :units }
      t.decimal :conversion_factor, null: false

      t.timestamps
    end

    add_index :unit_conversions, [:from_unit_id, :to_unit_id], unique: true
  end
end