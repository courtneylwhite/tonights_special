class GroceryListItem < ApplicationRecord
  belongs_to :user
  belongs_to :grocery
  belongs_to :unit

  validates :quantity, presence: true, numericality: { greater_than: 0 }
end
