# == Schema Information
# id :integer, not null
# user_id :integer, not null
# name :string, not null
# instructions :text, not null
# completed :boolean, nullable
# completed_at :datetime, nullable
# notes :text, nullable
# created_at :datetime, not null
# updated_at :datetime, not null
# recipe_category_id :integer, not null
# prep_time :string, nullable
# cook_time :string, nullable
# servings :float, nullable
class Recipe < ApplicationRecord
  belongs_to :user
  belongs_to :recipe_category

  has_many :recipe_ingredients, dependent: :destroy
  has_many :groceries, through: :recipe_ingredients

  validates :name, presence: true
  validates :instructions, presence: true

  scope :completed, -> { where(completed: true) }
  scope :not_completed, -> { where(completed: false) }
end
