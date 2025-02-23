# == Schema Information
# id :integer, not null
# user_id :integer, not null
# grocery_id :integer, not null
# quantity :decimal, nullable
# unit_id :integer, not null
# notes :text, nullable
# purchased :boolean, nullable
# created_at :datetime, not null
# updated_at :datetime, not null
class GroceryListItem < ApplicationRecord
  belongs_to :user
  belongs_to :grocery
  belongs_to :unit

  validates :quantity, presence: true, numericality: { greater_than: 0 }
end
