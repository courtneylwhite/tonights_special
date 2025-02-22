class AddNotNullToGroceriesName < ActiveRecord::Migration[8.0]
  def change
    change_column_null :groceries, :name, false
    change_column_null :groceries, :quantity, false
  end
end
