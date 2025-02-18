require 'rails_helper'

RSpec.describe "RecipeIngredients", type: :request do
  describe "GET /create" do
    it "returns http success" do
      get "/recipe_ingredients/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/recipe_ingredients/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/recipe_ingredients/destroy"
      expect(response).to have_http_status(:success)
    end
  end
end
