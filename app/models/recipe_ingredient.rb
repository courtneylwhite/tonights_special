# == Schema Information
# id :integer, not null
# recipe_id :integer, not null
# grocery_id :integer, nullable
# quantity :decimal, not null
# unit_id :integer, not null
# created_at :datetime, not null
# updated_at :datetime, not null
# name :string, not null
# preparation :string, nullable
# size :string, nullable
class RecipeIngredient < ApplicationRecord
  belongs_to :recipe
  belongs_to :grocery, optional: true
  belongs_to :unit

  validates :quantity, presence: true, numericality: { greater_than: 0 }
end
