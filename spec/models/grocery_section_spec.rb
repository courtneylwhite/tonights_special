require 'rails_helper'

RSpec.describe GrocerySection, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:display_order) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:grocery_section)).to be_valid
    end
  end
end
