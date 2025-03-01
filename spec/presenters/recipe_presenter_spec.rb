require 'rails_helper'

RSpec.describe RecipePresenter do
  describe '.grouped_recipes' do
    it 'groups recipes by category' do
      # Create categories
      category1 = create(:recipe_category, name: 'Breakfast', display_order: 1)
      category2 = create(:recipe_category, name: 'Dinner', display_order: 2)

      # Create recipes in those categories
      recipe1 = create(:recipe, recipe_category: category1, name: 'Pancakes')
      recipe2 = create(:recipe, recipe_category: category1, name: 'Waffles')
      recipe3 = create(:recipe, recipe_category: category2, name: 'Pasta')

      # Get all categories and recipes
      categories = [ category1, category2 ]
      recipes = [ recipe1, recipe2, recipe3 ]

      # Call the method
      result = RecipePresenter.grouped_recipes(recipes, categories)

      # Verify the structure
      expect(result.keys).to contain_exactly('Breakfast', 'Dinner')
      expect(result['Breakfast'][:id]).to eq(category1.id)
      expect(result['Breakfast'][:display_order]).to eq(1)
      expect(result['Breakfast'][:items].map { |i| i[:name] }).to contain_exactly('Pancakes', 'Waffles')
      expect(result['Dinner'][:items].map { |i| i[:name] }).to contain_exactly('Pasta')
    end

    it 'includes empty categories' do
      # Create categories
      category1 = create(:recipe_category, name: 'Breakfast', display_order: 1)
      category2 = create(:recipe_category, name: 'Dinner', display_order: 2)
      category3 = create(:recipe_category, name: 'Dessert', display_order: 3) # Empty category

      # Create recipes in only some categories
      recipe1 = create(:recipe, recipe_category: category1, name: 'Pancakes')
      recipe2 = create(:recipe, recipe_category: category2, name: 'Pasta')

      # Get all categories but only recipes from some categories
      categories = [ category1, category2, category3 ]
      recipes = [ recipe1, recipe2 ]

      # Call the method
      result = RecipePresenter.grouped_recipes(recipes, categories)

      # Verify the empty category is included
      expect(result.keys).to contain_exactly('Breakfast', 'Dinner', 'Dessert')
      expect(result['Dessert'][:items]).to eq([])
      expect(result['Dessert'][:id]).to eq(category3.id)
      expect(result['Dessert'][:display_order]).to eq(3)
    end

    it 'formats recipes correctly' do
      # Create category and recipe
      category = create(:recipe_category, name: 'Breakfast')
      recipe = create(:recipe,
                      recipe_category: category,
                      name: 'French Toast',
                      instructions: 'Dip bread in egg mixture and cook',
                      notes: 'Use day-old bread',
                      completed: true,
                      completed_at: Time.current)

      # Call the method
      result = RecipePresenter.grouped_recipes([ recipe ], [ category ])

      # Verify formatting details
      formatted_recipe = result['Breakfast'][:items].first
      expect(formatted_recipe[:id]).to eq(recipe.id)
      expect(formatted_recipe[:name]).to eq('French Toast')
      expect(formatted_recipe[:instructions]).to eq('Dip bread in egg mixture and cook')
      expect(formatted_recipe[:notes]).to eq('Use day-old bread')
      expect(formatted_recipe[:completed]).to be true
      expect(formatted_recipe[:completed_at]).to be_present
      expect(formatted_recipe[:emoji]).to eq('U+1F37D')
    end
  end

  describe '.grouped_recipes_with_availability' do
    it 'includes availability information' do
      # Create user, category, and recipe
      user = create(:user)
      category = create(:recipe_category, name: 'Breakfast', user: user)
      recipe = create(:recipe, recipe_category: category, name: 'Pancakes', user: user)

      # Set up a checker that will return true for availability
      availability_checker = instance_double(RecipeServices::AvailabilityChecker, available?: true)
      allow(RecipeServices::AvailabilityChecker).to receive(:new).and_return(availability_checker)

      # Call the method
      result = RecipePresenter.grouped_recipes_with_availability([ recipe ], [ category ], user)

      # Verify availability info is included
      formatted_recipe = result['Breakfast'][:items].first
      expect(formatted_recipe[:can_make]).to be true
    end

    it 'handles empty categories with availability information' do
      # Create user and categories
      user = create(:user)
      category1 = create(:recipe_category, name: 'Breakfast', display_order: 1, user: user)
      category2 = create(:recipe_category, name: 'Dessert', display_order: 2, user: user) # Empty category

      # Create recipe in only one category
      recipe = create(:recipe, recipe_category: category1, name: 'Pancakes', user: user)

      # Set up a checker that will return true for availability
      availability_checker = instance_double(RecipeServices::AvailabilityChecker, available?: true)
      allow(RecipeServices::AvailabilityChecker).to receive(:new).and_return(availability_checker)

      # Call the method
      result = RecipePresenter.grouped_recipes_with_availability([ recipe ], [ category1, category2 ], user)

      # Verify empty category is included
      expect(result.keys).to contain_exactly('Breakfast', 'Dessert')
      expect(result['Dessert'][:items]).to eq([])
      expect(result['Breakfast'][:items].first[:can_make]).to be true
    end

    it 'preloads groceries to avoid N+1 queries' do
      # Create user, category, and recipes
      user = create(:user)
      category = create(:recipe_category, name: 'Breakfast', user: user)
      recipe1 = create(:recipe, recipe_category: category, name: 'Pancakes', user: user)
      recipe2 = create(:recipe, recipe_category: category, name: 'Waffles', user: user)

      # Create grocery items for the user
      cup_unit = create(:unit, name: 'cup')
      create(:grocery, name: 'flour', user: user, unit: cup_unit, quantity: 5)
      create(:grocery, name: 'milk', user: user, unit: cup_unit, quantity: 2)

      # Verify that user.groceries is only called once to preload
      expect(user).to receive(:groceries).once.and_call_original

      # Call the method - with 2 recipes, this would normally cause N+1 queries
      # but our optimized version should only load groceries once
      RecipePresenter.grouped_recipes_with_availability([ recipe1, recipe2 ], [ category ], user)
    end
  end

  describe '.format_recipe_with_availability' do
    it 'adds availability flag to recipe data' do
      # Create user, category, and recipe
      user = create(:user)
      category = create(:recipe_category, name: 'Breakfast', user: user)
      recipe = create(:recipe, recipe_category: category, name: 'Pancakes', user: user)

      # Set up a checker that will return true for availability
      availability_checker = instance_double(RecipeServices::AvailabilityChecker, available?: true)
      allow(RecipeServices::AvailabilityChecker).to receive(:new).and_return(availability_checker)

      # Call the private method using send
      result = RecipePresenter.send(:format_recipe_with_availability, recipe, user)

      # Verify the result
      expect(result[:name]).to eq('Pancakes')
      expect(result[:can_make]).to be true
    end
  end
end
