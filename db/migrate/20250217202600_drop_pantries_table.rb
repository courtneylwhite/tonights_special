class DropPantriesTable < ActiveRecord::Migration[8.0]
  def up
    drop_table :pantries
  end

  def down
    create_table :pantries do |t|
      t.references :user, foreign_key: true
      t.timestamps
    end
  end
end
