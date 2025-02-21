require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:encrypted_password) }
  end

  describe 'associations' do
    it { should have_many(:groceries).dependent(:destroy) }
    it { should have_many(:recipes).dependent(:destroy) }
    it { should have_many(:grocery_list_items).dependent(:destroy) }
    it { should have_many(:grocery_sections).dependent(:destroy) }
  end

  describe 'devise modules' do
    it 'includes expected devise modules' do
      expect(User.devise_modules).to include(
                                       :database_authenticatable,
                                       :registerable,
                                       :recoverable,
                                       :rememberable,
                                       :validatable
                                     )
    end
  end
end
