class GrocerySection < ApplicationRecord
  belongs_to :user
  validates :name, presence: true
  validates :display_order, presence: true
end
