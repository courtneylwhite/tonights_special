# == Schema Information
# id :integer, not null
# name :string, nullable
# category :string, nullable
# abbreviation :string, nullable
# created_at :datetime, not null
# updated_at :datetime, not null
class Unit < ApplicationRecord
  has_many :groceries
  has_many :recipe_ingredients
  has_many :grocery_list_items
  has_many :from_conversions, class_name: "UnitConversion", foreign_key: "from_unit_id"
  has_many :to_conversions, class_name: "UnitConversion", foreign_key: "to_unit_id"

  validates :name, presence: true, uniqueness: true
  validates :category, presence: true
  validates :abbreviation, presence: true, uniqueness: true
end
