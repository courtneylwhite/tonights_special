require 'rails_helper'

RSpec.describe GrocerySection, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    subject { build(:grocery_section) }  # Add this line

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:display_order) }
    it { should validate_uniqueness_of(:name).case_insensitive.scoped_to(:user_id) }  # Add scoped_to
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:grocery_section)).to be_valid
    end
  end
end
