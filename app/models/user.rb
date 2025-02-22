# == Schema Information
# id :integer, not null 
# email :string, not null default: 
# encrypted_password :string, not null default: 
# reset_password_token :string, nullable 
# reset_password_sent_at :datetime, nullable 
# remember_created_at :datetime, nullable 
# created_at :datetime, not null 
# updated_at :datetime, not null 
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :groceries, dependent: :destroy
  has_many :recipes, dependent: :destroy
  has_many :grocery_list_items, dependent: :destroy
  has_many :grocery_sections, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :encrypted_password, presence: true
end
