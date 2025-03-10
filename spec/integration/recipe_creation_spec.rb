require 'rails_helper'

RSpec.describe "Recipes Integration", type: :request do
  let(:user) { create(:user) }
  let(:category) { create(:recipe_category, name: "Dinner", user: user) }
  let(:cup_unit) { create(:unit, name: "Cup#{rand(1000)}", abbreviation: "c#{rand(1000)}", category: "volume") }
  let(:tbsp_unit) { create(:unit, name: "Tablespoon#{rand(1000)}", abbreviation: "tbsp#{rand(1000)}", category: "volume") }
  let(:whole_unit) { create(:unit, name: "Whole#{rand(1000)}", abbreviation: "wh#{rand(1000)}", category: "count") }
  let(:grocery_section) { create(:grocery_section, name: "Produce", user: user) }
  let!(:apple) { create(:grocery, name: "apple", user: user, grocery_section: grocery_section, unit: cup_unit) }
  let!(:milk) { create(:grocery, name: "milk", user: user, grocery_section: grocery_section, unit: cup_unit) }
  let!(:sugar) { create(:grocery, name: "sugar", user: user, grocery_section: grocery_section, unit: tbsp_unit) }

  before do
    sign_in user
  end

  describe "POST /recipes" do
    context "with valid parameters" do
      it "creates a recipe with ingredients that match existing groceries" do
        recipe_params = {
          recipe: {
            name: "Apple Milk Shake",
            instructions: "Blend ingredients together",
            notes: "Best served cold",
            recipe_category_id: category.id,
            ingredients: "2 apples, cored and chopped\n1 cup milk\n2 tablespoons sugar"
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

        # Print the actual ingredient names to help debug
        puts "Actual ingredient names: #{recipe.recipe_ingredients.pluck(:name).inspect}"

        apple_ingredient = recipe.recipe_ingredients.find { |ri| ri.name.downcase.include?('apple') }
        milk_ingredient = recipe.recipe_ingredients.find { |ri| ri.name.downcase.include?('milk') }
        sugar_ingredient = recipe.recipe_ingredients.find { |ri| ri.name.downcase.include?('sugar') }

        expect(apple_ingredient).to be_present, "Could not find an apple ingredient among: #{recipe.recipe_ingredients.pluck(:name)}"
        expect(milk_ingredient).to be_present, "Could not find a milk ingredient"
        expect(sugar_ingredient).to be_present, "Could not find a sugar ingredient"

        if apple_ingredient.present?
          expect(apple_ingredient.grocery_id).to eq(apple.id)
        end

        if milk_ingredient.present?
          expect(milk_ingredient.grocery_id).to eq(milk.id)
        end

        if sugar_ingredient.present?
          expect(sugar_ingredient.grocery_id).to eq(sugar.id)
        end

        if apple_ingredient.present?
          expect(apple_ingredient.preparation.downcase).to include("chopped"),
                                                           "Expected preparation to include 'chopped', got: #{apple_ingredient.preparation}"
          expect(apple_ingredient.preparation.downcase).to include("cored"),
                                                           "Expected preparation to include 'cored', got: #{apple_ingredient.preparation}"
        end
      end

      it "creates a recipe with a new category when provided" do
        recipe_params = {
          recipe: {
            name: "Soup",
            instructions: "Cook everything",
            recipe_category_id: nil,
            ingredients: "1 cup water\n1 apple"
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
            name: "apple",
            quantity: 3,
            unit_id: whole_unit.id
          },
          {
            name: "sugar",
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

      new_apple = recipe.recipe_ingredients.find { |ri| ri.name.downcase.include?('apple') }
      new_sugar = recipe.recipe_ingredients.find { |ri| ri.name.downcase.include?('sugar') }

      expect(new_apple).to be_present, "Could not find an apple ingredient"
      expect(new_sugar).to be_present, "Could not find a sugar ingredient"

      if new_apple.present?
        expect(new_apple.grocery_id).to eq(apple.id)
      end

      if new_sugar.present?
        expect(new_sugar.grocery_id).to eq(sugar.id)
      end
    end
  end

  describe "complex ingredient parsing" do
    it "parses complex ingredient text correctly" do
      recipe_params = {
        recipe: {
          name: "Complex Recipe",
          instructions: "Mix all ingredients",
          recipe_category_id: category.id,
          ingredients: "2 large apples, peeled and diced\n" +
            "½ cup milk, room temperature\n" +
            "1 tablespoon sugar or honey (optional)\n" +
            "A pinch of cinnamon"
        }
      }

      post recipes_path, params: recipe_params, as: :json
      expect(response).to have_http_status(:created)

      json_response = JSON.parse(response.body)
      recipe = Recipe.find(json_response["recipe"]["id"])

      ingredients = recipe.recipe_ingredients

      puts "Complex recipe ingredients: #{ingredients.pluck(:name).inspect}"

      apple_ingredient = ingredients.find { |ri| ri.name.downcase.include?('apple') }
      milk_ingredient = ingredients.find { |ri| ri.name.downcase.include?('milk') }

      expect(apple_ingredient).to be_present, "Could not find an apple ingredient"
      expect(milk_ingredient).to be_present, "Could not find a milk ingredient"

      if apple_ingredient.present?
        expect(apple_ingredient.quantity).to eq(2)
        expect(apple_ingredient.preparation.downcase).to include("peeled")
        expect(apple_ingredient.preparation.downcase).to include("diced")
        expect(apple_ingredient.size.downcase).to include("large")
      end

      if milk_ingredient.present?
        expect(milk_ingredient.quantity.to_f).to eq(0.5)
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

      recipe.recipe_ingredients.create!(
        name: "apple",
        quantity: 1,
        unit_id: cup_unit.id,
        grocery_id: apple.id # This ingredient is available
      )

      recipe.recipe_ingredients.create!(
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
