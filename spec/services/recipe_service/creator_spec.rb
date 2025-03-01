require 'rails_helper'

RSpec.describe RecipeServices::Creator do
  let(:user) { create(:user) }
  let(:recipe_category) { create(:recipe_category, user: user) }

  describe '#create' do
    context 'with valid recipe parameters' do
      let(:recipe_attributes) {
        {
          name: 'Chocolate Cake',
          instructions: "1. Mix ingredients\n2. Bake at 350°F for 30 minutes",
          notes: "Mom's recipe",
          recipe_category_id: recipe_category.id
        }
      }

      it 'creates a new recipe' do
        service = described_class.new(user, recipe_attributes)

        expect {
          result = service.create
          expect(result[:success]).to be true
        }.to change(Recipe, :count).by(1)
      end

      it 'associates the recipe with the user and category' do
        service = described_class.new(user, recipe_attributes)
        result = service.create

        recipe = result[:recipe]
        expect(recipe.user).to eq(user)
        expect(recipe.recipe_category).to eq(recipe_category)
      end

      it 'sets the recipe attributes correctly' do
        service = described_class.new(user, recipe_attributes)
        result = service.create

        recipe = result[:recipe]
        expect(recipe.name).to eq('Chocolate Cake')
        expect(recipe.instructions).to include('Mix ingredients')
        expect(recipe.notes).to eq("Mom's recipe")
      end
    end

    context 'when creating a new category' do
      let(:recipe_attributes) {
        {
          name: 'Chocolate Cake',
          instructions: "1. Mix ingredients\n2. Bake at 350°F for 30 minutes",
          notes: "Mom's recipe"
        }
      }

      let(:new_category_params) {
        {
          name: 'Desserts',
          display_order: 1
        }
      }

      it 'creates both a new category and recipe' do
        # Create a real category first
        dessert_category = create(:recipe_category, name: 'Desserts', user: user)

        # Mock the category service to return the real category
        category_service = instance_double(RecipeServices::Category)
        allow(RecipeServices::Category).to receive(:new).with(user, new_category_params).and_return(category_service)
        allow(category_service).to receive(:create_new_category).and_return({
                                                                              success: true,
                                                                              category: dessert_category
                                                                            })

        service = described_class.new(user, recipe_attributes)
        service.new_category_params = new_category_params

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
        allow(RecipeServices::Category).to receive(:new).with(user, new_category_params).and_return(category_service)
        allow(category_service).to receive(:create_new_category).and_return({
                                                                              success: true,
                                                                              category: dessert_category
                                                                            })

        service = described_class.new(user, recipe_attributes)
        service.new_category_params = new_category_params
        result = service.create

        expect(result[:success]).to be true
        recipe = result[:recipe]
        expect(recipe.recipe_category).to eq(dessert_category)
      end
    end

    context 'when category creation fails' do
      let(:recipe_attributes) {
        {
          name: 'Chocolate Cake',
          instructions: "1. Mix ingredients\n2. Bake at 350°F for 30 minutes",
          notes: "Mom's recipe"
        }
      }

      let(:invalid_category_params) {
        {
          name: '', # Invalid: empty name
          display_order: 1
        }
      }

      it 'returns failure and does not create a recipe' do
        # Mock the category service to return failure
        category_service = instance_double(RecipeServices::Category)
        allow(RecipeServices::Category).to receive(:new).with(user, invalid_category_params).and_return(category_service)
        allow(category_service).to receive(:create_new_category).and_return({
                                                                              success: false,
                                                                              errors: [ "Category name can't be blank" ]
                                                                            })

        service = described_class.new(user, recipe_attributes)
        service.new_category_params = invalid_category_params

        expect {
          result = service.create
          expect(result[:success]).to be false
          expect(result[:errors]).to include('Failed to create category')
        }.not_to change(Recipe, :count)
      end
    end

    context 'with ingredients to parse' do
      let(:recipe_attributes) {
        {
          name: 'Chocolate Cake',
          ingredients: "2 cups flour\n1 cup sugar\n3 eggs",
          instructions: "1. Mix ingredients\n2. Bake at 350°F",
          notes: "Mom's recipe",
          recipe_category_id: recipe_category.id
        }
      }

      it 'parses ingredients and creates recipe_ingredients' do
        # Mock the parser
        parser = instance_double(RecipeServices::Parser)
        parsed_data = {
          ingredients: [
            { name: 'flour', quantity: 2, unit_name: 'cup' },
            { name: 'sugar', quantity: 1, unit_name: 'cup' },
            { name: 'eggs', quantity: 3, unit_name: 'whole' }
          ],
          notes: []
        }

        allow(RecipeServices::Parser).to receive(:new).with(recipe_attributes[:ingredients]).and_return(parser)
        allow(parser).to receive(:parse_ingredients_only).and_return(parsed_data)

        # Mock the ingredient service
        ingredient_service = instance_double(RecipeServices::Ingredient)
        allow(RecipeServices::Ingredient).to receive(:new).with(
          kind_of(Recipe), user, parsed_data[:ingredients]
        ).and_return(ingredient_service)
        allow(ingredient_service).to receive(:create_ingredients).and_return({
                                                                               success: true,
                                                                               ingredients: []
                                                                             })

        service = described_class.new(user, recipe_attributes)

        expect {
          result = service.create
          expect(result[:success]).to be true
        }.to change(Recipe, :count).by(1)
      end

      it 'handles ingredient creation failures gracefully' do
        # Mock the parser
        parser = instance_double(RecipeServices::Parser)
        parsed_data = {
          ingredients: [
            { name: 'flour', quantity: 2, unit_name: 'cup' }
          ],
          notes: []
        }

        allow(RecipeServices::Parser).to receive(:new).with(recipe_attributes[:ingredients]).and_return(parser)
        allow(parser).to receive(:parse_ingredients_only).and_return(parsed_data)

        # Mock the ingredient service to fail
        ingredient_service = instance_double(RecipeServices::Ingredient)
        allow(RecipeServices::Ingredient).to receive(:new).with(
          kind_of(Recipe), user, parsed_data[:ingredients]
        ).and_return(ingredient_service)
        allow(ingredient_service).to receive(:create_ingredients).and_return({
                                                                               success: false,
                                                                               errors: [ 'Invalid ingredient data' ]
                                                                             })

        service = described_class.new(user, recipe_attributes)
        result = service.create

        expect(result[:success]).to be true
        expect(result[:warnings]).to include(/Some ingredients could not be created/)
      end

      it 'adds extracted notes to the recipe' do
        # Mock the parser with notes
        parser = instance_double(RecipeServices::Parser)
        parsed_data = {
          ingredients: [
            { name: 'flour', quantity: 2, unit_name: 'cup' }
          ],
          notes: [ "Use organic flour if possible", "Sift before mixing" ]
        }

        allow(RecipeServices::Parser).to receive(:new).with(recipe_attributes[:ingredients]).and_return(parser)
        allow(parser).to receive(:parse_ingredients_only).and_return(parsed_data)

        # Mock the ingredient service
        ingredient_service = instance_double(RecipeServices::Ingredient)
        allow(RecipeServices::Ingredient).to receive(:new).with(
          kind_of(Recipe), user, parsed_data[:ingredients]
        ).and_return(ingredient_service)
        allow(ingredient_service).to receive(:create_ingredients).and_return({
                                                                               success: true,
                                                                               ingredients: []
                                                                             })

        service = described_class.new(user, recipe_attributes)
        result = service.create

        expect(result[:success]).to be true
        expect(result[:recipe].notes).to include("Mom's recipe")
        expect(result[:recipe].notes).to include("Use organic flour if possible")
        expect(result[:recipe].notes).to include("Sift before mixing")
      end

      it 'handles ingredient parsing errors gracefully' do
        # Mock the parser to raise an error
        allow(RecipeServices::Parser).to receive(:new).with(recipe_attributes[:ingredients]).and_raise(StandardError.new("Parsing error"))

        service = described_class.new(user, recipe_attributes)
        result = service.create

        expect(result[:success]).to be true
        expect(result[:warnings]).to include(/Error processing ingredients/)
      end
    end

    context 'with invalid recipe parameters' do
      let(:invalid_attributes) {
        {
          name: '', # Invalid: empty name
          instructions: "Mix and bake",
          notes: "Test",
          recipe_category_id: recipe_category.id
        }
      }

      it 'returns failure and error messages' do
        service = described_class.new(user, invalid_attributes)
        result = service.create

        expect(result[:success]).to be false
        expect(result[:errors]).not_to be_empty
      end

      it 'does not create a recipe' do
        service = described_class.new(user, invalid_attributes)

        expect {
          result = service.create
        }.not_to change(Recipe, :count)
      end
    end

    context 'with empty instructions' do
      let(:recipe_attributes) {
        {
          name: 'Invalid Recipe',
          instructions: "", # Empty instructions which isn't allowed
          notes: "Test recipe",
          recipe_category_id: recipe_category.id
        }
      }

      it 'fails validation due to required instructions' do
        service = described_class.new(user, recipe_attributes)

        expect {
          result = service.create
          expect(result[:success]).to be false
          expect(result[:errors]).to include(/instructions/i)
        }.not_to change(Recipe, :count)
      end
    end

    context 'with minimal valid instructions' do
      let(:recipe_attributes) {
        {
          name: 'Minimal Instructions Recipe',
          instructions: "Simple steps", # Minimal but valid instructions
          notes: "Test recipe",
          recipe_category_id: recipe_category.id
        }
      }

      it 'creates a recipe with minimal instructions' do
        service = described_class.new(user, recipe_attributes)

        expect {
          result = service.create
          expect(result[:success]).to be true
        }.to change(Recipe, :count).by(1)
      end
    end

    context 'when no recipe_category_id is provided' do
      let(:recipe_attributes) {
        {
          name: 'No Category Recipe',
          instructions: "Simple instructions",
          notes: "Test recipe"
          # No recipe_category_id
        }
      }

      it 'returns error due to missing category' do
        service = described_class.new(user, recipe_attributes)

        expect {
          result = service.create
          expect(result[:success]).to be false
          expect(result[:errors]).to include(/recipe category/i)
        }.not_to change(Recipe, :count)
      end
    end

    context 'with a complex scenario' do
      let(:recipe_attributes) {
        {
          name: 'Chocolate Cake',
          ingredients: "2 cups flour\n1 cup sugar\n3 eggs",
          instructions: "1. Mix ingredients\n2. Bake at 350°F",
          notes: "Mom's recipe"
        }
      }

      let(:new_category_params) {
        {
          name: 'Desserts',
          display_order: 1
        }
      }

      it 'creates a recipe with ingredients and a new category' do
        # Create a real category first
        dessert_category = create(:recipe_category, name: 'Desserts', user: user)

        # Mock the category service to return the real category
        category_service = instance_double(RecipeServices::Category)
        allow(RecipeServices::Category).to receive(:new).with(user, new_category_params).and_return(category_service)
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
          notes: []
        }

        allow(RecipeServices::Parser).to receive(:new).with(recipe_attributes[:ingredients]).and_return(parser)
        allow(parser).to receive(:parse_ingredients_only).and_return(parsed_data)

        # Mock the ingredient service
        ingredient_service = instance_double(RecipeServices::Ingredient)
        allow(RecipeServices::Ingredient).to receive(:new).with(
          kind_of(Recipe), user, parsed_data[:ingredients]
        ).and_return(ingredient_service)
        allow(ingredient_service).to receive(:create_ingredients).and_return({
                                                                               success: true,
                                                                               ingredients: []
                                                                             })

        service = described_class.new(user, recipe_attributes)
        service.new_category_params = new_category_params

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
