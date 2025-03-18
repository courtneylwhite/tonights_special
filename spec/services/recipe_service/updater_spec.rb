require 'rails_helper'

RSpec.describe RecipeServices::Updater, type: :service do
  # Create mocks for testing
  let(:user) { double('User', id: 1) }
  let(:recipe_category) { double('RecipeCategory', id: 1, name: 'Main Course') }
  let(:unit) { double('Unit', id: 1, name: 'cup', abbreviation: 'c', category: 'volume') }
  let(:grocery) { double('Grocery', id: 1, name: 'flour') }

  # Create a mock recipe
  let(:recipe) do
    double('Recipe',
           id: 1,
           user: user,
           recipe_category: recipe_category,
           name: 'Original Recipe Name',
           instructions: 'Original instructions',
           notes: 'Original notes',
           recipe_category_id: 1,
           completed: false,
           reload: nil # Stub reload for simplicity
    )
  end

  # Setup recipe ingredients collection
  let(:recipe_ingredients) do
    double('RecipeIngredients').tap do |collection|
      # Setup the collection to return specific recipe ingredients when queried
      allow(collection).to receive(:find_by) do |args|
        if args[:id] == 1
          double('RecipeIngredient', id: 1, name: 'flour', quantity: 2, unit_id: 1, preparation: nil, size: nil)
        elsif args[:id] == 2
          double('RecipeIngredient', id: 2, name: 'sugar', quantity: 1, unit_id: 1, preparation: nil, size: nil)
        else
          nil
        end
      end

      # Setup for where queries
      allow(collection).to receive(:where) do |args|
        if args[:id] == [ 2 ]
          ingredients_to_delete = [ double('RecipeIngredient', id: 2) ]
          allow(ingredients_to_delete).to receive(:destroy_all).and_return(true)
          allow(ingredients_to_delete).to receive(:pluck).and_return([ 2 ])
          ingredients_to_delete
        else
          []
        end
      end
    end
  end

  # Setup recipe before each test
  before do
    allow(recipe).to receive(:recipe_ingredients).and_return(recipe_ingredients)
    allow(recipe).to receive(:update).and_return(true)
    allow(recipe).to receive_message_chain(:errors, :full_messages).and_return([])
    allow(recipe).to receive(:reload).and_return(recipe)
  end

  describe '#update' do
    context 'with valid recipe attributes' do
      let(:recipe_attributes) do
        {
          name: 'Updated Recipe Name',
          instructions: 'Updated instructions',
          notes: 'Updated notes',
          recipe_category_id: 1,
          prep_time: '20 minutes',
          cook_time: '30 minutes',
          servings: 4
        }
      end

      it 'updates the recipe with new attributes' do
        # Set expectation for recipe update
        expect(recipe).to receive(:update).with(
          hash_including(
            name: 'updated recipe name',
            instructions: 'Updated instructions', # Not downcased
            notes: 'updated notes'
          )
        ).and_return(true)

        result = described_class.new(user, recipe, recipe_attributes).update

        expect(result[:success]).to be true
        expect(result[:recipe]).to eq(recipe)
      end
    end

    context 'with invalid recipe attributes' do
      let(:invalid_recipe_attributes) do
        {
          name: '' # Invalid - empty name
        }
      end

      it 'returns failure and error messages' do
        expect(recipe).to receive(:update).and_return(false)
        expect(recipe).to receive_message_chain(:errors, :full_messages).and_return([ 'Name cannot be blank' ])

        result = described_class.new(user, recipe, invalid_recipe_attributes).update

        expect(result[:success]).to be false
        expect(result[:recipe]).to be_nil
        expect(result[:errors]).to include('Name cannot be blank')
      end
    end

    context 'when updating recipe ingredients' do
      let(:recipe_attributes) { { name: 'Recipe with updated ingredients' } }
      let(:recipe_ingredient) { double('RecipeIngredient', id: 1, name: 'flour', quantity: 2) }
      let(:ingredients_attributes) do
        [
          { id: 1, quantity: 3 }, # Update the first ingredient
          { id: 2, name: 'brown sugar', preparation: 'sifted' } # Update the second ingredient
        ]
      end

      before do
        # Setup for ingredient updates
        allow(recipe_ingredients).to receive(:find_by).with(id: 1).and_return(recipe_ingredient)
        allow(recipe_ingredient).to receive(:update).and_return(true)

        # Allow name to be accessed on recipe_ingredient
        allow(recipe_ingredient).to receive(:name).and_return('flour')

        # Setup for second ingredient
        allow(recipe_ingredients).to receive(:find_by).with(id: 2).and_return(
          double('RecipeIngredient', id: 2, name: 'sugar').tap do |ing|
            allow(ing).to receive(:update).and_return(true)
          end
        )

        # Setup matcher service to return nil to avoid any matching attempts
        allow(MatchingService).to receive(:match_ingredient_to_grocery).and_return(nil)
      end

      it 'updates the existing ingredients' do
        expect(recipe_ingredient).to receive(:update).with(hash_including(quantity: 3)).and_return(true)

        result = described_class.new(
          user,
          recipe,
          recipe_attributes,
          ingredients_attributes
        ).update

        expect(result[:success]).to be true
      end

      context 'with non-existent ingredient id' do
        let(:ingredients_with_bad_id) do
          [ { id: 999999, quantity: 3 } ] # Non-existent ID
        end

        it 'adds a warning but still succeeds' do
          result = described_class.new(
            user,
            recipe,
            recipe_attributes,
            ingredients_with_bad_id
          ).update

          expect(result[:success]).to be true
          expect(result[:warnings]).to include("Couldn't find ingredient with ID: 999999")
        end
      end

      context 'when an ingredient update fails' do
        it 'returns failure and error messages' do
          allow(recipe_ingredient).to receive(:update).and_return(false)
          allow(recipe_ingredient).to receive_message_chain(:errors, :full_messages).and_return([ 'Quantity must be greater than 0' ])

          # Mock exception raising to match the test
          updater = described_class.new(
            user,
            recipe,
            recipe_attributes,
            [ { id: 1, quantity: 0 } ]
          )

          # Stub the update_recipe_ingredients method to raise the expected exception
          allow(updater).to receive(:update_recipe_ingredients).and_raise(StandardError.new("Ingredient validation failed"))

          result = updater.update

          expect(result[:success]).to be false
          expect(result[:errors]).to include('Failed to update recipe: Ingredient validation failed')
        end
      end
    end

    context 'when deleting ingredients' do
      let(:recipe_attributes) { { name: 'Recipe with deleted ingredients' } }
      let(:deleted_ingredient_ids) { [ 2 ] }

      it 'removes the specified ingredients' do
        # Expect the where query to find ingredients to delete
        expect(recipe_ingredients).to receive(:where).with(id: deleted_ingredient_ids).and_return(
          double('IngredientsCollection').tap do |collection|
            allow(collection).to receive(:destroy_all).and_return(true)
            allow(collection).to receive(:pluck).and_return([ 2 ])
          end
        )

        result = described_class.new(
          user,
          recipe,
          recipe_attributes,
          [],
          deleted_ingredient_ids
        ).update

        expect(result[:success]).to be true
      end
    end

    context 'when adding new ingredients' do
      let(:recipe_attributes) { { name: 'Recipe with new ingredients' } }
      let(:new_ingredients_attributes) do
        [
          { name: 'Eggs', quantity: 2, unit_id: 1, preparation: 'beaten' },
          { name: 'Milk', quantity: 1, unit_id: 1 }
        ]
      end

      # Mock the RecipeServices::Ingredient service
      let(:ingredient_service) { double('IngredientService') }

      before do
        allow(RecipeServices::Ingredient).to receive(:new).and_return(ingredient_service)
      end

      it 'creates the new ingredients using the ingredient service' do
        allow(ingredient_service).to receive(:create_ingredients).and_return({
                                                                               success: true,
                                                                               ingredients: [
                                                                                 double('RecipeIngredient', id: 101, name: 'eggs', quantity: 2),
                                                                                 double('RecipeIngredient', id: 102, name: 'milk', quantity: 1)
                                                                               ]
                                                                             })

        result = described_class.new(
          user,
          recipe,
          recipe_attributes,
          [],
          [],
          new_ingredients_attributes
        ).update

        expect(result[:success]).to be true
        expect(RecipeServices::Ingredient).to have_received(:new).with(
          recipe,
          user,
          kind_of(Array)
        )
      end

      context 'when ingredient creation fails' do
        it 'returns warnings but still succeeds when errors are minor' do
          # Return an empty ingredients array but with success: false
          allow(ingredient_service).to receive(:create_ingredients).and_return({
                                                                                 success: false,
                                                                                 ingredients: [],
                                                                                 errors: [ 'Unit not found, using default' ] # This is a minor error
                                                                               })

          result = described_class.new(
            user,
            recipe,
            recipe_attributes,
            [],
            [],
            new_ingredients_attributes
          ).update

          # Since errors don't contain "Error creating ingredient", we should still succeed
          expect(result[:success]).to be true
          expect(result[:warnings].first).to include("Some ingredients could not be created")
        end


        it 'returns failure and error messages for major errors' do
          allow(ingredient_service).to receive(:create_ingredients).and_return({
                                                                                 success: false,
                                                                                 errors: [ 'Error creating ingredient: Invalid unit' ]
                                                                               })

          result = described_class.new(
            user,
            recipe,
            recipe_attributes,
            [],
            [],
            new_ingredients_attributes
          ).update

          expect(result[:success]).to be false
          expect(result[:errors]).not_to be_empty
        end
      end
    end

    context 'with a comprehensive update' do
      let(:recipe_attributes) { { name: 'Comprehensive Recipe Update' } }
      let(:ingredients_attributes) { [ { id: 1, quantity: 3 } ] }
      let(:deleted_ingredient_ids) { [ 2 ] }
      let(:new_ingredients_attributes) { [ { name: 'Vanilla extract', quantity: 1, unit_id: 1 } ] }

      # Setup to simplify the comprehensive test
      before do
        # For ingredients update
        allow(recipe_ingredients).to receive(:find_by).with(id: 1).and_return(
          double('RecipeIngredient', id: 1, name: 'flour').tap do |ing|
            allow(ing).to receive(:update).and_return(true)
          end
        )

        # For ingredients deletion
        allow(recipe_ingredients).to receive(:where).with(id: [ 2 ]).and_return(
          double('IngredientsCollection').tap do |collection|
            allow(collection).to receive(:destroy_all).and_return(true)
            allow(collection).to receive(:pluck).and_return([ 2 ])
          end
        )

        # For new ingredients
        allow(RecipeServices::Ingredient).to receive(:new).and_return(
          double('IngredientService').tap do |service|
            allow(service).to receive(:create_ingredients).and_return({
                                                                        success: true,
                                                                        ingredients: [ double('RecipeIngredient', id: 201, name: 'vanilla extract') ]
                                                                      })
          end
        )

        # Setup matcher service to return nil to avoid any matching attempts
        allow(MatchingService).to receive(:match_ingredient_to_grocery).and_return(nil)
      end

      it 'performs all update operations successfully' do
        result = described_class.new(
          user,
          recipe,
          recipe_attributes,
          ingredients_attributes,
          deleted_ingredient_ids,
          new_ingredients_attributes
        ).update

        expect(result[:success]).to be true
      end
    end

    context 'when an unexpected error occurs' do
      let(:recipe_attributes) { { name: 'Recipe that will cause an error' } }

      it 'returns failure and captures the error message' do
        allow(recipe).to receive(:update).and_raise(StandardError.new("Unexpected database error"))

        result = described_class.new(user, recipe, recipe_attributes).update

        expect(result[:success]).to be false
        expect(result[:errors]).to include('Failed to update recipe: Unexpected database error')
      end
    end
  end
end
