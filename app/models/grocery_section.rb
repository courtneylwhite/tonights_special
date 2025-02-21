class GrocerySection < ApplicationRecord
  belongs_to :user

  validates :name, presence: true, uniqueness: { scope: :user_id, case_sensitive: false }
  validates :display_order, presence: true, uniqueness: { scope: :user_id }
end
