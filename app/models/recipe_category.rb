# == Schema Information
# id :integer, not null
# name :string, not null
# display_order :integer, nullable
# user_id :integer, not null
# created_at :datetime, not null
# updated_at :datetime, not null
class RecipeCategory < ApplicationRecord
  belongs_to :user
  has_many :recipes

  validates :name, presence: true, uniqueness: { scope: :user_id, case_sensitive: false }
  validates :display_order, presence: true, uniqueness: { scope: :user_id }
end
