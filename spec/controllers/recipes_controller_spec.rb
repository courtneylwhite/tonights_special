require 'rails_helper'

RSpec.describe RecipesController, type: :controller do
  let(:user) { create(:user) }
  let(:recipe_category) { create(:recipe_category, user: user) }

  # Use unique values for unit to avoid duplication errors
  let(:unit) do
    random_suffix = SecureRandom.hex(4)
    create(:unit,
           name: "TestUnit-#{random_suffix}",
           abbreviation: "tu-#{random_suffix}",
           category: "volume"
    )
  end

  let(:grocery) { create(:grocery, name: "TestGrocery-#{SecureRandom.hex(4)}") }
  let(:recipe) { create(:recipe, user: user, recipe_category: recipe_category) }
  let(:recipe_ingredient) do
    create(:recipe_ingredient,
           recipe: recipe,
           grocery: grocery,
           unit: unit,
           name: "Test Ingredient #{SecureRandom.hex(4)}" # Add required name
    )
  end

  before do
    sign_in user
  end

  describe "GET #index" do
    it "returns http success" do
      get :index
      expect(response).to have_http_status(:success)
    end

    it "assigns @recipes, @recipe_categories, and @grouped_recipes" do
      recipe # Create the recipe

      get :index

      expect(assigns(:recipes)).to include(recipe)
      expect(assigns(:recipe_categories)).to include(recipe_category)
      expect(assigns(:grouped_recipes)).to be_a(Hash)
    end

    it "renders JSON when requested" do
      recipe # Create the recipe

      get :index, format: :json

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("application/json")
    end
  end

  describe "GET #show" do
    it "returns http success" do
      get :show, params: { id: recipe.id }
      expect(response).to have_http_status(:success)
    end

    it "assigns @recipe, @units, @recipe_categories, and @recipe_ingredients" do
      ri = recipe_ingredient # Create the recipe ingredient

      get :show, params: { id: recipe.id }

      expect(assigns(:recipe)).to eq(recipe)
      expect(assigns(:units)).to be_present
      expect(assigns(:recipe_categories)).to include(recipe_category)
      expect(assigns(:recipe_ingredients)).to be_present
    end

    it "renders JSON when requested" do
      ri = recipe_ingredient # Create the recipe ingredient

      get :show, params: { id: recipe.id }, format: :json

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("application/json")

      json = JSON.parse(response.body)
      expect(json["recipe"]).to be_present
      expect(json["recipe_ingredients"]).to be_present
      expect(json["units"]).to be_present
      expect(json["recipe_categories"]).to be_present
    end

    it "handles recipe not found" do
      get :show, params: { id: 999999 }, format: :json

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)["error"]).to eq("Recipe not found.")
    end

    it "redirects to recipes_path with alert for HTML format when recipe not found" do
      get :show, params: { id: 999999 }

      expect(response).to redirect_to(recipes_path)
      expect(flash[:alert]).to eq("Recipe not found.")
    end
  end

  describe "POST #create" do
    let(:valid_recipe_attributes) {
      {
        name: "Chocolate Cake",
        ingredients: "2 cups flour\n1 cup sugar\n2 eggs",
        instructions: "1. Mix dry ingredients\n2. Add wet ingredients\n3. Bake at 350F for 30 minutes",
        notes: "Mom's favorite recipe",
        recipe_category_id: recipe_category.id
      }
    }

    context "with valid params" do
      it "returns success JSON response" do
        # Mock the Creator service with successful result
        creator_instance = instance_double(RecipeServices::Creator)
        allow(RecipeServices::Creator).to receive(:new).and_return(creator_instance)

        allow(creator_instance).to receive(:create).and_return({
                                                                 success: true,
                                                                 recipe: recipe,
                                                                 warnings: nil
                                                               })

        post :create, params: { recipe: valid_recipe_attributes }

        expect(response).to have_http_status(:created)
        expect(response.content_type).to include("application/json")
        expect(JSON.parse(response.body)["status"]).to eq("success")
      end

      it "handles new category creation" do
        creator_instance = instance_double(RecipeServices::Creator)
        allow(RecipeServices::Creator).to receive(:new).and_return(creator_instance)
        expect(creator_instance).to receive(:new_category_params=)

        allow(creator_instance).to receive(:create).and_return({
                                                                 success: true,
                                                                 recipe: recipe,
                                                                 warnings: nil
                                                               })

        post :create, params: {
          recipe: valid_recipe_attributes.except(:recipe_category_id),
          new_category: { name: "New Category", display_order: 1 }
        }

        expect(response).to have_http_status(:created)
      end
    end

    context "with invalid params" do
      it "returns error status" do
        creator_instance = instance_double(RecipeServices::Creator)
        allow(RecipeServices::Creator).to receive(:new).and_return(creator_instance)

        allow(creator_instance).to receive(:create).and_return({
                                                                 success: false,
                                                                 errors: [ "Name can't be blank" ]
                                                               })

        post :create, params: { recipe: { name: "" } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["status"]).to eq("error")
      end
    end
  end

  describe "PATCH #update" do
    let(:recipe_attributes) { { name: "Updated Recipe Name", notes: "Updated notes" } }

    it "returns success JSON response when valid" do
      updater_double = instance_double(RecipeServices::Updater)
      allow(RecipeServices::Updater).to receive(:new).and_return(updater_double)
      allow(updater_double).to receive(:update).and_return({ success: true, warnings: nil })

      patch :update, params: { id: recipe.id, recipe: recipe_attributes }, format: :json

      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)["status"]).to eq("success")
    end

    it "returns error status when invalid" do
      updater_double = instance_double(RecipeServices::Updater)
      allow(RecipeServices::Updater).to receive(:new).and_return(updater_double)
      allow(updater_double).to receive(:update).and_return({
                                                             success: false,
                                                             errors: [ "Name can't be blank" ]
                                                           })

      patch :update, params: { id: recipe.id, recipe: { name: "" } }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["status"]).to eq("error")
    end
  end

  describe "DELETE #destroy error handling" do
    it "handles deletion failure gracefully for HTML format" do
      # Simulate a scenario where recipe deletion fails
      allow_any_instance_of(Recipe).to receive(:destroy).and_raise(StandardError.new("Deletion failed"))

      # Log the error to match the controller's error logging
      expect(Rails.logger).to receive(:error).with(/Recipe deletion failed: Deletion failed/)

      # Attempt to delete the recipe
      delete :destroy, params: { id: recipe.id }

      # Check for redirect and alert
      expect(response).to redirect_to(recipes_path)
      expect(flash[:alert]).to eq("Failed to delete recipe.")
    end

    it "handles deletion failure gracefully for JSON format" do
      # Simulate a scenario where recipe deletion fails
      allow_any_instance_of(Recipe).to receive(:destroy).and_raise(StandardError.new("Deletion failed"))

      # Log the error to match the controller's error logging
      expect(Rails.logger).to receive(:error).with(/Recipe deletion failed: Deletion failed/)

      # Attempt to delete the recipe in JSON format
      delete :destroy, params: { id: recipe.id }, format: :json

      # Check for error response
      expect(response).to have_http_status(:unprocessable_entity)

      json_response = JSON.parse(response.body)
      expect(json_response["status"]).to eq("error")
      expect(json_response["message"]).to eq("Failed to delete recipe.")
    end
  end

  describe "PATCH #mark_completed" do
    it "marks the recipe as completed" do
      recipe = create(:recipe, user: user, recipe_category: recipe_category, completed: false)

      patch :mark_completed, params: { id: recipe.id }

      recipe.reload
      expect(recipe.completed).to be true
      expect(recipe.completed_at).not_to be_nil
    end

    it "returns success JSON response" do
      recipe = create(:recipe, user: user, recipe_category: recipe_category)

      patch :mark_completed, params: { id: recipe.id }, format: :json

      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)["status"]).to eq("success")
      expect(JSON.parse(response.body)["recipe"]).to be_present
    end
  end

  describe "PATCH #mark_incomplete" do
    it "marks the recipe as incomplete" do
      recipe = create(:recipe, user: user, recipe_category: recipe_category, completed: true, completed_at: Time.current)

      patch :mark_incomplete, params: { id: recipe.id }

      recipe.reload
      expect(recipe.completed).to be false
      expect(recipe.completed_at).to be_nil
    end

    it "returns success JSON response" do
      recipe = create(:recipe, user: user, recipe_category: recipe_category, completed: true)

      patch :mark_incomplete, params: { id: recipe.id }, format: :json

      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)["status"]).to eq("success")
      expect(JSON.parse(response.body)["recipe"]).to be_present
    end
  end
end
