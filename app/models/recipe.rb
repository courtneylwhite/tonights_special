# == Schema Information
# id :integer, not null 
# user_id :integer, not null 
# name :string, nullable 
# instructions :text, nullable 
# completed :boolean, nullable 
# completed_at :datetime, nullable 
# notes :text, nullable 
# created_at :datetime, not null 
# updated_at :datetime, not null 
class Recipe < ApplicationRecord
  belongs_to :user
  has_many :recipe_ingredients, dependent: :destroy
  has_many :groceries, through: :recipe_ingredients

  validates :name, presence: true
  validates :instructions, presence: true

  scope :completed, -> { where(completed: true) }
  scope :not_completed, -> { where(completed: false) }
end
