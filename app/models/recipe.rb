class Recipe < ApplicationRecord
  belongs_to :user
  has_many :recipe_ingredients, dependent: :destroy
  has_many :groceries, through: :recipe_ingredients

  validates :name, presence: true
  validates :instructions, presence: true

  scope :completed, -> { where(completed: true) }
  scope :not_completed, -> { where(completed: false) }
end
