# == Schema Information
# id :integer, not null
# user_id :integer, not null
# grocery_section_id :integer, not null
# name :string, not null
# quantity :decimal, not null
# unit_id :integer, not null
# created_at :datetime, not null
# updated_at :datetime, not null
# emoji :string, nullable
class Grocery < ApplicationRecord
  belongs_to :user
  belongs_to :grocery_section
  belongs_to :unit
  has_many :recipe_ingredients, dependent: :destroy
  has_many :grocery_list_items, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
