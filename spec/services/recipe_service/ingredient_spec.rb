require 'rails_helper'

RSpec.describe RecipeServices::Ingredient do
  let(:user) { create(:user) }
  let(:recipe_category) { create(:recipe_category, user: user) }
  let(:recipe) { create(:recipe, user: user, recipe_category: recipe_category) }

  # Units
  let!(:cup_unit) { create(:unit, name: 'cup', abbreviation: 'c', category: 'volume') }
  let!(:tablespoon_unit) { create(:unit, name: 'tablespoon', abbreviation: 'tbsp', category: 'volume') }
  let!(:teaspoon_unit) { create(:unit, name: 'teaspoon', abbreviation: 'tsp', category: 'volume') }
  let!(:whole_unit) { create(:unit, name: 'whole', abbreviation: 'pcs', category: 'count') }
  let!(:ounce_unit) { create(:unit, name: 'ounce', abbreviation: 'oz', category: 'weight') }
  let!(:pound_unit) { create(:unit, name: 'pound', abbreviation: 'lb', category: 'weight') }

  # Groceries
  let!(:flour) { create(:grocery, name: 'flour', user: user, unit: cup_unit) }
  let!(:sugar) { create(:grocery, name: 'sugar', user: user, unit: cup_unit) }

  describe '#create_ingredients' do
    context 'with valid ingredient data' do
      let(:ingredients_data) {
        [
          { name: 'flour', quantity: 2, unit_name: 'cup' },
          { name: 'sugar', quantity: 1, unit_name: 'cup' },
          { name: 'eggs', quantity: 3, unit_name: 'whole' }
        ]
      }

      it 'creates recipe ingredients for each ingredient' do
        service = described_class.new(recipe, user, ingredients_data)

        expect {
          result = service.create_ingredients
          expect(result[:success]).to be true
        }.to change(RecipeIngredient, :count).by(3)
      end

      it 'associates ingredients with existing groceries when available' do
        service = described_class.new(recipe, user, ingredients_data)
        result = service.create_ingredients

        flour_ingredient = RecipeIngredient.find_by(name: 'flour')
        sugar_ingredient = RecipeIngredient.find_by(name: 'sugar')
        eggs_ingredient = RecipeIngredient.find_by(name: 'eggs')

        expect(flour_ingredient.grocery).to eq(flour)
        expect(sugar_ingredient.grocery).to eq(sugar)
        expect(eggs_ingredient.grocery).to be_nil # No matching grocery
      end

      it 'sets the correct quantities and units' do
        service = described_class.new(recipe, user, ingredients_data)
        result = service.create_ingredients

        flour_ingredient = RecipeIngredient.find_by(name: 'flour')
        expect(flour_ingredient.quantity).to eq(2)
        expect(flour_ingredient.unit).to eq(cup_unit)

        sugar_ingredient = RecipeIngredient.find_by(name: 'sugar')
        expect(sugar_ingredient.quantity).to eq(1)
        expect(sugar_ingredient.unit).to eq(cup_unit)
      end
    end

    context 'with empty ingredients data' do
      it 'returns success with an empty ingredients array' do
        service = described_class.new(recipe, user, [])
        result = service.create_ingredients

        expect(result[:success]).to be true
        expect(result[:ingredients]).to be_empty
      end

      it 'returns success with an empty ingredients array when nil is provided' do
        service = described_class.new(recipe, user, nil)
        result = service.create_ingredients

        expect(result[:success]).to be true
        expect(result[:ingredients]).to be_empty
      end
    end

    context 'when some ingredient creations fail' do
      let(:invalid_ingredients_data) {
        [
          { name: 'flour', quantity: 2, unit_name: 'cup' },
          { name: '', quantity: 1, unit_name: 'cup' } # Invalid: empty name
        ]
      }

      it 'collects error messages and returns success: false when errors exist' do
        # Mock the recipe_ingredients association to raise an error for the invalid ingredient
        allow(recipe.recipe_ingredients).to receive(:create!).and_call_original

        # Recipe class might use different validation, but we're simulating it failing
        # specifically for an empty name
        allow(recipe.recipe_ingredients).to receive(:create!).with(
          hash_including(name: ''),
          any_args
        ).and_raise(ActiveRecord::RecordInvalid, "Validation failed: Name can't be blank")

        service = described_class.new(recipe, user, invalid_ingredients_data)
        result = service.create_ingredients

        expect(result[:success]).to be false
        expect(result[:errors]).not_to be_empty
        expect(result[:errors].first).to include("Error creating ingredient")
      end

      it 'creates valid ingredients but keeps track of failures' do
        # Allow valid ingredients to be created normally
        allow(recipe.recipe_ingredients).to receive(:create!).and_call_original

        # But make the invalid ingredient fail
        allow(recipe.recipe_ingredients).to receive(:create!).with(
          hash_including(name: ''),
          any_args
        ).and_raise(ActiveRecord::RecordInvalid, "Validation failed: Name can't be blank")

        service = described_class.new(recipe, user, invalid_ingredients_data)

        expect {
          result = service.create_ingredients
          expect(result[:success]).to be false
          expect(result[:errors]).not_to be_empty
        }.to change(RecipeIngredient, :count).by(1) # Only the valid one is created
      end
    end
  end

  describe 'unit handling' do
    it 'normalizes unit names' do
      ingredients_data = [
        { name: 'flour', quantity: 2, unit_name: 'tbsp' }, # Should normalize to tablespoon
        { name: 'sugar', quantity: 1, unit_name: 'c' }     # Should normalize to cup
      ]

      service = described_class.new(recipe, user, ingredients_data)
      result = service.create_ingredients

      flour_ingredient = RecipeIngredient.find_by(name: 'flour')
      expect(flour_ingredient.unit).to eq(tablespoon_unit)

      sugar_ingredient = RecipeIngredient.find_by(name: 'sugar')
      expect(sugar_ingredient.unit).to eq(cup_unit)
    end

    it 'handles units with trailing periods' do
      ingredients_data = [
        { name: 'flour', quantity: 2, unit_name: 'tbsp.' }
      ]

      service = described_class.new(recipe, user, ingredients_data)
      result = service.create_ingredients

      flour_ingredient = RecipeIngredient.find_by(name: 'flour')
      expect(flour_ingredient.unit).to eq(tablespoon_unit)
    end

    it 'normalizes teaspoon abbreviations' do
      ingredients_data = [
        { name: 'cinnamon', quantity: 1, unit_name: 'tsp' },
        { name: 'vanilla extract', quantity: 0.5, unit_name: 'tsps' }
      ]

      service = described_class.new(recipe, user, ingredients_data)
      result = service.create_ingredients

      cinnamon_ingredient = RecipeIngredient.find_by(name: 'cinnamon')
      vanilla_ingredient = RecipeIngredient.find_by(name: 'vanilla extract')

      expect(cinnamon_ingredient.unit).to eq(teaspoon_unit)
      expect(vanilla_ingredient.unit).to eq(teaspoon_unit)
    end

    it 'normalizes weight unit abbreviations' do
      ingredients_data = [
        { name: 'chicken', quantity: 1, unit_name: 'lb' },
        { name: 'chocolate chips', quantity: 8, unit_name: 'oz' }
      ]

      service = described_class.new(recipe, user, ingredients_data)
      result = service.create_ingredients

      chicken_ingredient = RecipeIngredient.find_by(name: 'chicken')
      chocolate_ingredient = RecipeIngredient.find_by(name: 'chocolate chips')

      expect(chicken_ingredient.unit).to eq(pound_unit)
      expect(chocolate_ingredient.unit).to eq(ounce_unit)
    end

    it 'handles other common unit abbreviations' do
      # Create additional units for testing
      gallon_unit = create(:unit, name: 'gallon', abbreviation: 'gal', category: 'volume')
      gram_unit = create(:unit, name: 'gram', abbreviation: 'g', category: 'weight')

      ingredients_data = [
        { name: 'milk', quantity: 1, unit_name: 'gal' },
        { name: 'sugar', quantity: 200, unit_name: 'g' }
      ]

      service = described_class.new(recipe, user, ingredients_data)
      result = service.create_ingredients

      milk_ingredient = RecipeIngredient.find_by(name: 'milk')
      sugar_ingredient = RecipeIngredient.where(name: 'sugar').last # Get the latest one

      expect(milk_ingredient.unit).to eq(gallon_unit)
      expect(sugar_ingredient.unit).to eq(gram_unit)
    end

    it 'creates new units when needed' do
      ingredients_data = [
        { name: 'carrots', quantity: 3, unit_name: 'bunch' } # New unit
      ]

      service = described_class.new(recipe, user, ingredients_data)

      expect {
        result = service.create_ingredients
        expect(result[:success]).to be true
      }.to change(Unit, :count).by(1)

      new_unit = Unit.find_by(name: 'bunch')
      expect(new_unit).not_to be_nil
      expect(new_unit.category).to eq('other') # Default category
    end

    it 'attempts to determine the correct category for new volume units' do
      ingredients_data = [
        { name: 'milk', quantity: 1, unit_name: 'gallon' } # Volume unit
      ]

      service = described_class.new(recipe, user, ingredients_data)
      result = service.create_ingredients

      new_unit = Unit.find_by(name: 'gallon')
      expect(new_unit.category).to eq('volume')
    end

    it 'attempts to determine the correct category for new weight units' do
      ingredients_data = [
        { name: 'flour', quantity: 500, unit_name: 'kilogram' } # Weight unit
      ]

      service = described_class.new(recipe, user, ingredients_data)
      result = service.create_ingredients

      new_unit = Unit.find_by(name: 'kilogram')
      expect(new_unit.category).to eq('weight')
    end

    it 'attempts to determine the correct category for new length units' do
      ingredients_data = [
        { name: 'cinnamon stick', quantity: 2, unit_name: 'inch' } # Length unit
      ]

      service = described_class.new(recipe, user, ingredients_data)
      result = service.create_ingredients

      new_unit = Unit.find_by(name: 'inch')
      expect(new_unit.category).to eq('length')
    end

    it 'defaults to the "whole" unit when no unit is provided' do
      ingredients_data = [
        { name: 'eggs', quantity: 3, unit_name: nil }
      ]

      service = described_class.new(recipe, user, ingredients_data)
      result = service.create_ingredients

      eggs_ingredient = RecipeIngredient.find_by(name: 'eggs')
      expect(eggs_ingredient.unit.name).to eq('whole')
    end

    it 'handles failure during unit creation gracefully' do
      ingredients_data = [
        { name: 'carrots', quantity: 3, unit_name: 'invalid_unit' }
      ]

      # Mock Unit.create! to fail for this specific unit name
      allow(Unit).to receive(:create!).with(
        hash_including(name: 'invalid_unit'),
        any_args
      ).and_raise(StandardError.new("Database error"))

      # Should fall back to whole unit
      service = described_class.new(recipe, user, ingredients_data)
      result = service.create_ingredients

      expect(result[:success]).to be true
      carrots_ingredient = RecipeIngredient.find_by(name: 'carrots')
      expect(carrots_ingredient.unit).to eq(whole_unit)
    end
  end

  describe 'grocery matching' do
    it 'matches groceries case-insensitively' do
      # Create a grocery with uppercase name
      create(:grocery, name: 'SALT', user: user, unit: whole_unit)

      ingredients_data = [
        { name: 'salt', quantity: 1, unit_name: 'whole' } # Lowercase name
      ]

      service = described_class.new(recipe, user, ingredients_data)
      result = service.create_ingredients

      salt_ingredient = RecipeIngredient.find_by(name: 'salt')
      expect(salt_ingredient.grocery.name).to eq('SALT')
    end

    it 'handles ingredients without matching groceries' do
      ingredients_data = [
        { name: 'cinnamon', quantity: 1, unit_name: 'teaspoon' } # No matching grocery
      ]

      service = described_class.new(recipe, user, ingredients_data)
      result = service.create_ingredients

      cinnamon_ingredient = RecipeIngredient.find_by(name: 'cinnamon')
      expect(cinnamon_ingredient.grocery).to be_nil
      expect(cinnamon_ingredient.name).to eq('cinnamon')
    end

    it 'strips whitespace from ingredient names' do
      # Create a grocery
      create(:grocery, name: 'butter', user: user, unit: cup_unit)

      ingredients_data = [
        { name: '  butter  ', quantity: 0.5, unit_name: 'cup' } # Extra whitespace
      ]

      service = described_class.new(recipe, user, ingredients_data)
      result = service.create_ingredients

      butter_ingredient = RecipeIngredient.find_by(name: 'butter')
      expect(butter_ingredient.name).to eq('butter') # Should be trimmed
    end
  end

  describe 'integration tests for complex scenarios' do
    it 'handles a mix of existing and new units and groceries' do
      # This test verifies the service can handle mixed scenarios with:
      # - Known groceries with known units
      # - Known groceries with unknown units
      # - Unknown groceries with known units
      # - Unknown groceries with unknown units

      ingredients_data = [
        { name: 'flour', quantity: 2, unit_name: 'cup' },       # Known grocery, known unit
        { name: 'sugar', quantity: 1, unit_name: 'handful' },   # Known grocery, new unit
        { name: 'cinnamon', quantity: 1, unit_name: 'tsp' },    # New grocery, known unit
        { name: 'vanilla pod', quantity: 1, unit_name: 'whole' } # New grocery, known unit
      ]

      service = described_class.new(recipe, user, ingredients_data)

      expect {
        result = service.create_ingredients
        expect(result[:success]).to be true
      }.to change(Unit, :count).by(1) # Only 'handful' should be new
                               .and change(RecipeIngredient, :count).by(4)

      flour_ingredient = RecipeIngredient.find_by(name: 'flour')
      sugar_ingredient = RecipeIngredient.find_by(name: 'sugar')
      cinnamon_ingredient = RecipeIngredient.find_by(name: 'cinnamon')
      vanilla_ingredient = RecipeIngredient.find_by(name: 'vanilla pod')

      expect(flour_ingredient.grocery).to eq(flour)
      expect(flour_ingredient.unit).to eq(cup_unit)

      expect(sugar_ingredient.grocery).to eq(sugar)
      expect(sugar_ingredient.unit.name).to eq('handful')

      expect(cinnamon_ingredient.grocery).to be_nil
      expect(cinnamon_ingredient.unit).to eq(teaspoon_unit)

      expect(vanilla_ingredient.grocery).to be_nil
      expect(vanilla_ingredient.unit).to eq(whole_unit)
    end

    it 'processes a complex list of ingredients with various edge cases' do
      # This test creates a more realistic scenario with various edge cases

      ingredients_data = [
        { name: 'flour', quantity: 2.5, unit_name: 'cups' },         # Plural unit
        { name: '  sugar  ', quantity: 1, unit_name: 'c.' },         # Whitespace + abbrev with period
        { name: 'EGGS', quantity: 3, unit_name: nil },               # Uppercase + nil unit
        { name: 'vanilla extract', quantity: 0.5, unit_name: 'tsp' }, # Multi-word name
        { name: '', quantity: 1, unit_name: 'tbsp' }                 # Empty name - should fail
      ]

      # Mock the error for the empty name ingredient
      allow(recipe.recipe_ingredients).to receive(:create!).and_call_original
      allow(recipe.recipe_ingredients).to receive(:create!).with(
        hash_including(name: ''),
        any_args
      ).and_raise(ActiveRecord::RecordInvalid, "Validation failed: Name can't be blank")

      service = described_class.new(recipe, user, ingredients_data)

      result = service.create_ingredients

      expect(result[:success]).to be false # Should fail due to empty name
      expect(result[:errors]).not_to be_empty

      # But should still create the valid ingredients
      expect(RecipeIngredient.find_by(name: 'flour')).not_to be_nil
      expect(RecipeIngredient.find_by(name: 'sugar')).not_to be_nil
      expect(RecipeIngredient.find_by(name: 'eggs')).not_to be_nil
      expect(RecipeIngredient.find_by(name: 'vanilla extract')).not_to be_nil

      # Verify specific attributes
      flour_ingredient = RecipeIngredient.find_by(name: 'flour')
      expect(flour_ingredient.quantity).to eq(2.5)

      sugar_ingredient = RecipeIngredient.find_by(name: 'sugar')
      expect(sugar_ingredient.unit).to eq(cup_unit)

      eggs_ingredient = RecipeIngredient.find_by(name: 'eggs')
      expect(eggs_ingredient.unit).to eq(whole_unit)
    end
  end
end
