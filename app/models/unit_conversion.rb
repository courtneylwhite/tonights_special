# == Schema Information
# id :integer, not null 
# from_unit_id :integer, not null 
# to_unit_id :integer, not null 
# conversion_factor :decimal, not null 
# created_at :datetime, not null 
# updated_at :datetime, not null 
class UnitConversion < ApplicationRecord
  belongs_to :from_unit, class_name: "Unit"
  belongs_to :to_unit, class_name: "Unit"

  validates :conversion_factor, presence: true, numericality: { greater_than: 0 }
  validate :different_units

  private

  def different_units
    if from_unit_id == to_unit_id
      errors.add(:base, "From and To units must be different")
    end
  end
end
