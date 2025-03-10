# == Schema Information
# id :integer, not null
# name :string, nullable
# display_order :integer, not null
# created_at :datetime, not null
# updated_at :datetime, not null
# user_id :integer, not null
class GrocerySection < ApplicationRecord
  belongs_to :user

  validates :name, presence: true, uniqueness: { scope: :user_id, case_sensitive: false }
  validates :display_order, presence: true, uniqueness: { scope: :user_id }
end
