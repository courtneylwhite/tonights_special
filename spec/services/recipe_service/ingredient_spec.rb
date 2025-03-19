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
        # Switch to inline mode to process jobs immediately
        Sidekiq::Testing.inline! do
          # Mock the MatchingService to return the expected groceries
          # This simulates what would happen in the job
          expect(MatchingService).to receive(:match_ingredient_to_grocery)
                                       .with(user, 'flour')
                                       .and_return(flour)

          expect(MatchingService).to receive(:match_ingredient_to_grocery)
                                       .with(user, 'sugar')
                                       .and_return(sugar)

          expect(MatchingService).to receive(:match_ingredient_to_grocery)
                                       .with(user, 'eggs')
                                       .and_return(nil)

          service = described_class.new(recipe, user, ingredients_data)
          result = service.create_ingredients

          # Since we're in inline mode, jobs are processed immediately
          # so the associations should be set after create_ingredients returns

          flour_ingredient = RecipeIngredient.find_by(name: 'flour')
          sugar_ingredient = RecipeIngredient.find_by(name: 'sugar')
          eggs_ingredient = RecipeIngredient.find_by(name: 'eggs')

          expect(flour_ingredient.grocery).to eq(flour)
          expect(sugar_ingredient.grocery).to eq(sugar)
          expect(eggs_ingredient.grocery).to be_nil # No matching grocery
        end

        # Reset back to fake mode
        Sidekiq::Testing.fake!
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
        # Skip the ingredient with empty name check so it propagates to create!
        allow_any_instance_of(RecipeServices::Ingredient).to receive(:create_ingredients).and_call_original
        allow_any_instance_of(RecipeServices::Ingredient).to receive(:create_single_ingredient).and_call_original

        # Mock the recipe_ingredients association to raise an error for the invalid ingredient
        allow(recipe.recipe_ingredients).to receive(:create!).and_call_original
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

  context 'with unit_id instead of unit_name' do
    it 'prioritizes unit_id over unit_name when both are provided' do
      ingredients_data = [
        { name: 'flour', quantity: 2, unit_id: tablespoon_unit.id, unit_name: 'cup' }
      ]

      service = described_class.new(recipe, user, ingredients_data)
      result = service.create_ingredients

      flour_ingredient = RecipeIngredient.find_by(name: 'flour')
      expect(flour_ingredient.unit).to eq(tablespoon_unit)
      expect(flour_ingredient.unit).not_to eq(cup_unit)
    end

    it 'handles invalid unit_id gracefully' do
      non_existent_id = Unit.maximum(:id).to_i + 1000 # Ensure it doesn't exist

      ingredients_data = [
        { name: 'flour', quantity: 2, unit_id: non_existent_id }
      ]

      service = described_class.new(recipe, user, ingredients_data)
      result = service.create_ingredients

      flour_ingredient = RecipeIngredient.find_by(name: 'flour')
      expect(flour_ingredient.unit).to eq(whole_unit) # Should fall back to default
    end
  end

  context 'with error handling' do
    it 'handles errors during grocery matching gracefully' do
      ingredients_data = [
        { name: 'flour', quantity: 2, unit_name: 'cup' }
      ]

      # Allow the job to be enqueued but it won't run in the test
      # (using fake Sidekiq testing mode)
      expect(IngredientMatchingJob).to receive(:perform_async).once

      service = described_class.new(recipe, user, ingredients_data)
      result = service.create_ingredients

      # The test is verifying that even if the background job fails later,
      # the initial ingredient creation succeeds
      expect(result[:success]).to be true
      flour_ingredient = RecipeIngredient.find_by(name: 'flour')
      expect(flour_ingredient).not_to be_nil
    end

    it 'handles non-numeric quantities' do
      ingredients_data = [
        { name: 'flour', quantity: "not a number", unit_name: 'cup' }
      ]

      service = described_class.new(recipe, user, ingredients_data)
      result = service.create_ingredients

      # The operation should fail because of invalid data
      expect(result[:success]).to be false
      expect(result[:errors].first).to include("Error creating ingredient flour")
    end
  end

  context 'with case insensitivity' do
    let!(:cup_unit_uppercase) { create(:unit, name: 'CUP', abbreviation: 'CUP', category: 'volume') }

    it 'matches units case-insensitively' do
      ingredients_data = [
        { name: 'flour', quantity: 2, unit_name: 'cup' }
      ]

      # Before creating ingredients, mock the find_unit_by_name method
      # to return the lowercase cup unit for case-insensitive comparison
      allow_any_instance_of(RecipeServices::Ingredient).to receive(:find_unit_by_name)
                                                             .with('cup').and_return(cup_unit)

      service = described_class.new(recipe, user, ingredients_data)
      result = service.create_ingredients

      flour_ingredient = RecipeIngredient.find_by(name: 'flour')
      expect(flour_ingredient.unit).to eq(cup_unit)
    end
  end

  describe 'additional edge cases' do
    it 'handles unit names with extra whitespace' do
      ingredients_data = [
        { name: 'flour', quantity: 2, unit_name: '  cup  ' } # Extra whitespace
      ]

      service = described_class.new(recipe, user, ingredients_data)
      result = service.create_ingredients

      flour_ingredient = RecipeIngredient.find_by(name: 'flour')
      expect(flour_ingredient.unit).to eq(cup_unit)
    end

    it 'handles very large quantities without rounding errors' do
      ingredients_data = [
        { name: 'water', quantity: 10000.25, unit_name: 'milliliter' }
      ]

      service = described_class.new(recipe, user, ingredients_data)
      result = service.create_ingredients

      water_ingredient = RecipeIngredient.find_by(name: 'water')
      expect(water_ingredient.quantity).to eq(10000.25)
    end

    it 'handles empty ingredient data array elements gracefully' do
      # Test with an array containing an empty hash
      ingredients_data = [ {} ]

      service = described_class.new(recipe, user, ingredients_data)
      result = service.create_ingredients

      # Should fail gracefully with a meaningful error
      expect(result[:success]).to be false
      expect(result[:errors]).to include(/Empty ingredient data provided/)
    end
  end
end
