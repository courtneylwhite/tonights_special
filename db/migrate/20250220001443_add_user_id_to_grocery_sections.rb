class AddUserIdToGrocerySections < ActiveRecord::Migration[8.0]
  def up
    add_reference :grocery_sections, :user, null: true, foreign_key: true

    User.first.tap do |user|
      if user
        execute <<-SQL
          UPDATE grocery_sections#{' '}
          SET user_id = #{user.id}
          WHERE user_id IS NULL
        SQL
      end
    end

    change_column_null :grocery_sections, :user_id, false
  end

  def down
    remove_reference :grocery_sections, :user
  end
end
