class RecipeIngredient < ApplicationRecord
  belongs_to :recipe
  belongs_to :grocery
  belongs_to :unit

  validates :quantity, presence: true, numericality: { greater_than: 0 }
end
