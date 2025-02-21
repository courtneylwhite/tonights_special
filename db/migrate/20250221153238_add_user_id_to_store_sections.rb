class AddUserIdToStoreSections < ActiveRecord::Migration[8.0]
  def up
    add_reference :store_sections, :user, null: true, foreign_key: true

    User.first.tap do |user|
      if user
        execute <<-SQL
            UPDATE store_sections#{' '}
            SET user_id = #{user.id}
            WHERE user_id IS NULL
        SQL
      end
    end

    change_column_null :store_sections, :user_id, false
  end

  def down
    remove_reference :grocery_sections, :user
  end
end
