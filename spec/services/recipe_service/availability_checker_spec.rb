require 'rails_helper'

RSpec.describe RecipeServices::AvailabilityChecker do
  let(:user) { create(:user) }
  let(:recipe_category) { create(:recipe_category, user: user) }
  let(:recipe) { create(:recipe, user: user, recipe_category: recipe_category) }

  let(:cup_unit) { create(:unit, name: 'cup', abbreviation: 'c', category: 'volume') }
  let(:tablespoon_unit) { create(:unit, name: 'tablespoon', abbreviation: 'tbsp', category: 'volume') }
  let(:whole_unit) { create(:unit, name: 'whole', abbreviation: 'pcs', category: 'count') }

  let(:flour) { create(:grocery, name: 'flour', user: user, unit: cup_unit) }
  let(:eggs) { create(:grocery, name: 'eggs', user: user, unit: whole_unit) }
  let(:butter) { create(:grocery, name: 'butter', user: user, unit: tablespoon_unit) }
  let(:sugar) { create(:grocery, name: 'sugar', user: user, unit: cup_unit) }

  before do
    # Create recipe ingredients
    create(:recipe_ingredient, recipe: recipe, grocery: flour, unit: cup_unit, quantity: 2, name: 'flour')
    create(:recipe_ingredient, recipe: recipe, grocery: eggs, unit: whole_unit, quantity: 3, name: 'eggs')
    create(:recipe_ingredient, recipe: recipe, grocery: butter, unit: tablespoon_unit, quantity: 6, name: 'butter')
    create(:recipe_ingredient, recipe: recipe, grocery: sugar, unit: cup_unit, quantity: 2, name: 'sugar')
  end

  describe '#available?' do
    context 'when all ingredients have grocery associations' do
      it 'returns true' do
        checker = described_class.new(user, recipe)
        expect(checker.available?).to be true
      end
    end

    context 'when some ingredients have no grocery association' do
      it 'returns false' do
        # Create an ingredient without a grocery association
        create(:recipe_ingredient, recipe: recipe, grocery: nil, unit: cup_unit, quantity: 1, name: 'cinnamon')

        checker = described_class.new(user, recipe)
        expect(checker.available?).to be false
      end
    end

    context 'with preloaded groceries' do
      it 'uses preloaded groceries instead of querying the database' do
        # Spy on the Grocery.find method to make sure it's not called
        expect(Grocery).not_to receive(:find)
        expect(Grocery).not_to receive(:find_by)

        checker = described_class.new(user, recipe)
        checker.available?
      end
    end

    context 'with early termination' do
      it 'stops checking after finding first missing ingredient' do
        # Create multiple ingredients without groceries
        create(:recipe_ingredient, recipe: recipe, grocery: nil, unit: cup_unit, quantity: 1, name: 'cinnamon')
        create(:recipe_ingredient, recipe: recipe, grocery: nil, unit: cup_unit, quantity: 1, name: 'vanilla')

        checker = described_class.new(user, recipe)

        # Spy on the missing_ingredients method to verify it's called with limit=1
        expect(checker).to receive(:missing_ingredients).with(1).and_call_original

        checker.available?
      end
    end
  end

  describe '#availability_info' do
    it 'returns a hash with availability status and missing ingredients' do
      checker = described_class.new(user, recipe)
      result = checker.availability_info

      expect(result).to be_a(Hash)
      expect(result).to have_key(:available)
      expect(result).to have_key(:missing_ingredients)
    end

    context 'when all ingredients have grocery associations' do
      it 'returns an empty missing_ingredients array' do
        checker = described_class.new(user, recipe)
        result = checker.availability_info

        expect(result[:available]).to be true
        expect(result[:missing_ingredients]).to be_empty
      end
    end

    context 'when some ingredients are missing grocery associations' do
      it 'includes them in the missing_ingredients array' do
        # Create an ingredient without a grocery association
        missing_ingredient = create(:recipe_ingredient, recipe: recipe, grocery: nil, unit: cup_unit, quantity: 1, name: 'cinnamon')

        checker = described_class.new(user, recipe)
        result = checker.availability_info

        expect(result[:available]).to be false
        expect(result[:missing_ingredients]).not_to be_empty
        missing = result[:missing_ingredients].first
        expect(missing[:name]).to eq('cinnamon')
        expect(missing[:id]).to eq(missing_ingredient.id)
      end
    end

    context 'with limit parameter' do
      it 'limits the number of missing ingredients returned' do
        # Create multiple ingredients without groceries
        create(:recipe_ingredient, recipe: recipe, grocery: nil, unit: cup_unit, quantity: 1, name: 'cinnamon')
        create(:recipe_ingredient, recipe: recipe, grocery: nil, unit: cup_unit, quantity: 1, name: 'vanilla')
        create(:recipe_ingredient, recipe: recipe, grocery: nil, unit: cup_unit, quantity: 1, name: 'nutmeg')

        checker = described_class.new(user, recipe)
        result = checker.availability_info(2)

        expect(result[:missing_ingredients].length).to eq(2)
      end
    end
  end

  describe '#missing_ingredients' do
    it 'identifies ingredients with no grocery association as missing' do
      cinnamon = create(:recipe_ingredient, recipe: recipe, grocery: nil, unit: cup_unit, quantity: 1, name: 'cinnamon')

      checker = described_class.new(user, recipe)
      missing = checker.missing_ingredients

      missing_cinnamon = missing.find { |i| i[:name] == 'cinnamon' }
      expect(missing_cinnamon).not_to be_nil
      expect(missing_cinnamon[:id]).to eq(cinnamon.id)
    end

    it 'returns an empty array when all ingredients have grocery associations' do
      checker = described_class.new(user, recipe)
      missing = checker.missing_ingredients

      expect(missing).to be_empty
    end

    context 'with limit parameter' do
      it 'stops after finding the specified number of missing ingredients' do
        # Create multiple ingredients without groceries
        create(:recipe_ingredient, recipe: recipe, grocery: nil, unit: cup_unit, quantity: 1, name: 'cinnamon')
        create(:recipe_ingredient, recipe: recipe, grocery: nil, unit: cup_unit, quantity: 1, name: 'vanilla')
        create(:recipe_ingredient, recipe: recipe, grocery: nil, unit: cup_unit, quantity: 1, name: 'nutmeg')

        checker = described_class.new(user, recipe)
        missing = checker.missing_ingredients(2)

        expect(missing.length).to eq(2)
      end
    end
  end
end
