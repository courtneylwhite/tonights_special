class Grocery < ApplicationRecord
  belongs_to :user
  belongs_to :store_section
  belongs_to :grocery_section
  belongs_to :unit
  has_many :recipe_ingredients, dependent: :destroy
  has_many :grocery_list_items, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
