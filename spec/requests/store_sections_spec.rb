require 'rails_helper'

RSpec.describe "StoreSections", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/store_sections/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/store_sections/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/store_sections/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/store_sections/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/store_sections/destroy"
      expect(response).to have_http_status(:success)
    end
  end
end
