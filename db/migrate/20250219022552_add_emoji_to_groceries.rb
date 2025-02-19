class AddEmojiToGroceries < ActiveRecord::Migration[8.0]
  def change
    add_column :groceries, :emoji, :string
  end
end
