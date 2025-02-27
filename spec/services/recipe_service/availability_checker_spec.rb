require 'rails_helper'

RSpec.describe RecipeServices::AvailabilityChecker do
  let(:user) { create(:user) }
  let(:recipe_category) { create(:recipe_category, user: user) }
  let(:recipe) { create(:recipe, user: user, recipe_category: recipe_category) }

  let(:cup_unit) { create(:unit, name: 'cup', abbreviation: 'c', category: 'volume') }
  let(:tablespoon_unit) { create(:unit, name: 'tablespoon', abbreviation: 'tbsp', category: 'volume') }
  let(:whole_unit) { create(:unit, name: 'whole', abbreviation: 'pcs', category: 'count') }

  let(:flour) { create(:grocery, name: 'flour', user: user, unit: cup_unit, quantity: 3) }
  let(:eggs) { create(:grocery, name: 'eggs', user: user, unit: whole_unit, quantity: 6) }
  let(:butter) { create(:grocery, name: 'butter', user: user, unit: tablespoon_unit, quantity: 8) }
  let(:sugar) { create(:grocery, name: 'sugar', user: user, unit: cup_unit, quantity: 1) }

  before do
    # Create recipe ingredients
    create(:recipe_ingredient, recipe: recipe, grocery: flour, unit: cup_unit, quantity: 2, name: 'flour')
    create(:recipe_ingredient, recipe: recipe, grocery: eggs, unit: whole_unit, quantity: 3, name: 'eggs')
    create(:recipe_ingredient, recipe: recipe, grocery: butter, unit: tablespoon_unit, quantity: 6, name: 'butter')
    create(:recipe_ingredient, recipe: recipe, grocery: sugar, unit: cup_unit, quantity: 2, name: 'sugar')
  end

  describe '#available?' do
    context 'when all ingredients are available in sufficient quantities' do
      it 'returns true' do
        checker = described_class.new(user, recipe)
        expect(checker.available?).to be false  # Sugar is not enough (need 2, have 1)

        # Update sugar quantity to be sufficient
        sugar.update(quantity: 2)
        expect(checker.available?).to be true
      end
    end

    context 'when some ingredients are not available in sufficient quantities' do
      it 'returns false' do
        # Reduce flour quantity to be insufficient
        flour.update(quantity: 1)

        checker = described_class.new(user, recipe)
        expect(checker.available?).to be false
      end
    end

    context 'when an ingredient has no grocery association' do
      it 'skips that ingredient in availability check' do
        # Create a recipe ingredient without a grocery association
        create(:recipe_ingredient, recipe: recipe, grocery: nil, unit: cup_unit, quantity: 1, name: 'cinnamon')

        # If all other ingredients are available, it should still return true
        sugar.update(quantity: 2)  # Make sure we have enough sugar

        checker = described_class.new(user, recipe)
        expect(checker.available?).to be true
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

    context 'when all ingredients are available' do
      it 'returns an empty missing_ingredients array' do
        # Update sugar to have enough
        sugar.update(quantity: 2)

        checker = described_class.new(user, recipe)
        result = checker.availability_info

        expect(result[:available]).to be true
        expect(result[:missing_ingredients]).to be_empty
      end
    end

    context 'when some ingredients are missing or insufficient' do
      it 'includes them in the missing_ingredients array' do
        # Make sure sugar is insufficient
        sugar.update(quantity: 1)

        checker = described_class.new(user, recipe)
        result = checker.availability_info

        expect(result[:available]).to be false
        expect(result[:missing_ingredients]).not_to be_empty

        # Check that sugar is in the missing ingredients
        missing_sugar = result[:missing_ingredients].find { |i| i[:name] == 'sugar' }
        expect(missing_sugar).not_to be_nil
        expect(missing_sugar[:required]).to eq(2)
        expect(missing_sugar[:available]).to eq(1)
      end
    end

    it 'includes unit information for missing ingredients' do
      # Make multiple ingredients insufficient
      flour.update(quantity: 1)
      sugar.update(quantity: 0.5)

      checker = described_class.new(user, recipe)
      result = checker.availability_info

      missing_flour = result[:missing_ingredients].find { |i| i[:name] == 'flour' }
      expect(missing_flour[:required_unit]).to eq('cup')
      expect(missing_flour[:available_unit]).to eq('cup')

      missing_sugar = result[:missing_ingredients].find { |i| i[:name] == 'sugar' }
      expect(missing_sugar[:required_unit]).to eq('cup')
      expect(missing_sugar[:available_unit]).to eq('cup')
    end
  end

  # Tests for the private method convert_to_common_unit
  describe '#convert_to_common_unit (private method)' do
    let(:checker) { described_class.new(user, recipe) }
    let(:milliliter_unit) { create(:unit, name: 'milliliter', abbreviation: 'ml', category: 'volume') }
    let(:teaspoon_unit) { create(:unit, name: 'teaspoon', abbreviation: 'tsp', category: 'volume') }
    let(:gram_unit) { create(:unit, name: 'gram', abbreviation: 'g', category: 'weight') }

    context 'when units are the same' do
      it 'returns the original quantity' do
        result = checker.send(:convert_to_common_unit, 2.5, cup_unit, cup_unit)
        expect(result).to eq(2.5)
      end
    end

    context 'when there is a direct conversion' do
      it 'returns the converted quantity' do
        # Create a conversion from tablespoon to cup
        conversion_factor = 0.0625 # 1 tbsp = 0.0625 cup
        create(:unit_conversion, from_unit: tablespoon_unit, to_unit: cup_unit, conversion_factor: conversion_factor)

        result = checker.send(:convert_to_common_unit, 16, tablespoon_unit, cup_unit)
        expect(result).to eq(16 * conversion_factor)
      end
    end

    context 'when only a reverse conversion exists' do
      it 'uses the inverse of the conversion factor' do
        # Create a conversion from cup to tablespoon
        conversion_factor = 16.0 # 1 cup = 16 tbsp (using float to avoid integer division)
        create(:unit_conversion, from_unit: cup_unit, to_unit: tablespoon_unit, conversion_factor: conversion_factor)

        result = checker.send(:convert_to_common_unit, 2, tablespoon_unit, cup_unit)
        expect(result).to eq(0.125) # 2/16 = 0.125 cups
      end
    end

    context 'when units are in the same category but no direct conversion' do
      it 'returns nil' do
        # Creating units in the same category without a direct conversion
        result = checker.send(:convert_to_common_unit, 100, milliliter_unit, teaspoon_unit)
        expect(result).to be_nil
      end
    end

    context 'when units are in different categories' do
      it 'returns nil' do
        result = checker.send(:convert_to_common_unit, 100, gram_unit, cup_unit)
        expect(result).to be_nil
      end
    end
  end
end
