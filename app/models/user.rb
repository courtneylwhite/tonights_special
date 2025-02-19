class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :groceries, dependent: :destroy
  has_many :recipes, dependent: :destroy
  has_many :grocery_list_items, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :encrypted_password, presence: true
end
