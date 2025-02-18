require 'rails_helper'

RSpec.describe Grocery, type: :model do
  # Factory setup
  let(:user) { create(:user) }
  let(:store_section) { create(:store_section) }
  let(:grocery_section) { create(:grocery_section) }
  let(:unit) { create(:unit) }
  let(:valid_attributes) do
    {
      name: "Apples",
      quantity: 5,
      user: user,
      store_section: store_section,
      grocery_section: grocery_section,
      unit: unit
    }
  end

  # Create a valid grocery instance for testing
  subject(:grocery) { described_class.new(valid_attributes) }

  # Basic validity test
  describe 'validity' do
    it 'is valid with valid attributes' do
      expect(grocery).to be_valid
    end
  end

  # Association tests
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:store_section) }
    it { should belong_to(:grocery_section) }
    it { should belong_to(:unit) }
    it { should have_many(:recipe_ingredients).dependent(:destroy) }
    it { should have_many(:grocery_list_items).dependent(:destroy) }
  end

  # Validation tests
  describe 'validations' do
    context 'name' do
      it { should validate_presence_of(:name) }

      it 'is invalid without a name' do
        grocery.name = nil
        expect(grocery).not_to be_valid
      end

      it 'is invalid with an empty name' do
        grocery.name = ''
        expect(grocery).not_to be_valid
      end
    end

    context 'quantity' do
      it { should validate_presence_of(:quantity) }
      it { should validate_numericality_of(:quantity).is_greater_than_or_equal_to(0) }

      it 'is invalid without a quantity' do
        grocery.quantity = nil
        expect(grocery).not_to be_valid
      end

      it 'is invalid with a negative quantity' do
        grocery.quantity = -1
        expect(grocery).not_to be_valid
      end

      it 'is valid with zero quantity' do
        grocery.quantity = 0
        expect(grocery).to be_valid
      end

      it 'is valid with a positive quantity' do
        grocery.quantity = 1
        expect(grocery).to be_valid
      end
    end
  end

  # Dependency tests
  describe 'dependent destroy' do
    let!(:user) { create(:user) }
    let!(:store_section) { create(:store_section) }
    let!(:grocery_section) { create(:grocery_section) }
    let!(:unit) { create(:unit) }
    let!(:grocery) { create(:grocery, user: user, store_section: store_section,
                            grocery_section: grocery_section, unit: unit) }
    let!(:recipe) { create(:recipe, user: user) }
    let!(:recipe_ingredient) { create(:recipe_ingredient, grocery: grocery, recipe: recipe, unit: unit) }
    let!(:grocery_list_item) { create(:grocery_list_item, grocery: grocery, unit: unit) }

    it 'destroys associated recipe_ingredients when destroyed' do
      expect { grocery.destroy }.to change(RecipeIngredient, :count).by(-1)
    end

    it 'destroys associated grocery_list_items when destroyed' do
      expect { grocery.destroy }.to change(GroceryListItem, :count).by(-1)
    end
  end

  # Edge cases
  describe 'edge cases' do
    it 'handles very large quantities' do
      grocery.quantity = 999999999
      expect(grocery).to be_valid
    end

    it 'handles special characters in name' do
      grocery.name = "Special! @#$%^&*()"
      expect(grocery).to be_valid
    end

    it 'handles unicode characters in name' do
      grocery.name = "アップル 🍎"
      expect(grocery).to be_valid
    end
  end
end
