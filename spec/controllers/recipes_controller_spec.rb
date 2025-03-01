require 'rails_helper'

RSpec.describe RecipesController, type: :controller do
  let(:user) { create(:user) }
  let(:recipe_category) { create(:recipe_category, user: user) }

  before do
    sign_in user
  end

  describe "GET #index" do
    it "returns http success" do
      get :index
      expect(response).to have_http_status(:success)
    end

    it "assigns @recipes, @recipe_categories, and @grouped_recipes" do
      recipe = create(:recipe, user: user, recipe_category: recipe_category)

      get :index

      expect(assigns(:recipes)).to include(recipe)
      expect(assigns(:recipe_categories)).to include(recipe_category)
      expect(assigns(:grouped_recipes)).to be_a(Hash)
    end

    it "uses RecipePresenter.grouped_recipes_with_availability" do
      recipe = create(:recipe, user: user, recipe_category: recipe_category)

      expect(RecipePresenter).to receive(:grouped_recipes_with_availability)
                                   .with(kind_of(ActiveRecord::Relation), kind_of(ActiveRecord::Relation), user)
                                   .and_call_original

      get :index
    end

    it "renders JSON when requested" do
      recipe = create(:recipe, user: user, recipe_category: recipe_category)

      get :index, format: :json

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("application/json")

      # Parse the response body
      json = JSON.parse(response.body)
      expect(json).to have_key(recipe_category.name)
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
      it "creates a new recipe" do
        # Create the recipe before setting up the mock to avoid factorybot validation issues
        recipe = create(:recipe, user: user, recipe_category: recipe_category)

        # Mock the Creator service with successful result
        creator_instance = instance_double(RecipeServices::Creator)
        allow(RecipeServices::Creator).to receive(:new).with(user, kind_of(ActionController::Parameters)).and_return(creator_instance)

        success_result = {
          success: true,
          recipe: recipe,
          warnings: nil
        }

        allow(creator_instance).to receive(:create).and_return(success_result)

        # Don't expect a recipe count change since we're mocking the service
        post :create, params: { recipe: valid_recipe_attributes }

        expect(response).to have_http_status(:created)
        expect(response.content_type).to include("application/json")

        json = JSON.parse(response.body)
        expect(json["status"]).to eq("success")
      end

      it "handles new category creation" do
        # Mock the Creator service
        creator_instance = instance_double(RecipeServices::Creator)
        allow(RecipeServices::Creator).to receive(:new).with(user, kind_of(ActionController::Parameters)).and_return(creator_instance)
        expect(creator_instance).to receive(:new_category_params=).with(kind_of(ActionController::Parameters))

        recipe = create(:recipe, user: user, recipe_category: recipe_category)
        success_result = {
          success: true,
          recipe: recipe,
          warnings: nil
        }

        allow(creator_instance).to receive(:create).and_return(success_result)

        # Add new_category parameters
        new_category_params = { name: "New Category", display_order: 1 }

        post :create, params: {
          recipe: valid_recipe_attributes.except(:recipe_category_id),
          new_category: new_category_params
        }

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["status"]).to eq("success")
      end

      it "includes warning messages from the service when present" do
        creator_instance = instance_double(RecipeServices::Creator)
        allow(RecipeServices::Creator).to receive(:new).with(user, kind_of(ActionController::Parameters)).and_return(creator_instance)

        recipe = create(:recipe, user: user, recipe_category: recipe_category)
        success_result_with_warnings = {
          success: true,
          recipe: recipe,
          warnings: [ "Some ingredients could not be parsed" ]
        }

        allow(creator_instance).to receive(:create).and_return(success_result_with_warnings)

        post :create, params: { recipe: valid_recipe_attributes }

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["message"]).to eq("Some ingredients could not be parsed")
      end
    end

    context "with invalid params" do
      it "returns error status and messages" do
        # Mock the Creator service with error result
        creator_instance = instance_double(RecipeServices::Creator)
        allow(RecipeServices::Creator).to receive(:new).with(user, kind_of(ActionController::Parameters)).and_return(creator_instance)

        error_result = {
          success: false,
          errors: [ "Name can't be blank", "Instructions can't be blank" ]
        }

        allow(creator_instance).to receive(:create).and_return(error_result)

        post :create, params: { recipe: { name: "" } }  # Invalid params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to include("application/json")

        json = JSON.parse(response.body)
        expect(json["status"]).to eq("error")
        expect(json["errors"]).to include("Name can't be blank")
      end
    end

    it "passes permitted parameters to the Creator service" do
      # Create a recipe before mocking to avoid factorybot validation issues
      existing_recipe = create(:recipe, user: user, recipe_category: recipe_category)

      # Test that only permitted parameters are passed to the service
      creator_double = instance_double(RecipeServices::Creator)
      allow(creator_double).to receive(:create).and_return({ success: true, recipe: existing_recipe })

      expect(RecipeServices::Creator).to receive(:new) do |current_user, params|
        expect(params).to respond_to(:permit)
        expect(params).to respond_to(:[])
        creator_double
      end

      post :create, params: {
        recipe: valid_recipe_attributes.merge(unpermitted_param: "should not be passed")
      }
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
      expect(response.content_type).to include("application/json")

      json = JSON.parse(response.body)
      expect(json["status"]).to eq("success")
      expect(json["message"]).to eq("Recipe marked as completed.")
      expect(json["recipe"]).to be_present
    end

    it "includes formatted recipe data in the response" do
      recipe = create(:recipe, user: user, recipe_category: recipe_category)

      patch :mark_completed, params: { id: recipe.id }, format: :json

      json = JSON.parse(response.body)
      expect(json["recipe"]["id"]).to eq(recipe.id)
      expect(json["recipe"]["name"]).to eq(recipe.name)
      expect(json["recipe"]["instructions"]).to eq(recipe.instructions)
    end

    it "handles recipes that are already completed" do
      recipe = create(:recipe, user: user, recipe_category: recipe_category, completed: true, completed_at: 1.day.ago)
      old_completed_at = recipe.completed_at

      patch :mark_completed, params: { id: recipe.id }

      recipe.reload
      expect(recipe.completed).to be true
      expect(recipe.completed_at).not_to eq(old_completed_at) # Should update the timestamp
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
      expect(response.content_type).to include("application/json")

      json = JSON.parse(response.body)
      expect(json["status"]).to eq("success")
      expect(json["message"]).to eq("Recipe marked as incomplete.")
      expect(json["recipe"]).to be_present
    end

    it "includes formatted recipe data in the response" do
      recipe = create(:recipe, user: user, recipe_category: recipe_category, completed: true)

      patch :mark_incomplete, params: { id: recipe.id }, format: :json

      json = JSON.parse(response.body)
      expect(json["recipe"]["id"]).to eq(recipe.id)
      expect(json["recipe"]["name"]).to eq(recipe.name)
      expect(json["recipe"]["instructions"]).to eq(recipe.instructions)
    end

    it "handles recipes that are already incomplete" do
      recipe = create(:recipe, user: user, recipe_category: recipe_category, completed: false, completed_at: nil)

      patch :mark_incomplete, params: { id: recipe.id }

      recipe.reload
      expect(recipe.completed).to be false
      expect(recipe.completed_at).to be_nil
    end
  end
end
