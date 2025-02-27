require 'rails_helper'

RSpec.describe RecipeServices::Creator do
  let(:user) { create(:user) }
  let(:recipe_category) { create(:recipe_category, user: user) }

  describe '#create' do
    context 'with valid recipe parameters' do
      let(:recipe_params) {
        ActionController::Parameters.new({
                                           recipe: {
                                             name: 'Chocolate Cake',
                                             instructions: "1. Mix ingredients\n2. Bake at 350°F for 30 minutes",
                                             notes: "Mom's recipe"
                                           },
                                           new_category: nil
                                         })
      }

      before do
        # Modify recipe_params to include the category ID
        recipe_params[:recipe][:recipe_category_id] = recipe_category.id
      end

      it 'creates a new recipe' do
        service = described_class.new(user, recipe_params)

        expect {
          result = service.create
          expect(result[:success]).to be true
        }.to change(Recipe, :count).by(1)
      end

      it 'associates the recipe with the user and category' do
        service = described_class.new(user, recipe_params)
        result = service.create

        recipe = result[:recipe]
        expect(recipe.user).to eq(user)
        expect(recipe.recipe_category).to eq(recipe_category)
      end

      it 'sets the recipe attributes correctly' do
        service = described_class.new(user, recipe_params)
        result = service.create

        recipe = result[:recipe]
        expect(recipe.name).to eq('Chocolate Cake')
        expect(recipe.instructions).to include('Mix ingredients')
        expect(recipe.notes).to eq("Mom's recipe")
      end
    end

    context 'when creating a new category' do
      let(:recipe_params) {
        ActionController::Parameters.new({
                                           recipe: {
                                             name: 'Chocolate Cake',
                                             instructions: "1. Mix ingredients\n2. Bake at 350°F for 30 minutes",
                                             notes: "Mom's recipe"
                                           },
                                           new_category: {
                                             name: 'Desserts',
                                             display_order: 1
                                           }
                                         })
      }

      it 'creates both a new category and recipe' do
        # Create a real category first
        dessert_category = create(:recipe_category, name: 'Desserts', user: user)

        # Mock the category service to return the real category
        category_service = instance_double(RecipeServices::Category)
        allow(RecipeServices::Category).to receive(:new).with(user, anything).and_return(category_service)
        allow(category_service).to receive(:create_new_category).and_return({
                                                                              success: true,
                                                                              category: dessert_category
                                                                            })

        service = described_class.new(user, recipe_params)

        expect {
          result = service.create
          expect(result[:success]).to be true
        }.to change(Recipe, :count).by(1)
      end

      it 'associates the recipe with the new category' do
        # Create a real category first
        dessert_category = create(:recipe_category, name: 'Desserts', user: user)

        # Mock the category service to return the real category
        category_service = instance_double(RecipeServices::Category)
        allow(RecipeServices::Category).to receive(:new).with(user, anything).and_return(category_service)
        allow(category_service).to receive(:create_new_category).and_return({
                                                                              success: true,
                                                                              category: dessert_category
                                                                            })

        service = described_class.new(user, recipe_params)
        result = service.create

        expect(result[:success]).to be true
        recipe = result[:recipe]
        expect(recipe.recipe_category).to eq(dessert_category)
      end
    end

    context 'when category creation fails' do
      let(:recipe_params) {
        ActionController::Parameters.new({
                                           recipe: {
                                             name: 'Chocolate Cake',
                                             instructions: "1. Mix ingredients\n2. Bake at 350°F for 30 minutes",
                                             notes: "Mom's recipe"
                                           },
                                           new_category: {
                                             name: '' # Invalid: empty name
                                           }
                                         })
      }

      it 'returns failure and does not create a recipe' do
        # Mock the category service to return failure
        category_service = instance_double(RecipeServices::Category)
        allow(RecipeServices::Category).to receive(:new).with(user, anything).and_return(category_service)
        allow(category_service).to receive(:create_new_category).and_return({
                                                                              success: false,
                                                                              errors: [ "Category name can't be blank" ]
                                                                            })

        service = described_class.new(user, recipe_params)

        expect {
          result = service.create
          expect(result[:success]).to be false
          expect(result[:errors]).to include('Failed to create category')
        }.not_to change(Recipe, :count)
      end
    end

    context 'with instructions that include ingredient data' do
      let(:recipe_params) {
        ActionController::Parameters.new({
                                           recipe: {
                                             name: 'Chocolate Cake',
                                             instructions: "Ingredients:\n2 cups flour\n1 cup sugar\n3 eggs\n\nInstructions:\n1. Mix ingredients\n2. Bake at 350°F",
                                             notes: "Mom's recipe",
                                             recipe_category_id: recipe_category.id
                                           }
                                         })
      }

      it 'parses ingredients from instructions' do
        # Mock the parser
        parser = instance_double(RecipeServices::Parser)
        parsed_data = {
          ingredients: [
            { name: 'flour', quantity: 2, unit_name: 'cup' },
            { name: 'sugar', quantity: 1, unit_name: 'cup' },
            { name: 'eggs', quantity: 3, unit_name: 'whole' }
          ],
          instructions: "1. Mix ingredients\n2. Bake at 350°F"
        }

        allow(RecipeServices::Parser).to receive(:new).and_return(parser)
        allow(parser).to receive(:parse).and_return(parsed_data)

        # Mock the ingredient service
        ingredient_service = instance_double(RecipeServices::Ingredient)
        allow(RecipeServices::Ingredient).to receive(:new).and_return(ingredient_service)
        allow(ingredient_service).to receive(:create_ingredients).and_return({ success: true, ingredients: [] })

        service = described_class.new(user, recipe_params)

        expect {
          result = service.create
          expect(result[:success]).to be true
        }.to change(Recipe, :count).by(1)

        # Verify that the instructions were updated
        created_recipe = Recipe.last
        expect(created_recipe.instructions).to eq("1. Mix ingredients\n2. Bake at 350°F")
      end

      it 'handles ingredient creation failures gracefully' do
        # Mock the parser
        parser = instance_double(RecipeServices::Parser)
        parsed_data = {
          ingredients: [
            { name: 'flour', quantity: 2, unit_name: 'cup' }
          ],
          instructions: "1. Mix ingredients\n2. Bake at 350°F"
        }

        allow(RecipeServices::Parser).to receive(:new).and_return(parser)
        allow(parser).to receive(:parse).and_return(parsed_data)

        # Mock the ingredient service to fail
        ingredient_service = instance_double(RecipeServices::Ingredient)
        allow(RecipeServices::Ingredient).to receive(:new).and_return(ingredient_service)
        allow(ingredient_service).to receive(:create_ingredients).and_return({
                                                                               success: false,
                                                                               errors: [ 'Invalid ingredient data' ]
                                                                             })

        service = described_class.new(user, recipe_params)
        result = service.create

        expect(result[:success]).to be true
        expect(result[:warnings]).to include(/some ingredients could not be created/)
      end
    end

    context 'with invalid recipe parameters' do
      let(:invalid_params) {
        ActionController::Parameters.new({
                                           recipe: {
                                             name: '', # Invalid: empty name
                                             instructions: "Mix and bake",
                                             notes: "Test",
                                             recipe_category_id: recipe_category.id
                                           }
                                         })
      }

      it 'returns failure and error messages' do
        service = described_class.new(user, invalid_params)
        result = service.create

        expect(result[:success]).to be false
        expect(result[:errors]).not_to be_empty
      end

      it 'does not create a recipe' do
        service = described_class.new(user, invalid_params)

        expect {
          result = service.create
        }.not_to change(Recipe, :count)
      end
    end

    context 'with empty instructions' do
      let(:recipe_params) {
        ActionController::Parameters.new({
                                           recipe: {
                                             name: 'Invalid Recipe',
                                             instructions: "", # Empty instructions which isn't allowed
                                             notes: "Test recipe",
                                             recipe_category_id: recipe_category.id
                                           }
                                         })
      }

      it 'fails validation due to required instructions' do
        service = described_class.new(user, recipe_params)

        expect {
          result = service.create
          expect(result[:success]).to be false
          expect(result[:errors]).to include(/instructions/i)
        }.not_to change(Recipe, :count)
      end
    end

    context 'with minimal valid instructions' do
      let(:recipe_params) {
        ActionController::Parameters.new({
                                           recipe: {
                                             name: 'Minimal Instructions Recipe',
                                             instructions: "Simple steps", # Minimal but valid instructions
                                             notes: "Test recipe",
                                             recipe_category_id: recipe_category.id
                                           }
                                         })
      }

      it 'creates a recipe with minimal instructions' do
        # Mock a simple parser that doesn't find ingredients
        parser = instance_double(RecipeServices::Parser)
        allow(RecipeServices::Parser).to receive(:new).and_return(parser)
        allow(parser).to receive(:parse).and_return({
                                                      ingredients: [],
                                                      instructions: "Simple steps"
                                                    })

        service = described_class.new(user, recipe_params)

        expect {
          result = service.create
          expect(result[:success]).to be true
        }.to change(Recipe, :count).by(1)
      end
    end

    context 'when no recipe_category_id is provided' do
      let(:recipe_params) {
        ActionController::Parameters.new({
                                           recipe: {
                                             name: 'No Category Recipe',
                                             instructions: "Simple instructions",
                                             notes: "Test recipe"
                                             # No recipe_category_id
                                           }
                                         })
        # No new_category
      }

      it 'returns error due to missing category' do
        service = described_class.new(user, recipe_params)

        expect {
          result = service.create
          expect(result[:success]).to be false
          expect(result[:errors]).to include(/recipe category/i)
        }.not_to change(Recipe, :count)
      end
    end

    context 'with a complex scenario' do
      let(:recipe_params) {
        ActionController::Parameters.new({
                                           recipe: {
                                             name: 'Chocolate Cake',
                                             instructions: "Ingredients:\n2 cups flour\n1 cup sugar\n3 eggs\n\nInstructions:\n1. Mix ingredients\n2. Bake at 350°F",
                                             notes: "Mom's recipe"
                                           },
                                           new_category: {
                                             name: 'Desserts',
                                             display_order: 1
                                           }
                                         })
      }

      it 'creates a recipe with ingredients and a new category' do
        # Create a real category first
        dessert_category = create(:recipe_category, name: 'Desserts', user: user)

        # Mock the category service to return the real category
        category_service = instance_double(RecipeServices::Category)
        allow(RecipeServices::Category).to receive(:new).with(user, anything).and_return(category_service)
        allow(category_service).to receive(:create_new_category).and_return({
                                                                              success: true,
                                                                              category: dessert_category
                                                                            })

        # Mock the parser
        parser = instance_double(RecipeServices::Parser)
        parsed_data = {
          ingredients: [
            { name: 'flour', quantity: 2, unit_name: 'cup' },
            { name: 'sugar', quantity: 1, unit_name: 'cup' },
            { name: 'eggs', quantity: 3, unit_name: 'whole' }
          ],
          instructions: "1. Mix ingredients\n2. Bake at 350°F"
        }

        allow(RecipeServices::Parser).to receive(:new).and_return(parser)
        allow(parser).to receive(:parse).and_return(parsed_data)

        # Mock the ingredient service
        ingredient_service = instance_double(RecipeServices::Ingredient)
        allow(RecipeServices::Ingredient).to receive(:new).and_return(ingredient_service)
        allow(ingredient_service).to receive(:create_ingredients).and_return({ success: true, ingredients: [] })

        service = described_class.new(user, recipe_params)

        expect {
          result = service.create
          expect(result[:success]).to be true

          recipe = result[:recipe]
          expect(recipe.name).to eq('Chocolate Cake')
          expect(recipe.recipe_category).to eq(dessert_category)
          expect(recipe.instructions).to eq("1. Mix ingredients\n2. Bake at 350°F")
        }.to change(Recipe, :count).by(1)
      end
    end
  end
end
