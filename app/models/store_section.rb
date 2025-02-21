class StoreSection < ApplicationRecord
  belongs_to :user
  has_many :groceries

  validates :name, presence: true, uniqueness: { scope: :user_id, case_sensitive: false }
  validates :display_order, presence: true, uniqueness: { scope: :user_id }
end
