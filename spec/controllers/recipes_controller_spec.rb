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

  describe "DELETE #destroy" do
    it "destroys the requested recipe" do
      recipe = create(:recipe, user: user, recipe_category: recipe_category)

      expect {
        delete :destroy, params: { id: recipe.id }
      }.to change(Recipe, :count).by(-1)
    end

    it "redirects to the recipes list" do
      recipe = create(:recipe, user: user, recipe_category: recipe_category)

      delete :destroy, params: { id: recipe.id }

      expect(response).to redirect_to(recipes_url)
    end

    it "returns success JSON when requested" do
      recipe = create(:recipe, user: user, recipe_category: recipe_category)

      delete :destroy, params: { id: recipe.id }, format: :json

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("application/json")

      json = JSON.parse(response.body)
      expect(json["status"]).to eq("success")
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

    it "redirects to the recipe" do
      recipe = create(:recipe, user: user, recipe_category: recipe_category)

      patch :mark_completed, params: { id: recipe.id }

      expect(response).to redirect_to(recipe)
    end

    it "returns success JSON when requested" do
      recipe = create(:recipe, user: user, recipe_category: recipe_category)

      patch :mark_completed, params: { id: recipe.id }, format: :json

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("application/json")

      json = JSON.parse(response.body)
      expect(json["status"]).to eq("success")
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

    it "redirects to the recipe" do
      recipe = create(:recipe, user: user, recipe_category: recipe_category)

      patch :mark_incomplete, params: { id: recipe.id }

      expect(response).to redirect_to(recipe)
    end

    it "returns success JSON when requested" do
      recipe = create(:recipe, user: user, recipe_category: recipe_category)

      patch :mark_incomplete, params: { id: recipe.id }, format: :json

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("application/json")

      json = JSON.parse(response.body)
      expect(json["status"]).to eq("success")
    end
  end
end