require 'rails_helper'

RSpec.describe Grocery, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:store_section) }
    it { should belong_to(:grocery_section) }
    it { should belong_to(:unit) }
    it { should have_many(:recipe_ingredients).dependent(:destroy) }
    it { should have_many(:grocery_list_items).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:quantity) }
    it { should validate_numericality_of(:quantity).is_greater_than_or_equal_to(0) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      grocery = build(:grocery)
      expect(grocery).to be_valid
    end
  end
end
