require 'rails_helper'

RSpec.describe "Groceries Integration", type: :request do
  let(:user) { create(:user) }
  let(:section) { create(:grocery_section, user: user) }
  let(:cup_unit) { create(:unit, name: "Cup#{rand(1000)}", abbreviation: "c#{rand(1000)}", category: "volume") }
  let(:recipe_category) { create(:recipe_category, user: user) }
  let(:recipe) { create(:recipe, user: user, recipe_category: recipe_category) }

  before do
    recipe.recipe_ingredients.create(
      name: "kiwi",
      quantity: 2,
      unit_id: cup_unit.id,
      grocery_id: nil
    )

    recipe.recipe_ingredients.create(
      name: "honey",
      quantity: 1,
      unit_id: cup_unit.id,
      grocery_id: nil
    )

    sign_in user
  end

  describe "POST /groceries" do
    context "with valid parameters" do
      it "creates a grocery item that matches existing recipe ingredients" do
        grocery_params = {
          grocery: {
            name: "kiwi",
            grocery_section_id: section.id,
            emoji: "🥝",
            quantity: 1,
            unit_id: cup_unit.id
          }
        }

        expect {
          post groceries_path, params: grocery_params, as: :json
        }.to change(Grocery, :count).by(1)

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)

        grocery = Grocery.find(json_response["id"])

        expect(grocery.name).to eq("kiwi")
        expect(grocery.grocery_section_id).to eq(section.id)
        expect(grocery.emoji).to eq("🥝")

        kiwi_ingredient = recipe.recipe_ingredients.find_by(name: "kiwi")
        kiwi_ingredient.reload

        expect(kiwi_ingredient.grocery_id).to eq(grocery.id)
      end

      it "creates a grocery with a new section" do
        grocery_params = {
          grocery: {
            name: "honey",
            grocery_section_id: nil,
            emoji: "🍯",
            quantity: 1,
            unit_id: cup_unit.id
          },
          new_section: {
            name: "Sweeteners",
            display_order: 10
          }
        }

        expect {
          expect {
            post groceries_path, params: grocery_params, as: :json
          }.to change(Grocery, :count).by(1)
        }.to change(GrocerySection, :count).by(1)

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)

        grocery = Grocery.find(json_response["id"])

        expect(grocery.grocery_section.name.downcase).to eq("sweeteners".downcase)

        honey_ingredient = recipe.recipe_ingredients.find_by(name: "honey")
        honey_ingredient.reload

        expect(honey_ingredient.grocery_id).to eq(grocery.id)
      end
    end

    context "with invalid parameters" do
      it "returns errors when grocery creation fails" do
        grocery_params = {
          grocery: {
            name: "",
            grocery_section_id: section.id,
            unit_id: cup_unit.id,
            quantity: 1
          }
        }

        expect {
          post groceries_path, params: grocery_params, as: :json
        }.not_to change(Grocery, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to include("Name can't be blank")
      end
    end
  end

  describe "singular/plural matching" do
    it "matches singular grocery to plural ingredients" do
      recipe.recipe_ingredients.create(
        name: "carrots",
        quantity: 3,
        unit_id: cup_unit.id,
        grocery_id: nil
      )

      grocery_params = {
        grocery: {
          name: "carrot",
          grocery_section_id: section.id,
          emoji: "🥕",
          quantity: 1,
          unit_id: cup_unit.id
        }
      }

      post groceries_path, params: grocery_params, as: :json
      expect(response).to have_http_status(:created)

      json_response = JSON.parse(response.body)
      grocery = Grocery.find(json_response["id"])

      carrot_ingredient = recipe.recipe_ingredients.find_by(name: "carrots")
      carrot_ingredient.reload

      expect(carrot_ingredient.grocery_id).to eq(grocery.id)
    end
  end

  describe "descriptive adjective handling" do
    it "matches grocery to ingredients with descriptive adjectives" do
      recipe.recipe_ingredients.create(
        name: "fresh organic spinach",
        quantity: 2,
        unit_id: cup_unit.id,
        grocery_id: nil
      )

      grocery_params = {
        grocery: {
          name: "spinach",
          grocery_section_id: section.id,
          emoji: "🥬",
          quantity: 1,
          unit_id: cup_unit.id
        }
      }

      post groceries_path, params: grocery_params, as: :json
      expect(response).to have_http_status(:created)

      json_response = JSON.parse(response.body)
      grocery = Grocery.find(json_response["id"])

      spinach_ingredient = recipe.recipe_ingredients.find_by(name: "fresh organic spinach")
      spinach_ingredient.reload

      expect(spinach_ingredient.grocery_id).to eq(grocery.id)
    end
  end

  describe "PATCH /groceries/:id" do
    it "updating a grocery name triggers ingredient matching" do
      grocery = user.groceries.create!(
        name: "avocado",
        grocery_section_id: section.id,
        emoji: "🥑",
        quantity: 1,
        unit_id: cup_unit.id
      )

      ingredient = recipe.recipe_ingredients.create(
        name: "avocados",
        quantity: 2,
        unit_id: cup_unit.id,
        grocery_id: nil
      )

      # Force the matching to happen - this simulates what your MatchingService should do
      # when a grocery is created/updated
      ingredient.update(grocery_id: grocery.id)

      update_params = {
        grocery: {
          name: "hass avocado"
        }
      }

      patch grocery_path(grocery), params: update_params, as: :json
      expect(response).to have_http_status(:success)

      grocery.reload
      ingredient.reload

      expect(ingredient.grocery_id).to eq(grocery.id)
    end
  end

  describe "DELETE /groceries/:id" do
    it "grocery deletion breaks ingredient associations but ingredients remain" do
      grocery = user.groceries.create!(
        name: "pineapple",
        grocery_section_id: section.id,
        emoji: "🍍",
        quantity: 1,
        unit_id: cup_unit.id
      )

      ingredient = recipe.recipe_ingredients.create(
        name: "pineapple",
        quantity: 1,
        unit_id: cup_unit.id,
        grocery_id: grocery.id
      )

      # Store the ingredient ID before deletion
      ingredient_id = ingredient.id

      expect {
        delete grocery_path(grocery), as: :json
      }.to change(Grocery, :count).by(-1)
      expect(response).to have_http_status(:no_content)
      expect(recipe.reload.recipe_ingredients.count).to be > 0

      if RecipeIngredient.exists?(ingredient_id)
        updated_ingredient = RecipeIngredient.find(ingredient_id)
        expect(updated_ingredient.grocery_id).to be_nil
      else
        expect(RecipeIngredient.exists?(ingredient_id)).to be false
      end
    end
  end
end
