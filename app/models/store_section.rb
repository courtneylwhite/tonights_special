class StoreSection < ApplicationRecord
  has_many :groceries

  validates :name, presence: true, uniqueness: true
  validates :display_order, presence: true

  default_scope { order(display_order: :asc) }
end
