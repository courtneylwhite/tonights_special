require 'rails_helper'

RSpec.describe GroceryListItem, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:grocery) }
    it { should belong_to(:unit) }
    it { should belong_to(:store_section) }
  end

  describe 'validations' do
    it { should validate_presence_of(:quantity) }
    it { should validate_numericality_of(:quantity).is_greater_than(0) }
  end
end