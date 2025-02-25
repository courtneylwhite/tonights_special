# == Schema Information
# id :integer, not null
# recipe_id :integer, not null
# grocery_id :integer, not null
# quantity :decimal, nullable
# unit_id :integer, not null
# created_at :datetime, not null
# updated_at :datetime, not null
class RecipeIngredient < ApplicationRecord
  belongs_to :recipe
  belongs_to :grocery, optional: true
  belongs_to :unit

  validates :quantity, presence: true, numericality: { greater_than: 0 }
end
