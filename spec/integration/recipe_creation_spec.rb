require 'rails_helper'

RSpec.describe "Recipes Integration", type: :request do
  let(:user) { create(:user) }
  let(:category) { create(:recipe_category, name: "Dinner", user: user) }
  # Use unique unit names to avoid collisions between tests
  let(:cup_unit) { create(:unit, name: "Cup#{rand(1000)}", abbreviation: "c#{rand(1000)}", category: "volume") }
  let(:tbsp_unit) { create(:unit, name: "Tablespoon#{rand(1000)}", abbreviation: "tbsp#{rand(1000)}", category: "volume") }
  let(:whole_unit) { create(:unit, name: "Whole#{rand(1000)}", abbreviation: "wh#{rand(1000)}", category: "count") }
  let(:grocery_section) { create(:grocery_section, name: "Produce", user: user) }

  # Create groceries with unique names by adding random suffixes
  let!(:apple) do
    apple = create(:grocery,
                   name: "apple#{rand(1000)}",
                   user: user,
                   grocery_section: grocery_section,
                   unit: cup_unit
    )
    # Store the name for later use in tests
    @apple_name = apple.name
    apple
  end

  let!(:milk) do
    milk = create(:grocery,
                  name: "milk#{rand(1000)}",
                  user: user,
                  grocery_section: grocery_section,
                  unit: cup_unit
    )
    @milk_name = milk.name
    milk
  end

  let!(:sugar) do
    sugar = create(:grocery,
                   name: "sugar#{rand(1000)}",
                   user: user,
                   grocery_section: grocery_section,
                   unit: tbsp_unit
    )
    @sugar_name = sugar.name
    sugar
  end

  before do
    sign_in user
  end

  describe "POST /recipes" do
    context "with valid parameters" do
      it "creates a recipe with ingredients that match existing groceries" do
        # Use the stored grocery names in the test
        recipe_params = {
          recipe: {
            name: "Apple Milk Shake",
            instructions: "Blend ingredients together",
            notes: "Best served cold",
            recipe_category_id: category.id,
            ingredients: "2 #{@apple_name}, cored and chopped\n1 cup #{@milk_name}\n2 tablespoons #{@sugar_name}"
          }
        }

        expect {
          post recipes_path, params: recipe_params, as: :json
        }.to change(Recipe, :count).by(1)

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("success")

        recipe = Recipe.find(json_response["recipe"]["id"])

        expect(recipe.name.downcase).to eq("apple milk shake")
        expect(recipe.instructions).to eq("Blend ingredients together")
        expect(recipe.recipe_ingredients.count).to eq(3)

        # Debug information
        puts "Actual ingredient names: #{recipe.recipe_ingredients.pluck(:name).inspect}"

        # Find ingredients by name
        apple_ingredient = recipe.recipe_ingredients.find { |ri| ri.name.include?(@apple_name) }
        milk_ingredient = recipe.recipe_ingredients.find { |ri| ri.name.include?(@milk_name) }
        sugar_ingredient = recipe.recipe_ingredients.find { |ri| ri.name.include?(@sugar_name) }

        # Validate that ingredients were found
        expect(apple_ingredient).to be_present, "Could not find an apple ingredient with name containing '#{@apple_name}'"
        expect(milk_ingredient).to be_present, "Could not find a milk ingredient with name containing '#{@milk_name}'"
        expect(sugar_ingredient).to be_present, "Could not find a sugar ingredient with name containing '#{@sugar_name}'"

        # Reload ingredients to get fresh data
        apple_ingredient.reload if apple_ingredient
        milk_ingredient.reload if milk_ingredient
        sugar_ingredient.reload if sugar_ingredient

        # Check associations
        expect(apple_ingredient.grocery_id).to eq(apple.id)
        expect(milk_ingredient.grocery_id).to eq(milk.id)
        expect(sugar_ingredient.grocery_id).to eq(sugar.id)

        # Check preparation details
        expect(apple_ingredient.preparation.downcase).to include("chopped")
        expect(apple_ingredient.preparation.downcase).to include("cored")
      end

      it "creates a recipe with a new category when provided" do
        recipe_params = {
          recipe: {
            name: "Soup",
            instructions: "Cook everything",
            recipe_category_id: nil,
            ingredients: "1 cup water\n1 #{@apple_name}"
          },
          new_category: {
            name: "Soups",
            display_order: 5
          }
        }

        expect {
          expect {
            post recipes_path, params: recipe_params, as: :json
          }.to change(Recipe, :count).by(1)
        }.to change(RecipeCategory, :count).by(1)

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)

        recipe = Recipe.find(json_response["recipe"]["id"])

        expect(recipe.recipe_category.name.downcase).to eq("soups")

        # Check for the apple ingredient and its association
        apple_ingredient = recipe.recipe_ingredients.find { |ri| ri.name.include?(@apple_name) }
        expect(apple_ingredient).to be_present

        apple_ingredient.reload if apple_ingredient
        expect(apple_ingredient.grocery_id).to eq(apple.id)
      end
    end

    context "with invalid parameters" do
      it "returns errors when recipe creation fails" do
        recipe_params = {
          recipe: {
            name: "",
            instructions: "Mix",
            ingredients: "invalid ingredient data that won't parse properly"
          }
        }

        expect {
          post recipes_path, params: recipe_params, as: :json
        }.not_to change(Recipe, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
        expect(json_response["errors"].join(", ")).to include("Name can't be blank")
      end
    end
  end

  describe "PATCH /recipes/:id" do
    let(:recipe) { create(:recipe, name: "Smoothie", user: user, recipe_category: category) }

    before do
      create(:recipe_ingredient, recipe: recipe, name: "banana", quantity: 1, unit: whole_unit)
    end

    it "updates a recipe with new ingredients that match existing groceries" do
      update_params = {
        recipe: {
          name: "Updated Smoothie",
          instructions: "Updated instructions"
        },
        new_recipe_ingredients: [
          {
            name: @apple_name,
            quantity: 3,
            unit_id: whole_unit.id
          },
          {
            name: @sugar_name,
            quantity: 1,
            unit_id: tbsp_unit.id
          }
        ]
      }

      patch recipe_path(recipe), params: update_params, as: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response["status"]).to eq("success")

      recipe.reload

      expect(recipe.name.downcase).to eq("updated smoothie".downcase)
      expect(recipe.instructions).to eq("Updated instructions")

      # Find new ingredients
      new_apple = recipe.recipe_ingredients.find { |ri| ri.name.include?(@apple_name) }
      new_sugar = recipe.recipe_ingredients.find { |ri| ri.name.include?(@sugar_name) }

      expect(new_apple).to be_present, "Could not find an apple ingredient with name '#{@apple_name}'"
      expect(new_sugar).to be_present, "Could not find a sugar ingredient with name '#{@sugar_name}'"

      # Reload to get updated associations
      new_apple.reload if new_apple
      new_sugar.reload if new_sugar

      expect(new_apple.grocery_id).to eq(apple.id)
      expect(new_sugar.grocery_id).to eq(sugar.id)
    end
  end

  describe "complex ingredient parsing" do
    it "parses complex ingredient text correctly" do
      recipe_params = {
        recipe: {
          name: "Complex Recipe",
          instructions: "Mix all ingredients",
          recipe_category_id: category.id,
          ingredients: "2 large #{@apple_name}, peeled and diced\n" +
            "½ cup #{@milk_name}, room temperature\n" +
            "1 tablespoon #{@sugar_name} or honey (optional)\n" +
            "A pinch of cinnamon"
        }
      }

      post recipes_path, params: recipe_params, as: :json
      expect(response).to have_http_status(:created)

      json_response = JSON.parse(response.body)
      recipe = Recipe.find(json_response["recipe"]["id"])

      ingredients = recipe.recipe_ingredients

      puts "Complex recipe ingredients: #{ingredients.pluck(:name).inspect}"

      apple_ingredient = ingredients.find { |ri| ri.name.include?(@apple_name) }
      milk_ingredient = ingredients.find { |ri| ri.name.include?(@milk_name) }

      expect(apple_ingredient).to be_present, "Could not find an apple ingredient"
      expect(milk_ingredient).to be_present, "Could not find a milk ingredient"

      if apple_ingredient
        expect(apple_ingredient.quantity).to eq(2)
        expect(apple_ingredient.preparation.downcase).to include("peeled")
        expect(apple_ingredient.preparation.downcase).to include("diced")
        expect(apple_ingredient.size.downcase).to include("large")

        apple_ingredient.reload
        expect(apple_ingredient.grocery_id).to eq(apple.id)
      end

      if milk_ingredient
        expect(milk_ingredient.quantity.to_f).to eq(0.5)

        milk_ingredient.reload
        expect(milk_ingredient.grocery_id).to eq(milk.id)
      end

      expect(recipe.notes.downcase).to include("sugar")
      expect(recipe.notes.downcase).to include("honey")
      expect(recipe.notes.downcase).to include("alternative")

      cinnamon = ingredients.find { |ri| ri.name.downcase.include?('cinnamon') }
      expect(cinnamon).to be_present, "Could not find a cinnamon ingredient"
    end
  end

  describe "recipe availability checking" do
    it "correctly identifies available and unavailable ingredients" do
      recipe = create(:recipe, name: "Test Recipe", user: user, recipe_category: category)

      apple_ingredient = recipe.recipe_ingredients.create!(
        name: @apple_name,
        quantity: 1,
        unit_id: cup_unit.id,
        grocery_id: apple.id # This ingredient is available
      )

      exotic_fruit = recipe.recipe_ingredients.create!(
        name: "exotic fruit",
        quantity: 1,
        unit_id: cup_unit.id,
        grocery_id: nil # This ingredient is not available
      )

      availability_checker = RecipeServices::AvailabilityChecker.new(user, recipe)
      availability_info = availability_checker.availability_info

      expect(availability_info[:available]).to be false
      expect(availability_info[:missing_ingredients].length).to eq(1)
      expect(availability_info[:missing_ingredients].first[:name]).to eq("exotic fruit")
    end
  end
end
